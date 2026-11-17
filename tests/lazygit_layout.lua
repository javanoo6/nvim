-- Run: nvim --headless -u NONE -i NONE -l tests/lazygit_layout.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)
local original = vim.fn.jobstart
local captured, calls, forwarded = nil, 0, 0
vim.fn.jobstart = function(command, opts)
  calls = calls + 1
  captured = { command = command, opts = opts }
  return 42
end
local checks = 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. ": " .. vim.inspect(actual))
  checks = checks + 1
end
local function translated(char)
  return vim.fn.maparg(char, "t", false, true).callback()
end
local function run()
  local input = require("util.input")
  input.setup_lazygit()
  local wrapped = vim.fn.jobstart
  input.setup_lazygit()
  equal(vim.fn.jobstart, wrapped, "Repeated setup keeps one wrapper")
  local ordinary = { term = true }
  vim.fn.jobstart({ "zsh" }, ordinary)
  equal(captured.opts, ordinary, "Ordinary terminals retain their options")
  equal(vim.fn.maparg("о", "t"), "", "Ordinary terminal has no plain Russian aliases")
  local other = vim.api.nvim_create_buf(false, true)
  local opts = {
    term = true,
    on_stdout = function(job, data, event)
      equal({ job, data, event }, { 42, { "\27[?25h" }, "stdout" }, "Original stdout callback receives unchanged arguments")
      forwarded = forwarded + 1
    end,
  }
  local original_callback = opts.on_stdout
  equal(vim.fn.jobstart({ "/usr/local/bin/lazygit" }, opts), 42, "Job ID preserved")
  equal(opts.on_stdout, original_callback, "Caller options remain unchanged")
  equal(translated("о"), "j", "Russian down command")
  equal(translated("л"), "k", "Russian up command")
  equal(translated("С"), "C", "Shifted Russian command")
  equal(translated("<S-р>"), "H", "Explicit Shift Russian command")
  equal(translated("<S-д>"), "L", "Explicit Shift Russian right command")
  equal(translated("Б"), "<", "Shifted punctuation stays literal")
  captured.opts.on_stdout(42, { "\27[?25h" }, "stdout")
  equal(forwarded, 1, "Original stdout callback runs")
  equal(translated("о"), "о", "Editable fields preserve Russian")
  equal(translated("<S-р>"), "Р", "Editable fields preserve explicit Shift Russian")
  -- Next launch has independent cursor state; chunks can split CSI sequences.
  vim.fn.jobstart({ "lazygit" }, { term = true })
  equal(translated("о"), "j", "New launch resets input state")
  captured.opts.on_stdout(42, { "\27[?2" }, "stdout")
  captured.opts.on_stdout(42, { "5h" }, "stdout")
  equal(translated("П"), "П", "Split cursor-show preserves uppercase Russian")
  captured.opts.on_stdout(42, { "\27[?25lredraw\27[?25h" }, "stdout")
  equal(translated("р"), "р", "Last cursor visibility wins")
  captured.opts.on_stdout(42, { "\27[?25l" }, "stdout")
  equal(translated("й"), "q", "Closing text field restores commands")
  vim.api.nvim_set_current_buf(other)
  equal(vim.fn.maparg("о", "t"), "", "Mappings stay local to LazyGit buffer")
  vim.fn.jobstart({ "lazygit" }, {})
  equal(vim.fn.maparg("о", "t"), "", "Nonterminal LazyGit jobs are unaffected")
  equal(calls, 4, "Every job delegated exactly once")
end
local ok, err = xpcall(run, debug.traceback)
vim.fn.jobstart = original
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit 1")
end
print("LazyGit Russian layout: " .. checks .. " assertions passed")
vim.cmd("qa!")
