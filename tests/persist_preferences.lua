-- Real plugin setup and two-process preference restore, using disposable state.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(repo)
vim.opt.rtp:append(repo .. "/after")
local plugin_dir = vim.fn.stdpath("data") .. "/lazy/"
for _, name in ipairs(vim.fn.readdir(plugin_dir)) do
  vim.opt.rtp:append(plugin_dir .. name)
end
vim.notify = function() end
local preferences = require("util.preferences")
local toggles = require("persist-toggle")
local passed = 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. ": " .. vim.inspect(actual) .. " expected " .. vim.inspect(expected))
  passed = passed + 1
end
local function spec(module, name)
  for _, plugin in ipairs(require(module)) do
    if plugin[1] == name then
      return plugin
    end
  end
  error("Missing spec: " .. name)
end
local function run(path, mode)
  preferences.setup({ path = path, notify = false })
  if mode == "seed" then
    for id, default in pairs(toggles.defaults()) do
      preferences.set(id, not default)
    end
    return
  end
  -- Saved false must survive getters, plugin setup, and scheduled callbacks.
  for id, default in pairs(toggles.defaults()) do
    equal(preferences.get(id), not default, "Restored " .. id)
  end
  equal(vim.diagnostic.is_enabled(), false, "Diagnostics restored off")
  equal(vim.g.disable_autoformat, true, "Formatting restored off")
  equal(require("util.inlay_hints").is_enabled(), false, "Hints restored off")
  local neotest_before = package.loaded.neotest
  local summary_opens, run_calls = 0, 0
  package.loaded.neotest = {
    summary = {
      open = function()
        summary_opens = summary_opens + 1
      end,
    },
    output_panel = { clear = function() end },
  }
  require("util.neotest_scope").with_scope(function()
    run_calls = run_calls + 1
  end)()
  equal(summary_opens, 0, "Saved summary preference suppresses regular-run opening")
  equal(run_calls, 1, "Suppressed summary does not suppress test execution")
  package.loaded.neotest = neotest_before
  local autosave = require("plugins.auto-save")
  autosave.config(nil, vim.deepcopy(autosave.opts))
  equal(require("auto-save").enabled(), false, "Auto-save setup respects off")
  vim.cmd.ASToggle()
  equal(toggles.get("autosave"), true, "ASToggle persists enable")
  equal(require("auto-save").enabled(), true, "ASToggle applies enable")
  vim.cmd.ASToggle()
  equal(toggles.get("autosave"), false, "ASToggle persists disable")

  local inline = spec("plugins.lsp", "rachartier/tiny-inline-diagnostic.nvim")
  inline.config(nil, inline.opts)
  vim.wait(50, function()
    return false
  end)
  equal(require("tiny-inline-diagnostic.state").user_toggle_state, false, "Inline diagnostics stay off after scheduled setup")
  vim.cmd("TinyInlineDiag enable")
  equal(toggles.get("inline_diagnostics"), true, "Native inline command persists")
  vim.cmd("TinyInlineDiag disable")
  equal(toggles.get("inline_diagnostics"), false, "Native inline disable persists")

  local git = spec("plugins.git", "lewis6991/gitsigns.nvim")
  local opts = vim.deepcopy(git.opts)
  opts.on_attach = nil -- which-key is irrelevant to preference checks.
  local command_before = require("gitsigns.actions")._get_cmd_func("stage_hunk")
  git.config(nil, opts)
  equal(require("gitsigns.actions")._get_cmd_func("stage_hunk"), command_before, "Unowned Gitsigns command delegates unchanged")
  local git_config = require("gitsigns.config").config
  equal(git_config.current_line_blame, true, "Git blame restores after setup")
  equal(git_config.word_diff, true, "Git word diff restores after setup")
  vim.cmd("Gitsigns toggle_current_line_blame false")
  assert(
    vim.wait(1000, function()
      return toggles.get("git_blame") == false
    end),
    "Gitsigns command did not persist"
  )
  equal(git_config.current_line_blame, false, "Gitsigns command applies preference")
  require("gitsigns").toggle_linehl(false)
  equal(toggles.get("git_linehl"), false, "Gitsigns public API persists")

  local session = require("plugins.sessions")
  local session_opts = vim.deepcopy(session.opts)
  session_opts.root_dir = vim.fs.dirname(path) .. "/sessions/"
  session.config(nil, session_opts)
  equal(require("auto-session.config").auto_save, false, "Session auto-save respects saved off")
  equal(require("auto-session.config").auto_restore, false, "Session auto-restore respects saved off")
  preferences.set("session_autosave", true)
  equal(require("auto-session.config").auto_save, true, "Session preference applies live")
  -- Plugin safety disables are operational state, not permanent preferences.
  require("auto-session").disable_auto_save()
  equal(toggles.get("session_autosave"), true, "Session safety disable does not overwrite saved preference")
  local flash = spec("plugins.motion", "folke/flash.nvim")
  flash.config(nil, flash.opts)
  equal(require("flash.plugins.search").enabled, true, "Flash restores after setup")
  preferences.toggle("flash_search")
  equal(require("flash.plugins.search").enabled, false, "Flash toggle applies")
  local oil = spec("plugins.editor", "stevearc/oil.nvim")
  oil.config(nil, vim.deepcopy(oil.opts))
  equal(require("oil.config").view_options.show_hidden, true, "Oil restores hidden files")
  preferences.toggle("oil_hidden")
  equal(require("oil.config").view_options.show_hidden, false, "Oil hidden toggle applies")

  vim.cmd("filetype plugin on")
  vim.bo.filetype = "markdown"
  equal({ vim.wo.wrap, vim.wo.spell }, { true, true }, "Explicit prose on overrides")
  preferences.set("wrap", false)
  preferences.set("spell", false)
  vim.bo.filetype = "lua"
  vim.bo.filetype = "markdown"
  equal({ vim.wo.wrap, vim.wo.spell }, { false, false }, "Prose respects saved off")
  vim.wo.wrap = true
  vim.wo.number = true
  vim.api.nvim_exec_autocmds("SessionLoadPost", {})
  equal({ vim.wo.wrap, vim.wo.number }, { false, false }, "Session options cannot overwrite preferences")
  vim.cmd("PersistToggleReset wrap")
  equal(vim.wo.wrap, true, "Reset restores prose default")
  equal(vim.api.nvim_get_option_value("wrap", { scope = "global" }), false, "Prose does not change global default")
  vim.cmd("PersistToggleResetAll")
  equal(require("auto-save").enabled(), true, "Reset applies plugin default")
  equal(require("tiny-inline-diagnostic.state").user_toggle_state, true, "Reset applies inline default")
  equal(toggles.persisted(), {}, "Reset removes saved overrides")
  require("auto-save").off()
end
local mode, path = arg[1], arg[2]
local fixture
local ok, err = xpcall(function()
  if mode then
    run(path, mode)
  else
    fixture = vim.fn.tempname()
    vim.fn.mkdir(fixture, "p")
    for _, phase in ipairs({ "seed", "restore" }) do
      local result = vim
        .system({
          vim.v.progpath,
          "--headless",
          "-u",
          "NONE",
          "-i",
          "NONE",
          "-l",
          repo .. "/tests/persist_preferences.lua",
          phase,
          fixture .. "/state.json",
        }, { text = true, cwd = fixture })
        :wait()
      assert(result.code == 0, phase .. " failed:\n" .. result.stdout .. result.stderr)
      if phase == "restore" then
        print(vim.trim(result.stdout .. result.stderr))
      end
    end
  end
end, debug.traceback)
if fixture then
  vim.fn.delete(fixture, "rf")
end
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit 1")
end
if mode == "restore" then
  print(string.format("Persistent preferences: %d assertions passed across restarts", passed))
end
vim.cmd("qa!")
