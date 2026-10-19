local M = {}
local bottom_layout = 2 -- Locals/Watches; 3 is Console.

function M.is_panel(bufnr)
  local ft = vim.bo[bufnr].filetype
  return ft:match("^dapui_") ~= nil or ft == "dap-repl"
end

local function is_open()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if M.is_panel(vim.api.nvim_win_get_buf(win)) then
      return true
    end
  end
  return false
end

function M.close()
  require("util.debug_help").close()
  require("dapui").close()
end

function M.open()
  local ui = require("dapui")
  local win = vim.api.nvim_get_current_win()
  ui.open({ layout = 1 })
  ui.open({ layout = bottom_layout })
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end
end

function M.toggle()
  if is_open() then
    M.close()
  else
    M.open()
  end
end

function M.toggle_bottom()
  local focus_panel = M.is_panel(vim.api.nvim_get_current_buf())
  require("dapui").close({ layout = bottom_layout })
  bottom_layout = bottom_layout == 2 and 3 or 2
  M.open()
  if focus_panel then
    local element = bottom_layout == 2 and "scopes" or "repl"
    local win = vim.fn.bufwinid(require("dapui").elements[element].buffer())
    if win ~= -1 then
      vim.api.nvim_set_current_win(win)
    end
  end
end

function M.toggle_keep_open()
  require("util.preferences").toggle("debug_panel_keep_open")
end

function M.evaluate()
  -- Retain IntelliJ's dotted/call-chain extraction for source expressions.
  local expr
  if vim.fn.mode() == "n" then
    expr = require("intellij-lsp.debug")._expression_at_cursor(vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(0)[2])
  end
  require("dapui").eval(expr, { context = "repl", enter = true })
end

local function prompt(label, callback)
  vim.ui.input({ prompt = label .. ": " }, function(expr)
    if expr and vim.trim(expr) ~= "" then
      callback(expr)
    end
  end)
end

local function panel_keys(buf)
  local dap = require("dap")
  local function map(key, callback, desc)
    vim.keymap.set("n", key, callback, { buffer = buf, nowait = true, silent = true, desc = "Debug: " .. desc })
  end
  local function stopped(action)
    return function()
      local session = dap.session()
      if session and session.stopped_thread_id then
        dap[action]()
      else
        vim.notify("No suspended debug session", vim.log.levels.INFO, { title = "DAP" })
      end
    end
  end
  map("c", stopped("continue"), "Continue")
  map("n", stopped("step_over"), "Step over")
  map("s", stopped("step_into"), "Step into")
  map("o", stopped("step_out"), "Step out")
  map("p", dap.pause, "Pause")
  map("t", function()
    if dap.session() then
      dap.terminate()
    end
  end, "Terminate")
  map("e", function()
    prompt("Evaluate", function(expr)
      require("dapui").eval(expr, { context = "repl", enter = true })
    end)
  end, "Evaluate expression")
  map("w", function()
    prompt("Watch", function(expr)
      require("dapui").elements.watches.add(expr)
    end)
  end, "Add watch")
  map("<Tab>", M.toggle_bottom, "Switch Locals / Console")
  map("q", M.close, "Close debugger UI")
  map("?", function()
    require("util.debug_help").toggle()
  end, "Show/hide shortcut help")
  -- Keep insert mode available in the REPL and Watches prompt buffer.
  if vim.bo[buf].filetype == "dapui_scopes" or vim.bo[buf].filetype == "dapui_stacks" then
    map("i", stopped("step_into"), "Step into")
  end
end

function M.setup()
  local dap = require("dap")
  local group = vim.api.nvim_create_augroup("LocalDebugUI", { clear = true })
  require("util.debug_help").setup(group)
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "dapui_*", "dap-repl" },
    callback = function(event)
      panel_keys(event.buf)
    end,
  })
  require("dapui").setup({
    layouts = {
      { elements = { "stacks" }, size = 40, position = "left" },
      { elements = { { id = "scopes", size = 0.7 }, { id = "watches", size = 0.3 } }, size = 12, position = "bottom" },
      { elements = { { id = "repl", size = 0.7 }, { id = "console", size = 0.3 } }, size = 12, position = "bottom" },
    },
    mappings = { expand = { "<CR>", "<2-LeftMouse>" }, open = "O", remove = "dd", edit = "E", repl = "r", toggle = "T", watch = "W" },
    controls = { enabled = false },
  })
  -- No IntelliJ debug listeners: one UI owns stops for every adapter.
  dap.listeners.after.event_stopped["default_debug_panel"] = function()
    vim.schedule(M.open)
  end
  dap.listeners.before.event_initialized["close_test_summary"] = function()
    local neotest = package.loaded.neotest
    if neotest then
      neotest.summary.close()
    end
  end
  local function close_on_exit()
    vim.schedule(function()
      if next(dap.sessions()) == nil and not require("util.preferences").get("debug_panel_keep_open") then
        M.close()
      end
    end)
  end
  dap.listeners.after.event_terminated["default_debug_panel"] = close_on_exit
  dap.listeners.after.event_exited["default_debug_panel"] = close_on_exit
end

return M
