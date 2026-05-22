local M = {}

local util = require("util")

local state
local setup_done = false
local max_projects = 50
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

local function is_project_dir(path)
  path = normalize(path)
  return is_dir(path) and get_marker_root_for_path(path) == path
end

local function load()
  if state then
    return state
  end

  state = { manual = {}, projects = {} }
  if vim.fn.filereadable(store_path) ~= 1 then
    return state
  end

  local ok, lines = pcall(vim.fn.readfile, store_path)
  if not ok or not lines or vim.tbl_isempty(lines) then
    return state
  end

  local decode_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decode_ok or type(decoded) ~= "table" then
    return state
  end

  -- Migrate older schema: pinned -> manual, recent -> projects.
  state.manual = dedupe_dirs(decoded.manual or decoded.pinned)
  state.projects = vim.tbl_filter(is_project_dir, dedupe_dirs(decoded.projects or decoded.recent))
  return state
end

local function save()
  local current = load()
  current.manual = dedupe_dirs(current.manual)
  current.projects = vim.tbl_filter(is_project_dir, dedupe_dirs(current.projects))
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

local function current_project_root(bufnr)
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

  return nil
end

local function current_dir(bufnr)
  bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  local path = current_buffer_path(bufnr)
  if path then
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
    return normalize(vim.fs.dirname(path))
  end
  return util.get_cwd()
end

local function open_dir(path)
  path = normalize(path)
  if not is_dir(path) then
    vim.notify("Not a directory: " .. tostring(path), vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_set_current_dir(path)

  local ok, builtin = pcall(require, "telescope.builtin")
  if ok then
    builtin.find_files({ cwd = path })
    return
  end

  vim.notify("CWD set to " .. vim.fn.fnamemodify(path, ":~"), vim.log.levels.INFO)
end

local function telescope_pick(opts)
  opts = opts or {}
  local items = opts.items or {}
  if vim.tbl_isempty(items) then
    if opts.empty_message then
      vim.notify(opts.empty_message, vim.log.levels.INFO)
    end
    return
  end

  local telescope_ok, pickers = pcall(require, "telescope.pickers")
  if telescope_ok then
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local entry_display = require("telescope.pickers.entry_display")
    local displayer = entry_display.create({
      separator = " ",
      items = {
        { width = 30 },
        { remaining = true },
      },
    })

    local function make_display(entry)
      return displayer({ entry.name or "", { entry.value.path or entry.value.label, "Comment" } })
    end

    pickers
      .new({}, {
        prompt_title = opts.title or "Directories",
        finder = finders.new_table({
          results = items,
          entry_maker = function(item)
            return {
              value = item,
              display = make_display,
              name = item.name or vim.fn.fnamemodify(item.path or item.label, ":t"),
              ordinal = (item.name or "") .. " " .. (item.path or item.label or ""),
            }
          end,
        }),
        previewer = false,
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          if opts.attach_mappings then
            return opts.attach_mappings(prompt_bufnr, map)
          end

          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if selection and selection.value then
              open_dir(selection.value.path)
            end
          end)
          return true
        end,
      })
      :find()
    return
  end

  vim.ui.select(items, {
    prompt = opts.title or "Directories",
    format_item = function(item)
      return item.label or item.path or item.name
    end,
  }, function(choice)
    if choice and choice.path then
      open_dir(choice.path)
    elseif choice and opts.on_choice then
      opts.on_choice(choice)
    end
  end)
end

function M.pick_projects()
  local current = load()
  local items = {}
  for _, path in ipairs(current.projects) do
    items[#items + 1] = {
      path = path,
      label = path,
    }
  end

  telescope_pick({
    title = "Projects",
    items = items,
    empty_message = "No projects yet. Open files inside a detected project first.",
  })
end

function M.get_current_project_root(bufnr)
  return current_project_root(bufnr)
end

function M.get_current_dir(bufnr)
  return current_dir(bufnr)
end

function M.add_project(path)
  path = normalize(path)
  if not is_dir(path) then
    return
  end

  local current = load()
  current.projects = prepend_unique(current.projects, path, max_projects)
  save()
end

function M.add_manual(path)
  path = normalize(path)
  if not is_dir(path) then
    vim.notify("No directory to add", vim.log.levels.WARN)
    return
  end

  local current = load()
  current.manual = prepend_unique(current.manual, path)
  save()
  vim.notify("Added manual dir: " .. vim.fn.fnamemodify(path, ":~"), vim.log.levels.INFO)
end

function M.remove_manual(path)
  path = normalize(path)
  if not path then
    vim.notify("No directory to remove", vim.log.levels.WARN)
    return
  end

  local current = load()
  local next_manual = {}
  local removed = false

  for _, item in ipairs(current.manual) do
    if normalize(item) ~= path then
      next_manual[#next_manual + 1] = item
    else
      removed = true
    end
  end

  current.manual = next_manual
  save()

  if removed then
    vim.notify("Removed manual dir: " .. vim.fn.fnamemodify(path, ":~"), vim.log.levels.INFO)
  else
    vim.notify("Directory is not in manual list: " .. vim.fn.fnamemodify(path, ":~"), vim.log.levels.INFO)
  end
end

function M.list_manual()
  local current = load()
  local items = {}
  for _, path in ipairs(current.manual) do
    items[#items + 1] = {
      path = path,
      label = path,
    }
  end

  telescope_pick({
    title = "Manual Dirs",
    items = items,
    empty_message = "No manual directories yet.",
  })
end

function M.remove_manual_picker()
  local current = load()
  local items = {}
  for _, path in ipairs(current.manual) do
    items[#items + 1] = {
      path = path,
      label = path,
    }
  end

  telescope_pick({
    title = "Remove Manual Dir",
    items = items,
    empty_message = "No manual directories to remove.",
    attach_mappings = function(prompt_bufnr)
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection and selection.value then
          M.remove_manual(selection.value.path)
        end
      end)
      return true
    end,
    on_choice = function(choice)
      if choice and choice.path then
        M.remove_manual(choice.path)
      end
    end,
  })
end

function M.add_manual_prompt()
  vim.ui.input({
    prompt = "Add manual dir: ",
    default = current_dir(0) or util.get_cwd(),
    completion = "dir",
  }, function(input)
    if not input or input == "" then
      return
    end
    M.add_manual(vim.fn.fnamemodify(input, ":p"))
  end)
end

function M.manage_manual()
  local items = {
    { key = "a", label = "Add dir" },
    { key = "r", label = "Remove dir" },
    { key = "l", label = "List dirs" },
  }

  telescope_pick({
    title = "Manual Dirs",
    items = items,
    attach_mappings = function(prompt_bufnr)
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not selection or not selection.value then
          return
        end

        if selection.value.key == "a" then
          M.add_manual_prompt()
        elseif selection.value.key == "r" then
          M.remove_manual_picker()
        elseif selection.value.key == "l" then
          M.list_manual()
        end
      end)
      return true
    end,
    on_choice = function(choice)
      if not choice then
        return
      end
      if choice.key == "a" then
        M.add_manual_prompt()
      elseif choice.key == "r" then
        M.remove_manual_picker()
      elseif choice.key == "l" then
        M.list_manual()
      end
    end,
  })
end

function M.setup()
  if setup_done then
    return
  end
  setup_done = true

  load()
  save()

  local function record_buffer(bufnr)
    if type(bufnr) ~= "number" or bufnr <= 0 or not vim.api.nvim_buf_is_valid(bufnr) then
      bufnr = vim.api.nvim_get_current_buf()
    end
    local root = current_project_root(bufnr)
    if root then
      M.add_project(root)
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
