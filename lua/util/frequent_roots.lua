local M = {}

local util = require("util")

local state
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

  state = { manual = {} }
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

  -- Keep legacy project/history fields opaque; manual writes must not discard them.
  state = decoded
  state.manual = dedupe_dirs(decoded.manual or decoded.pinned)
  return state
end

local function save()
  local current = load()
  current.manual = dedupe_dirs(current.manual)
  vim.fn.writefile({ vim.json.encode(current) }, store_path)
end

local function prepend_unique(list, path)
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
    if choice and opts.on_choice then
      opts.on_choice(choice)
    elseif choice and choice.path then
      open_dir(choice.path)
    end
  end)
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

return M
