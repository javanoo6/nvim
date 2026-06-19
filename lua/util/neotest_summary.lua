local M = {}

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
