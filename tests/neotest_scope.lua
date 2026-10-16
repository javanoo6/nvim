-- Step 09: real cwd events, discovery filtering, asynchronous adapter specs.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(repo)
local plugins = vim.fn.stdpath("data") .. "/lazy/"
for _, name in ipairs({ "neotest", "nvim-nio", "plenary.nvim", "neotest-python", "neotest-golang" }) do
  vim.opt.rtp:append(plugins .. name)
end
local nio = require("nio")
local scope = require("util.neotest_scope")
local util = require("util")
local fixture = vim.fn.tempname()
local original_cwd = vim.fn.getcwd()
local passed = 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual))
  passed = passed + 1
end
local function write(relative, contents)
  local path = fixture .. "/" .. relative
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(contents or {}, path)
  return path
end
local root_a = fixture .. "/project A"
local root_b = fixture .. "/project B"
local path_a = write("project A/tests/test_example.py", { "def test_example(): pass" })
local path_b = write("project B/tests/test_example.py", { "def test_example(): pass" })
write("project A/pyproject.toml", {})
write("project B/pytest.ini", {})
write("project A/nested/pyproject.toml", {})
local nested_path = write("project A/nested/test_nested.py", {})
local function buffer(path, ft)
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = ft or "python"
  return buf
end
local function tree(path, kind)
  return {
    data = function()
      return { id = path, path = path, type = kind or "file" }
    end,
  }
end
local function async(fn)
  local done, err = false, nil
  nio.run(fn, function(success, failure)
    err = not success and failure or nil
    done = true
  end)
  assert(
    vim.wait(5000, function()
      return done
    end, 10),
    "Async fixture timed out"
  )
  assert(not err, tostring(err))
end
local function run()
  vim.cmd.cd(vim.fn.fnameescape(fixture))
  buffer(path_a)
  util.pin_explorer_cwd(fixture, 5000)
  local events = {}
  vim.api.nvim_create_autocmd("DirChanged", {
    callback = function()
      events[#events + 1] = vim.deepcopy(vim.v.event)
    end,
  })
  -- Exercise the installed filesystem walker before any scope is activated.
  -- Its libuv callbacks must safely resolve the current-buffer fallback.
  local unrelated = write("unrelated/test_unrelated.py", {})
  local ignored = write("project A/build/test_generated.py", {})
  local observed_fast_callback = false
  async(function()
    local files = require("neotest.lib").files.find(fixture, {
      filter_dir = function(...)
        observed_fast_callback = observed_fast_callback or vim.in_fast_event()
        return scope.scoped_discovery_filter(...)
      end,
    })
    equal(vim.tbl_contains(files, path_a), true, "Cold discovery reaches focused project test")
    equal(vim.tbl_contains(files, nested_path), true, "Cold discovery traverses nested directories")
    equal(vim.tbl_contains(files, path_b), false, "Cold discovery excludes other projects")
    equal(vim.tbl_contains(files, unrelated), false, "Cold discovery excludes unactivated siblings")
    equal(vim.tbl_contains(files, ignored), false, "Cold discovery excludes generated directories")
  end)
  equal(observed_fast_callback, true, "Installed walker exercises fast-event fallback")
  scope.activate_scope()
  equal(vim.fn.getcwd(-1, -1), fixture, "Test activation preserves global workspace")
  equal(util.get_explorer_cwd(), fixture, "Test activation preserves explicit explorer pin")
  equal(#events, 0, "Test activation emits no workspace event")

  buffer(path_b)
  scope.activate_scope()
  equal(vim.fn.getcwd(), fixture, "Second project preserves editor cwd")
  equal(util.get_explorer_cwd(), fixture, "Explorer scope survives second project")
  equal(scope.scoped_discovery_filter("tests", "tests", root_a), true, "Previous project's async discovery remains allowed")
  equal(scope.scoped_discovery_filter("tests", "tests", root_b), true, "New project's discovery remains allowed")
  equal(scope.scoped_discovery_filter("project A", "project A", fixture), true, "Shared parent retains first module")
  equal(scope.scoped_discovery_filter("project B", "project B", fixture), true, "Shared parent retains second module")
  equal(scope.scoped_discovery_filter("unrelated", "unrelated", fixture), false, "Unactivated sibling remains excluded")
  equal(scope.scoped_discovery_filter(".git", ".git", root_b), false, "Ignored dirs remain excluded")
  async(function()
    local files = require("neotest.lib").files.find(fixture, { filter_dir = scope.scoped_discovery_filter })
    equal(vim.tbl_contains(files, path_a), true, "Real scan retains first activated project")
    equal(vim.tbl_contains(files, path_b), true, "Real scan retains second activated project")
    equal(vim.tbl_contains(files, unrelated), false, "Real scan excludes unactivated siblings")
    equal(vim.tbl_contains(files, ignored), false, "Real scan excludes generated directories")
  end)
  equal(scope.discovery_cwd(path_a), root_a, "Discovery retains first project's cwd")
  equal(scope.discovery_cwd(path_b), root_b, "Discovery retains second project's cwd")
  local goenv = require("neotest-golang.lib.goenv")
  goenv.set_cache_for_testing({ gopath = root_a, goroot = fixture .. "/sdk" })
  equal(goenv.should_skip(path_a, scope.discovery_cwd(path_a)), false, "Activated GOPATH project is discoverable from another cwd")
  equal(
    goenv.should_skip(fixture .. "/sdk/example_test.go", scope.discovery_cwd(fixture .. "/sdk/example_test.go")),
    true,
    "Unactivated SDK tests remain skipped"
  )

  buffer(nested_path)
  equal(scope.current_scope().focus_root, root_a .. "/nested", "Nested test project marker wins")
  scope.activate_scope()
  equal(util.get_explorer_cwd(), fixture, "Nested test scope preserves explorer choice")
  equal(scope.discovery_cwd(nested_path), root_a .. "/nested", "Discovery chooses most specific activated scope")
  vim.cmd.cd(vim.fn.fnameescape(root_a .. "/nested"))
  buffer(path_a)
  local before = #events
  scope.activate_scope()
  equal(vim.fn.getcwd(), root_a .. "/nested", "Explicit narrower cwd is retained")
  equal(#events, before, "Already nested activation emits no artificial event")

  vim.cmd.tcd(vim.fn.fnameescape(root_b))
  vim.cmd.lcd(vim.fn.fnameescape(root_b .. "/tests"))
  buffer(path_a)
  scope.activate_scope()
  equal(
    { vim.fn.getcwd(), vim.fn.getcwd(-1, 0), vim.fn.getcwd(-1, -1) },
    { root_b .. "/tests", root_b, root_a .. "/nested" },
    "Cross-project activation preserves local/tab/global cwd"
  )

  -- UI focus changes must not change the source captured by with_scope().
  local captured
  package.loaded.neotest = {
    summary = {
      open = function()
        buffer(path_b)
      end,
    },
    output_panel = { clear = function() end },
  }
  buffer(path_a)
  scope.with_scope(function(ctx)
    captured = ctx
  end)()
  scope.activate_scope()
  equal(captured.path, path_a, "UI switch preserves source path")
  equal(captured.scope.focus_root, root_a, "UI switch preserves source scope")
  equal(scope.get_scope().focus_root, root_b, "New active scope is independent of captured run")
  local opened, closed, cleared = 0, 0, 0
  package.loaded.neotest = {
    summary = {
      open = function()
        opened = opened + 1
      end,
      close = function()
        closed = closed + 1
      end,
    },
    output_panel = {
      clear = function()
        cleared = cleared + 1
      end,
    },
  }
  -- Execute every configured debug key, so new wrappers cannot silently open UI.
  local debug_keys = { ["<leader>td"] = true, ["<leader>tP"] = true, ["<leader>tL"] = true, ["<leader>tf"] = true, ["<leader>tD"] = true }
  for _, plugin in ipairs(require("plugins.neotest")) do
    if plugin[1] == "nvim-neotest/neotest" then
      package.loaded.neotest.run = { run = function() end, run_last = function() end }
      package.loaded.neotest.state = {
        adapter_ids = function()
          return {}
        end,
      }
      local nearest = scope.run_nearest
      scope.run_nearest = function() end
      for _, key in ipairs(plugin.keys) do
        if debug_keys[key[1]] then
          key[2]()
        end
      end
      scope.run_nearest = nearest
    end
  end
  equal(opened, 0, "Debug mappings never open summary")
  equal(closed, 5, "Every debug mapping closes existing summary")
  equal(cleared, 5, "Debug mappings still clear old output")
  scope.with_scope(function() end)()
  equal(opened, 1, "Regular test run still opens summary")
  local dap_before = package.loaded.dap
  local debug_before = package.loaded["intellij-lsp.debug"]
  local fake_dap = { listeners = { before = { event_initialized = {} }, after = { event_terminated = {}, event_exited = {} } } }
  package.loaded.dap = fake_dap
  package.loaded["intellij-lsp.debug"] = { setup = function() end }
  require("util.debug_ui").setup()
  fake_dap.listeners.before.event_initialized.close_test_summary()
  equal(closed, 6, "DAP initialization closes summary for non-test debug entry points")
  package.loaded.dap = dap_before
  package.loaded["intellij-lsp.debug"] = debug_before
  package.loaded.neotest = nil

  -- A builder that yields while B activates must still launch A from A's root.
  local adapter = require("util.neotest_python").with_project_cwd({
    root = function()
      return root_a
    end,
    build_spec = function()
      nio.sleep(30)
      return { strategy = { cwd = vim.fn.getcwd() } }
    end,
  })
  async(function()
    local result
    local building = nio.control.future()
    buffer(path_a)
    scope.activate_scope()
    nio.run(function()
      result = adapter.build_spec({ tree = tree(path_a), strategy = "dap" })
      building.set()
    end)
    nio.sleep(10)
    nio.scheduler()
    buffer(path_b)
    scope.activate_scope()
    building.wait()
    equal(result.cwd, root_a, "Delayed Python process keeps original root")
    equal(result.strategy.cwd, root_a, "Delayed Python DAP launch keeps original root")
    equal(vim.fn.getcwd(), root_b .. "/tests", "Finishing old build preserves editor cwd")
  end)

  -- Use the installed Python adapter to build both run and DAP specs.
  local python = require("util.neotest_python").with_project_cwd(require("neotest-python")({ python = "python3", runner = "unittest" }))
  async(function()
    for _, path in ipairs({ path_a, path_b }) do
      for _, strategy in ipairs({ "integrated", "dap" }) do
        local spec = python.build_spec({ tree = tree(path), strategy = strategy })
        local expected = path == path_a and root_a or root_b
        equal(spec.cwd, expected, "Installed Python process cwd: " .. path .. strategy)
        if strategy == "dap" then
          equal(spec.strategy.cwd, expected, "Installed Python DAP cwd: " .. path)
        end
        spec.context.stop_stream()
      end
    end
    local spec = python.build_spec({ tree = tree(path_a), cwd = root_b, strategy = "dap" })
    equal({ spec.cwd, spec.strategy.cwd }, { root_b, root_b }, "Explicit run cwd override is respected")
    spec.context.stop_stream()
  end)

  -- Restoring a session clears the cumulative scopes from the previous session.
  buffer(path_b)
  local session = fixture .. "/session.vim"
  vim.cmd.mksession({ args = { session }, bang = true })
  buffer(path_a)
  scope.activate_scope()
  vim.cmd.source(vim.fn.fnameescape(session))
  equal(scope.get_scope().focus_root, root_b, "Restored session uses restored source scope")
  equal(scope.scoped_discovery_filter("tests", "tests", root_a), false, "Old discovery scopes cleared on session restore")
  equal(scope.scoped_discovery_filter("tests", "tests", root_b), true, "Restored project remains discoverable")
  async(function()
    local files = require("neotest.lib").files.find(fixture, { filter_dir = scope.scoped_discovery_filter })
    equal(vim.tbl_contains(files, path_b), true, "Restored discovery safely reads fallback scope in real scan")
    equal(vim.tbl_contains(files, path_a), false, "Restored discovery excludes previous session's scopes")
  end)

  write("java/pom.xml", {})
  local java = write("java/src/test/java/ExampleTest.java", {})
  buffer(java, "java")
  scope.activate_scope()
  equal(scope.get_scope().focus_root, fixture .. "/java", "Java retains specialized Maven scope")
  equal(util.get_explorer_cwd(), fixture, "Java scope preserves explorer choice")
end
local ok, err = xpcall(run, debug.traceback)
vim.cmd.cd(vim.fn.fnameescape(original_cwd))
vim.fn.delete(fixture, "rf")
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit 1")
end
print(string.format("Neotest scope: %d assertions passed", passed))
vim.cmd("qa!")
