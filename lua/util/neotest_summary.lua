local M = {}

local installed = false

local function recovery_buffer()
  local buffers = vim.fn.getbufinfo({ buflisted = 1 })
  table.sort(buffers, function(a, b)
    return a.lastused > b.lastused
  end)
  for _, buf in ipairs(buffers) do
    if vim.bo[buf.bufnr].buftype == "" then
      return buf.bufnr
    end
  end
  return vim.api.nvim_create_buf(true, false)
end

function M.install()
  if installed then
    return
  end
  -- Wrap the class so toggle, summary-local close, and debug entry points all
  -- share the guard, including summary instances already open in this process.
  local Summary = getmetatable(require("neotest.consumers.summary.summary")({}))
  local close = Summary.close
  Summary.close = function(self)
    if self.win:is_open() then
      local win = self.win._win
      local normal_windows = 0
      for _, tabwin in ipairs(vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(win))) do
        if vim.api.nvim_win_get_config(tabwin).relative == "" then
          normal_windows = normal_windows + 1
        end
      end
      if normal_windows == 1 then
        local buf = recovery_buffer()
        vim.api.nvim_win_call(win, function()
          vim.cmd("aboveleft vsplit")
          vim.wo.winfixbuf = false
          vim.wo.winfixwidth = false
          vim.api.nvim_win_set_buf(0, buf)
        end)
      end
    end
    return close(self)
  end
  installed = true
end

local function listed_normal_windows()
  local windows = {}

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative == "" then
      local buf = vim.api.nvim_win_get_buf(win)
      local buftype = vim.bo[buf].buftype
      local filetype = vim.bo[buf].filetype

      if buftype == "" and filetype ~= "neotest-summary" then
        table.insert(windows, win)
      end
    end
  end

  return windows
end

local function has_vertical_buffer_split()
  local columns = {}

  for _, win in ipairs(listed_normal_windows()) do
    columns[vim.api.nvim_win_get_position(win)[2]] = true
  end

  return vim.tbl_count(columns) >= 2
end

function M.summary_width()
  local divisor = has_vertical_buffer_split() and 4 or 3
  return math.max(24, math.floor(vim.o.columns / divisor))
end

function M.open()
  local width = M.summary_width()
  vim.cmd("botright vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.cmd(("vertical resize %d"):format(width))
  return win
end

return M
