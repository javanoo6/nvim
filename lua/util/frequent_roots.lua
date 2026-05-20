local M = {}

local util = require("util")

local state
local setup_done = false
local max_recent = 50
local store_path = vim.fn.stdpath("data") .. "/frequent-roots.json"

local function normalize(path)
  if not path or path == "" then
    return nil
  end
  if vim.startswith(path, "file://") then
    path = vim.uri_to_fname(path)
  end
  return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

local function path_has_prefix(path, prefix)
  path = normalize(path)
  prefix = normalize(prefix)
  if not path or not prefix then
    return false
  end
  if path == prefix then
    return true
  end
  local with_sep = prefix:sub(-1) == "/" and prefix or (prefix .. "/")
  return path:sub(1, #with_sep) == with_sep
end

local function is_dir(path)
  return path and vim.fn.isdirectory(path) == 1
end

local function dedupe_dirs(paths)
  local seen = {}
  local items = {}

  for _, path in ipairs(paths or {}) do
    path = normalize(path)
    if is_dir(path) and not seen[path] then
      seen[path] = true
      items[#items + 1] = path
    end
  end

  return items
end

local function load()
  if state then
    return state
  end

  state = { pinned = {}, recent = {} }
  if vim.fn.filereadable(store_path) ~= 1 then
    return state
  end

  local ok, lines = pcall(vim.fn.readfile, store_path)
  if not ok or not lines or vim.tbl_isempty(lines) then
    return state
  end

  local data_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not data_ok or type(decoded) ~= "table" then
    return state
  end

  state.pinned = dedupe_dirs(decoded.pinned)
  state.recent = dedupe_dirs(decoded.recent)
  return state
end

local function save()
  local current = load()
  current.pinned = dedupe_dirs(current.pinned)
  current.recent = dedupe_dirs(current.recent)
  vim.fn.writefile({ vim.json.encode(current) }, store_path)
end

local function prepend_unique(list, path, limit)
  path = normalize(path)
  if not is_dir(path) then
    return list
  end

  local items = { path }
  for _, item in ipairs(list) do
    item = normalize(item)
    if item and item ~= path and is_dir(item) then
      items[#items + 1] = item
    end
    if limit and #items >= limit then
      break
    end
  end

  return items
end

local function current_buffer_path(bufnr)
  if type(bufnr) ~= "number" or bufnr <= 0 or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    return nil
  end
  return normalize(path)
end

local function get_marker_root_for_path(path)
  path = normalize(path)
  if not path then
    return nil
  end

  local search_from = path
  if vim.fn.isdirectory(path) ~= 1 then
    search_from = vim.fs.dirname(path)
  end

  local root = vim.fs.find(util.root_patterns, { path = search_from, upward = true })[1]
  return root and vim.fs.dirname(root) or nil
end

function M.current_root(bufnr)
  bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  local path = current_buffer_path(bufnr)
  if not path then
    return nil
  end

  local marker_root = get_marker_root_for_path(path)
  local lsp_root = util.get_lsp_root(bufnr)

  if marker_root then
    if lsp_root and path_has_prefix(lsp_root, marker_root) then
      return lsp_root
    end
    return marker_root
  end

  if lsp_root then
    return lsp_root
  end

  if vim.fn.isdirectory(path) == 1 then
    return path
  end

  return normalize(vim.fs.dirname(path))
end

function M.add_recent(path)
  path = normalize(path)
  if not is_dir(path) then
    return
  end

  local current = load()
  current.recent = prepend_unique(current.recent, path, max_recent)
  save()
end

function M.pin(path)
  path = normalize(path)
  if not is_dir(path) then
    vim.notify("No directory to pin", vim.log.levels.WARN)
    return
  end

  local current = load()
  current.pinned = prepend_unique(current.pinned, path)
  save()
  vim.notify("Pinned root: " .. vim.fn.fnamemodify(path, ":~"), vim.log.levels.INFO)
end

function M.unpin(path)
  path = normalize(path)
  if not path then
    vim.notify("No directory to unpin", vim.log.levels.WARN)
    return
  end

  local current = load()
  local next_pinned = {}
  local removed = false

  for _, item in ipairs(current.pinned) do
    if normalize(item) ~= path then
      next_pinned[#next_pinned + 1] = item
    else
      removed = true
    end
  end

  current.pinned = next_pinned
  save()

  if removed then
    vim.notify("Unpinned root: " .. vim.fn.fnamemodify(path, ":~"), vim.log.levels.INFO)
  else
    vim.notify("Root is not pinned: " .. vim.fn.fnamemodify(path, ":~"), vim.log.levels.INFO)
  end
end

function M.get_items()
  local current = load()
  local items = {}
  local seen = {}

  for _, path in ipairs(current.pinned) do
    path = normalize(path)
    if is_dir(path) and not seen[path] then
      seen[path] = true
      items[#items + 1] = {
        path = path,
        source = "pinned",
        label = string.format("%s  [pinned]", vim.fn.fnamemodify(path, ":~")),
      }
    end
  end

  for _, path in ipairs(current.recent) do
    path = normalize(path)
    if is_dir(path) and not seen[path] then
      seen[path] = true
      items[#items + 1] = {
        path = path,
        source = "recent",
        label = string.format("%s  [recent]", vim.fn.fnamemodify(path, ":~")),
      }
    end
  end

  return items
end

function M.open(path)
  path = normalize(path)
  if not is_dir(path) then
    vim.notify("Not a directory: " .. tostring(path), vim.log.levels.ERROR)
    return
  end

  M.add_recent(path)
  vim.api.nvim_set_current_dir(path)

  local ok, builtin = pcall(require, "telescope.builtin")
  if ok then
    builtin.find_files({ cwd = path })
    return
  end

  vim.notify("CWD set to " .. vim.fn.fnamemodify(path, ":~"), vim.log.levels.INFO)
end

function M.pick()
  local items = M.get_items()
  if vim.tbl_isempty(items) then
    vim.notify("No frequent roots yet. Open files or pin a directory first.", vim.log.levels.INFO)
    return
  end

  local telescope_ok, pickers = pcall(require, "telescope.pickers")
  if telescope_ok then
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers
      .new({}, {
        prompt_title = "Frequent Roots",
        finder = finders.new_table({
          results = items,
          entry_maker = function(item)
            return {
              value = item,
              display = item.label,
              ordinal = item.path .. " " .. item.source,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if selection and selection.value then
              M.open(selection.value.path)
            end
          end)
          return true
        end,
      })
      :find()
    return
  end

  vim.ui.select(items, {
    prompt = "Frequent Roots",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      M.open(choice.path)
    end
  end)
end

function M.setup()
  if setup_done then
    return
  end
  setup_done = true

  load()

  local function record_buffer(bufnr)
    if type(bufnr) ~= "number" or bufnr <= 0 or not vim.api.nvim_buf_is_valid(bufnr) then
      bufnr = vim.api.nvim_get_current_buf()
    end
    local root = M.current_root(bufnr)
    if root then
      M.add_recent(root)
    end
  end

  vim.api.nvim_create_autocmd({ "BufEnter", "VimEnter" }, {
    group = util.augroup("frequent_roots"),
    callback = function(args)
      record_buffer(args.buf)
    end,
  })

  record_buffer(vim.api.nvim_get_current_buf())
end

return M
