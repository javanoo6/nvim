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
ui.setup()
local source = vim.api.nvim_get_current_win()
ui.open()
vim.wait(100)
check(visible("stacks") and visible("scopes") and visible("watches"), "Stack, Locals and Watches open")
check(not visible("repl") and not visible("console"), "Console starts hidden")
check(vim.api.nvim_get_current_win() == source, "Opening UI preserves source focus")
local scopes = dapui.elements.scopes.buffer()
check(type(mapping(scopes, "e").callback) == "function", "Locals has evaluate prompt")
check(type(mapping(scopes, "w").callback) == "function", "Locals has watch prompt")
check(mapping(scopes, "j").lhs == nil and mapping(scopes, "k").lhs == nil, "Vim j/k preserved")
check(mapping(scopes, "<CR>").lhs ~= nil, "Tree expansion retained")
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
print("DAP UI checks passed: " .. passed)
vim.cmd("qa!")
