local M = {}

function M.is_panel(bufnr)
  return vim.api.nvim_buf_get_name(bufnr) == "intellij-lsp://debug"
end

function M.close()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if M.is_panel(vim.api.nvim_win_get_buf(win)) then
      pcall(vim.api.nvim_win_close, win, false)
    end
  end
end

function M.open()
  return require("intellij-lsp.debug").open()
end

function M.toggle()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if M.is_panel(vim.api.nvim_win_get_buf(win)) then
      M.close()
      return
    end
  end
  M.open()
end

function M.toggle_keep_open()
  require("util.preferences").toggle("debug_panel_keep_open")
end

function M.setup()
  local dap = require("dap")
  require("intellij-lsp.debug").setup()
  dap.listeners.before.event_initialized["close_test_summary"] = function()
    local neotest = package.loaded.neotest
    if neotest then
      neotest.summary.close()
    end
  end
  -- Upstream opens on stops for every adapter. Retain our exit-close policy.
  local function close_on_exit()
    if not require("util.preferences").get("debug_panel_keep_open") then
      vim.schedule(M.close)
    end
  end
  dap.listeners.after.event_terminated["default_debug_panel"] = close_on_exit
  dap.listeners.after.event_exited["default_debug_panel"] = close_on_exit
end

return M
