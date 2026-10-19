-- Real UI buffers/layouts, without launching an adapter or language server.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(repo)
for _, name in ipairs({ "nvim-dap", "nvim-dap-ui", "nvim-nio", "intellij-lsp.nvim" }) do
  vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/" .. name)
end
vim.o.columns = 160
vim.o.lines = 50
local ui = require("util.debug_ui")
local dapui = require("dapui")
local passed = 0
local function check(value, label)
  assert(value, label)
  passed = passed + 1
end
local function visible(element)
  return vim.fn.bufwinid(dapui.elements[element].buffer()) ~= -1
end
local function mapping(buf, key)
  return vim.api.nvim_buf_call(buf, function()
    return vim.fn.maparg(key, "n", false, true)
  end)
end
local function help_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" and vim.inspect(config.title):find("DAP keys", 1, true) then
      return win
    end
  end
end
ui.setup()
local source = vim.api.nvim_get_current_win()
ui.open()
vim.wait(100)
check(visible("stacks") and visible("scopes") and visible("watches"), "Stack, Locals and Watches open")
check(not visible("repl") and not visible("console"), "Console starts hidden")
check(vim.api.nvim_get_current_win() == source, "Opening UI preserves source focus")
check(not help_window(), "Shortcut popup stays hidden in source")
local scopes = dapui.elements.scopes.buffer()
check(type(mapping(scopes, "e").callback) == "function", "Locals has evaluate prompt")
check(type(mapping(scopes, "w").callback) == "function", "Locals has watch prompt")
check(mapping(scopes, "j").lhs == nil and mapping(scopes, "k").lhs == nil, "Vim j/k preserved")
check(mapping(scopes, "<CR>").lhs ~= nil, "Tree expansion retained")
vim.api.nvim_set_current_win(vim.fn.bufwinid(scopes))
vim.wait(100)
local help = help_window()
check(help ~= nil, "Focusing DAP shows shortcut popup")
check(vim.api.nvim_get_current_buf() == scopes, "Shortcut popup never takes focus")
check(not vim.api.nvim_win_get_config(help).focusable, "Shortcut popup cannot intercept navigation")
mapping(scopes, "?").callback()
check(not help_window(), "Question mark hides shortcut popup")
mapping(scopes, "?").callback()
check(help_window() ~= nil, "Question mark restores shortcut popup")
vim.api.nvim_set_current_win(source)
vim.wait(100)
check(not help_window(), "Returning to source hides shortcut popup")
vim.api.nvim_set_current_win(vim.fn.bufwinid(scopes))
mapping(scopes, "<Tab>").callback()
vim.wait(100)
check(visible("stacks") and visible("repl") and visible("console"), "Console keeps Stack visible")
check(not visible("scopes") and not visible("watches"), "Console replaces Locals and Watches")
check(vim.api.nvim_get_current_buf() == dapui.elements.repl.buffer(), "Tab focuses Console REPL")
check(mapping(dapui.elements.repl.buffer(), "i").lhs == nil, "REPL insert mode retained")
ui.toggle_bottom()
vim.wait(100)
check(visible("scopes") and not visible("repl"), "Tab returns to Locals")
check(vim.api.nvim_get_current_buf() == scopes, "Tab focuses Locals")
dapui.elements.watches.add("example")
ui.toggle()
check(not visible("stacks") and not visible("scopes"), "Toggle closes all layouts")
ui.toggle()
check(visible("stacks") and visible("scopes"), "Toggle restores chosen layout")
check(dapui.elements.watches.get()[1].expression == "example", "Watch survives close/reopen")
-- A continue shortcut without a session must never launch a configuration picker.
local dap = require("dap")
local continue = dap.continue
dap.continue = function()
  error("Continue must not run without a suspended session")
end
mapping(scopes, "c").callback()
dap.continue = continue
check(true, "Continue is guarded")
ui.close()
vim.wait(100)
check(not help_window(), "Closing DAP removes shortcut popup")
-- IntelliJ's run module registers a global first-output listener when loaded.
-- It must not open another console for any language's debug sessions.
require("util.java_launch").setup()
local output = require("intellij-lsp.output")
local original_open = output.open
local opened = 0
output.open = function()
  opened = opened + 1
end
local first_output = dap.listeners.before.event_output["intellij-lsp.run.panel"]
for id, adapter in ipairs({ "intellij_jvm", "python", "go" }) do
  first_output({ id = id, config = { type = adapter, noDebug = false } }, { output = "test started" })
end
vim.wait(100)
check(opened == 0, "Debug output never automatically opens IntelliJ output")
local normal_run = { id = 4, config = { type = "intellij_jvm", noDebug = true } }
first_output(normal_run, { output = "program started" })
first_output(normal_run, { output = "more output" })
vim.wait(100)
check(opened == 1, "Normal Java runs still open output once")
output.open = original_open
print("DAP UI checks passed: " .. passed)
vim.cmd("qa!")
