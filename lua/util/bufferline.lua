local M = {}
local pending_session

-- Store paths rather than transient buffer IDs. This payload belongs to one
-- auto-session, independently of Bufferline's process-global persistence.
function M.save_session()
  require("bufferline")
  local groups = require("bufferline.groups")
  local state = require("bufferline.state")
  local order, pins, seen = {}, {}, {}
  local function add(id)
    if seen[id] or not vim.api.nvim_buf_is_valid(id) or not vim.bo[id].buflisted or vim.bo[id].buftype ~= "" then
      return
    end
    seen[id] = true
    local path = vim.api.nvim_buf_get_name(id)
    if path == "" then
      return
    end
    order[#order + 1] = path
    if groups._is_pinned({ id = id }) then
      pins[#pins + 1] = path
    end
  end
  for _, item in ipairs(state.components) do
    add(item.id)
  end
  for _, id in ipairs(state.custom_sort or {}) do
    add(id)
  end
  for _, id in ipairs(vim.api.nvim_list_bufs()) do
    add(id)
  end
  return vim.json.encode({ bufferline = { order = order, pins = pins } })
end

function M.before_restore()
  pending_session = nil
  -- Legacy sessions must not inherit the previous workspace's metadata.
  vim.g.BufferlinePinnedBuffers = ""
  vim.g.BufferlinePositions = ""
end

function M.load_session(data)
  local ok, decoded = pcall(vim.json.decode, data)
  if ok and type(decoded) == "table" then
    pending_session = decoded.bufferline
  end
end

function M.after_restore()
  require("bufferline")
  local groups = require("bufferline.groups")
  local ids = {}
  for _, id in ipairs(vim.api.nvim_list_bufs()) do
    groups.remove_id_from_manual_groupings(id)
    ids[vim.api.nvim_buf_get_name(id)] = id
  end
  vim.g.BufferlinePinnedBuffers = ""
  local data = pending_session or {}
  for _, path in ipairs(data.pins or {}) do
    if ids[path] then
      groups.add_element("pinned", { id = ids[path] })
    end
  end
  local order = {}
  for _, path in ipairs(data.order or {}) do
    if ids[path] then
      order[#order + 1] = ids[path]
    end
  end
  require("bufferline.state").set({ custom_sort = #order > 0 and order or vim.NIL })
  require("bufferline.utils").save_positions(order)
  pending_session = nil
  require("bufferline.ui").refresh()
end

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
