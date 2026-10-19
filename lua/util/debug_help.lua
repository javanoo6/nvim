local M = {}
local win, buf
local enabled = true

function M.close()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  win = nil
end

function M.refresh()
  local current = vim.api.nvim_get_current_win()
  if
    not enabled
    or vim.fn.mode() ~= "n"
    or vim.api.nvim_win_get_config(current).relative ~= ""
    or not require("util.debug_ui").is_panel(vim.api.nvim_get_current_buf())
  then
    M.close()
    return
  end

  local ft = vim.bo.filetype
  local lines = {
    " e  Evaluate      w  Add watch",
    " c  Continue      p  Pause",
    " n  Step over     s  Step into",
    " o  Step out      t  Terminate",
    " Enter  Expand / select frame",
    " dd Remove watch  E  Edit value/watch",
    " r  Send to REPL  W  Watch variable",
    " O  Open source   T  Toggle thread",
    " Tab Locals / Console   q Close UI",
    " j/k Move         ?  Hide/show help",
    (ft == "dapui_scopes" or ft == "dapui_stacks") and " i  Step into" or " i  Type input    Esc Normal mode",
  }
  local width = math.min(40, vim.o.columns - 4)
  local height = math.min(#lines, vim.o.lines - vim.o.cmdheight - 4)
  if width < 20 or height < 4 then
    M.close()
    return
  end
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "hide"
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local config = {
    relative = "editor",
    anchor = "NE",
    row = 1,
    col = vim.o.columns - 2,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " DAP keys ",
    title_pos = "center",
    focusable = false,
    zindex = 40,
  }
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_config(win, config)
  else
    win = vim.api.nvim_open_win(buf, false, config)
    vim.wo[win].winblend = 10
    vim.wo[win].wrap = false
  end
end

function M.toggle()
  enabled = not enabled
  M.refresh()
end

function M.setup(group)
  vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "ModeChanged", "VimResized", "WinClosed" }, {
    group = group,
    callback = function()
      vim.schedule(M.refresh)
    end,
    desc = "Show DAP shortcut help while a debugger pane has Normal-mode focus",
  })
end

return M
