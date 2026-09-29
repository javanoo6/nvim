-- Run via scripts/test-toggle-preferences.sh; uses a temporary XDG_STATE_HOME.
local function check()
  local persist = require("persist-toggle")
  local phase = vim.env.PERSIST_TOGGLE_TEST_PHASE
  local defaults = persist.defaults()
  assert(vim.tbl_count(defaults) == 16, "expected all 16 preferences")

  if phase == "write" then
    for name, default in pairs(defaults) do
      assert(persist.get(name) == default, "missing-state default: " .. name)
    end
    -- Exercise existing keymaps and helpers, including false overrides.
    for _, key in ipairs({ "us", "uw", "ul", "un", "uf", "um", "ud", "uD", "ue", "uh", "uJ", "uu", "uH" }) do
      local mapping = vim.fn.maparg(" " .. key, "n", false, true)
      assert(type(mapping.callback) == "function", "missing keymap: " .. key)
      mapping.callback()
    end
    persist.set("autoformat", false)
    persist.set("autosave", false)
    persist.set("dapui_keep_open_on_exit", true)
  end

  for name, default in pairs(defaults) do
    assert(persist.get(name) == not default, "saved/restarted preference: " .. name)
    assert(persist.values()[name] == not default, "effective state report: " .. name)
  end
  assert(not vim.diagnostic.is_enabled(), "diagnostics restored")
  assert(not vim.g.inlay_hints_enabled, "inlay hints restored")
  assert(vim.g.java_field_usages_enabled, "Java field usages restored")
  assert(not vim.g.neotree_reveal_on_open, "Neo-tree preference restored")
  assert(vim.g.dapui_keep_open_on_exit, "DAP UI preference restored")
  assert(vim.g.disable_autoformat, "autoformat restored")
  assert(vim.o.mouse == "a", "mouse restored")
  assert(not require("util").reference_style_state.underline, "reference style restored")

  -- Loading plugins later must not reset a saved preference.
  require("lazy").load({ plugins = { "nvim-lspconfig", "conform.nvim", "auto-save.nvim", "tiny-inline-diagnostic.nvim" } })
  vim.wait(100)
  assert(not vim.diagnostic.is_enabled(), "LSP setup reset diagnostics")
  assert(not require("tiny-inline-diagnostic.state").user_toggle_state, "inline diagnostics setup reset preference")
  assert(not require("auto-save").enabled(), "auto-save setup reset preference")
  assert(vim.g.disable_autoformat, "conform setup reset preference")
  vim.cmd("ASToggle")
  assert(persist.get("autosave") and require("auto-save").enabled(), "ASToggle enable")
  vim.cmd("ASToggle")
  assert(not persist.get("autosave") and not require("auto-save").enabled(), "ASToggle disable")
  vim.cmd("FormatEnable")
  assert(persist.get("autoformat"), "FormatEnable persists")
  vim.cmd("FormatDisable!")
  assert(persist.get("autoformat") and vim.b.disable_autoformat, "bang remains buffer-local")
  vim.cmd("FormatDisable")
  assert(not persist.get("autoformat"), "FormatDisable persists")

  persist.set("wrap", false)
  persist.set("spell", false)
  vim.cmd("setfiletype markdown")
  assert(not vim.wo.wrap and not vim.wo.spell, "text autocmd ignored explicit false")
  vim.wo.wrap = true
  vim.wo.number = true
  vim.api.nvim_exec_autocmds("SessionLoadPost", {})
  assert(not vim.wo.wrap and not vim.wo.number, "session overrode preferences")
  -- Leave all values inverted for the second process.
  persist.set("wrap", true)
  persist.set("spell", true)

  if phase == "read" then
    persist.reset("diagnostics")
    assert(vim.diagnostic.is_enabled() and persist.persisted().diagnostics == nil, "reset one")
    persist.reset_all()
    assert(vim.tbl_isempty(persist.persisted()), "reset all")
  end
  print("Toggle preference integration passed: " .. phase)
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
