local M = {}

local function find_upvalue(fn, name)
  for index = 1, math.huge do
    local upvalue_name, value = debug.getupvalue(fn, index)
    if not upvalue_name then
      return nil
    end
    if upvalue_name == name then
      return value
    end
  end
end

local function stale_buffer_id(err)
  local id = tostring(err):match("Invalid buffer id: (%d+)")
  return id and tonumber(id) or nil
end

local function remove_stale_id(groups, err)
  local id = stale_buffer_id(err)
  if not id then
    return false
  end
  groups.remove_id_from_manual_groupings(id)
  return true
end

local function persist_pinned_buffers(groups)
  local persist = find_upvalue(groups.add_element, "persist_pinned_buffers")
  if not persist then
    return true
  end

  for _ = 1, 20 do
    local ok, err = pcall(persist)
    if ok then
      return true
    end
    if not remove_stale_id(groups, err) then
      return false, err
    end
  end

  return false, "too many stale bufferline pinned buffers"
end

function M.toggle_pin()
  local groups = require("bufferline.groups")
  local ok, err = pcall(groups.toggle_pin)
  if ok then
    return
  end

  if not remove_stale_id(groups, err) then
    error(err, 0)
  end

  local persist_ok, persist_err = persist_pinned_buffers(groups)
  pcall(require("bufferline.ui").refresh)
  if not persist_ok then
    error(persist_err, 0)
  end

  vim.notify("Removed a stale bufferline pin", vim.log.levels.WARN)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("custom_bufferline_pins", { clear = true })
  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group,
    callback = function(args)
      local ok, groups = pcall(require, "bufferline.groups")
      if ok then
        groups.remove_id_from_manual_groupings(args.buf)
      end
    end,
  })
end

return M
