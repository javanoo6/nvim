local M = {}
local pending = {}

function M.save_session()
  -- Saving an ordinary editing session must not load the debugger.
  local breakpoints = package.loaded["dap.breakpoints"]
  local saved = {}
  if not breakpoints then
    return saved
  end
  for buf, points in pairs(breakpoints.get()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" then
      local path = vim.api.nvim_buf_get_name(buf)
      if path ~= "" then
        for _, point in ipairs(points) do
          saved[#saved + 1] = {
            path = path,
            line = point.line,
            condition = point.condition,
            hit_condition = point.hitCondition,
            log_message = point.logMessage,
          }
        end
      end
    end
  end
  table.sort(saved, function(a, b)
    return a.path == b.path and a.line < b.line or a.path < b.path
  end)
  return saved
end

function M.before_restore()
  pending = {}
  -- Notify adapters while the old buffers/signs still identify their sources.
  -- After auto-session wipes the buffers, DAP can no longer enumerate them.
  local dap = package.loaded.dap
  if dap then
    dap.clear_breakpoints()
  end
end

function M.load_session(data)
  local ok, decoded = pcall(vim.json.decode, data)
  if ok and type(decoded) == "table" and type(decoded.breakpoints) == "table" then
    pending = decoded.breakpoints
  end
end

function M.after_restore()
  local saved = pending
  pending = {}
  if not package.loaded["dap.breakpoints"] and #saved == 0 then
    return
  end
  local dap = require("dap")
  local breakpoints = require("dap.breakpoints")
  -- An empty or legacy session must not inherit another branch's breakpoints.
  -- The public clear also informs any running adapters.
  dap.clear_breakpoints()
  for _, point in ipairs(saved) do
    if
      type(point.path) == "string"
      and type(point.line) == "number"
      and point.line > 0
      and point.line % 1 == 0
      and vim.fn.filereadable(point.path) == 1
    then
      local buf = vim.fn.bufadd(point.path)
      vim.fn.bufload(buf)
      if point.line <= vim.api.nvim_buf_line_count(buf) then
        breakpoints.set({
          condition = point.condition,
          hit_condition = point.hit_condition,
          log_message = point.log_message,
        }, buf, point.line)
      end
    end
  end
  local restored = breakpoints.get()
  for _, session in pairs(dap.sessions()) do
    session:set_breakpoints(restored)
  end
end

return M
