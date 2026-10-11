-- Run make check-compatibility after plugin updates; no installs or servers.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local plugin_dir = vim.fn.stdpath("data") .. "/lazy/"
vim.opt.runtimepath:prepend(repo)
local plugins = {
  "cmp-buffer",
  "which-key.nvim",
  "neotest",
  "neotest-python",
  "neotest-golang",
  "neotest-java",
  "intellij-lsp.nvim",
  "bufferline.nvim",
  "glance.nvim",
  "auto-session",
  "git-conflict.nvim",
  "nvim-nio",
}
for _, name in ipairs(plugins) do
  vim.opt.runtimepath:append(plugin_dir .. name)
end
for _, name in ipairs({
  "plenary.nvim",
  "nvim-cmp",
  "LuaSnip",
  "lspkind.nvim",
  "cmp-nvim-lsp",
  "nvim-lsp-file-operations",
  "nvim-dap",
  "nvim-web-devicons",
}) do
  vim.opt.runtimepath:append(plugin_dir .. name)
end
local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture, "p")
local passed = 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), "Compatibility: " .. label .. "\nactual: " .. vim.inspect(actual))
  passed = passed + 1
end
local function callable(value, label)
  equal(type(value), "function", label .. " API")
end
local function buffer(lines)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or { "" })
  return buf
end
local nio = require("nio")
local function run()
  -- Revision drift must trigger review of the documented baseline, not get
  -- silently accepted because a new plugin happens to expose the same names.
  local lock = vim.json.decode(table.concat(vim.fn.readfile(repo .. "/lazy-lock.json"), "\n"))
  local registry = table.concat(vim.fn.readfile(repo .. "/docs/core/compatibility-patches.md"), "\n")
  for _, name in ipairs(plugins) do
    local head = vim.system({ "git", "-C", plugin_dir .. name, "rev-parse", "HEAD" }, { text = true }):wait()
    equal(head.code, 0, name .. " installed checkout")
    equal(vim.trim(head.stdout), lock[name].commit, name .. " installed revision matches lock")
    equal(registry:find(lock[name].commit, 1, true) ~= nil, true, name .. " revision recorded; review registry after upgrading")
    local diff = vim.system({ "git", "-C", plugin_dir .. name, "diff", "--quiet", "HEAD", "--", "lua" }, { text = true }):wait()
    equal(diff.code, 0, name .. " has no undocumented tracked Lua edits")
  end

  -- Exercise the actual completion config against the installed cmp-buffer.
  local cmp_buffer = require("cmp_buffer.buffer")
  for _, name in ipairs({ "new", "safe_buf_call", "index_range", "index_line" }) do
    callable(cmp_buffer[name], "cmp-buffer." .. name)
  end
  equal(type(cmp_buffer.GET_LINES_CHUNK_SIZE), "number", "cmp-buffer chunk-size contract")
  require("plugins.completion")[1].config()
  equal(cmp_buffer.__custom_index_range_bounds_patch, true, "cmp-buffer patch installed")
  local b = buffer({ "alpha beta", "gamma" })
  local index = cmp_buffer.new(b, { keyword_pattern = [[\k\+]], keyword_length = 1, max_indexed_line_length = 4096 })
  index:index_range(-10, 100, false)
  equal(index.lines_words[1], { "alpha", "beta" }, "clamped indexing retains words")
  equal(index.lines_words[2], { "gamma" }, "clamped indexing reaches final line")
  vim.api.nvim_buf_set_lines(b, 1, -1, false, {})
  equal(pcall(index.index_range, index, 0, 100, false), true, "shrunk buffer does not raise out-of-bounds")
  index:close()
  equal(pcall(index.index_range, index, 0, 100, false), true, "closed index skips work")

  -- Actual which-key internals: seed, suspend/reattach, and Diffview refresh.
  vim.g.mapleader = " "
  vim.o.timeoutlen = 1
  vim.keymap.set("n", " ", "<Nop>")
  vim.keymap.set("n", "<leader>zz", function() end, { desc = "fixture action" })
  local triggers = require("which-key.triggers")
  callable(triggers.suspend, "which-key.suspend")
  callable(triggers.attach, "which-key.attach")
  local wkbuf = require("which-key.buf")
  callable(wkbuf.get, "which-key.buf.get")
  callable(wkbuf.clear, "which-key.buf.clear")
  local spec = require("plugins.ui")[2]
  spec.config(nil, spec.opts)
  nio.sleep(100)
  local mode = wkbuf.get({ buf = b, mode = "n" })
  callable(mode.buf.valid, "which-key mode.buf.valid")
  equal(vim.fn.maparg(" ", "n", false, true).desc:find("which-key-trigger", 1, true) ~= nil, true, "leader seeded at setup")
  triggers.suspend(mode)
  nio.sleep(100)
  equal(
    vim.fn.maparg(" ", "n", false, true).desc:find("which-key-trigger", 1, true) ~= nil,
    true,
    "leader reattached after same-mode suspension"
  )
  vim.api.nvim_exec_autocmds("User", { pattern = "DiffviewViewClosed" })
  nio.sleep(100)
  equal(vim.fn.maparg(" ", "n", false, true).desc:find("which-key-trigger", 1, true) ~= nil, true, "Diffview close restores trigger")

  -- Neotest private client layout used by nearest/file, failed and sequential.
  local core_client = require("neotest.client")({})
  for _, name in ipairs({ "get_adapter", "_get_adapter", "get_position", "_update_positions", "get_results", "run_tree" }) do
    callable(core_client[name], "neotest client." .. name)
  end
  local run_consumer = require("neotest.consumers.run")(core_client)
  local upvalue_name, internal = debug.getupvalue(run_consumer.get_tree_from_args, 1)
  equal(upvalue_name, "client", "Neotest run first upvalue name")
  equal(internal, core_client, "Neotest run first upvalue identity")
  callable(require("neotest-golang.lib.goenv").should_skip, "Go workspace filter")

  -- Both replacement output consumers must cap real files and preserve short
  -- output, full-file pointers, and terminal delivery.
  local lib = require("neotest.lib")
  for _, name in ipairs({ "read" }) do
    callable(lib.files[name], "neotest.lib.files." .. name)
  end
  callable(lib.ui.open_term, "neotest.lib.ui.open_term")
  callable(lib.ui.float.open, "neotest.lib.ui.float.open")
  callable(require("neotest.consumers.output_panel.panel"), "Neotest OutputPanel constructor")
  local upstream_output = require("neotest.consumers.output")
  local upstream_panel = require("neotest.consumers.output_panel")
  callable(upstream_output.open, "upstream output.open")
  for _, name in ipairs({ "open", "close", "toggle", "clear", "buffer" }) do
    callable(upstream_panel[name], "upstream panel." .. name)
  end
  require("util.neotest_output_guard").install()
  local Tree = require("neotest.types").Tree
  local tree = Tree.from_list({ { id = "test", type = "test", name = "test", path = fixture .. "/Test.java" } }, function(data)
    return data.id
  end)
  local large = fixture .. "/large-output"
  local small = fixture .. "/small-output"
  vim.fn.writefile({ "HEAD" .. string.rep("m", 8192) .. "TAIL" }, large)
  vim.fn.writefile({ "small output" }, small)
  local results = { test = { output = large, short = "short failure", status = "failed" } }
  local captured = {}
  local send = nio.api.nvim_chan_send
  nio.api.nvim_chan_send = function(chan, data)
    captured[#captured + 1] = data
    return send(chan, data)
  end
  local client = {
    listeners = {},
    get_position = function()
      return tree, "fixture"
    end,
    get_results = function()
      return results
    end,
  }
  local panel = require("neotest.consumers.output_panel")(client)
  local panel_results = client.listeners.results
  vim.g.neotest_output_max_bytes = 128
  client.listeners.results("fixture", results, false)
  local text = table.concat(captured)
  equal(text:find("Output truncated", 1, true) ~= nil, true, "output panel truncates large file")
  equal(text:find(large, 1, true) ~= nil, true, "output panel keeps full output path")
  equal(text:find("HEAD", 1, true) ~= nil and text:find("TAIL", 1, true) ~= nil, true, "output panel retains beginning and end")
  equal(#text < 1000, true, "output panel bounds rendered bytes")
  captured = {}
  results.test.output = small
  client.listeners.results("fixture", results, false)
  equal(table.concat(captured):find("small output", 1, true) ~= nil, true, "small output remains complete")
  panel.clear()
  local output = require("neotest.consumers.output")(client)
  captured = {}
  results.test.output = large
  output.open({
    position_id = "test",
    open_win = function()
      vim.cmd.vsplit()
      return vim.api.nvim_get_current_win()
    end,
  })
  equal(table.concat(captured):find("Output truncated", 1, true) ~= nil, true, "single output consumer also caps large files")
  vim.cmd.close()
  captured = {}
  output.open({
    position_id = "test",
    short = true,
    open_win = function()
      vim.cmd.vsplit()
      return vim.api.nvim_get_current_win()
    end,
  })
  equal(table.concat(captured):find("short failure", 1, true) ~= nil, true, "short output preserved")
  vim.cmd.close()
  nio.api.nvim_chan_send = send
  local fs_read, fs_close = vim.uv.fs_read, vim.uv.fs_close
  local closed = 0
  vim.uv.fs_read = function()
    return nil, "fixture chunk read failure"
  end
  vim.uv.fs_close = function(fd)
    closed = closed + 1
    return fs_close(fd)
  end
  local read_ok, read_error = pcall(panel_results, "fixture", results, false)
  vim.uv.fs_read, vim.uv.fs_close = fs_read, fs_close
  equal(read_ok, false, "chunk read failure surfaces")
  equal(tostring(read_error):find("fixture chunk read failure", 1, true) ~= nil, true, "chunk error retains cause")
  equal(closed, 1, "failed chunk read still closes descriptor")

  -- neotest-java overrides must shadow installed modules and match the real
  -- Path/JunitResult contracts, including single parameterized invocations.
  local Path = require("neotest-java.model.path")
  local checker = require("neotest-java.core.file_checker")({ patterns = { "Test$" } })
  equal(
    checker.is_test_file(fixture .. "/project/src/test/java/ExampleTest.java"),
    true,
    "Java file accepted independently of construction cwd"
  )
  equal(checker.is_test_file(fixture .. "/project/src/main/java/ExampleTest.java"), false, "Main source excluded")
  equal(checker.is_test_file(fixture .. "/project/src/test/java/Helper.java"), false, "Class-name pattern retained")
  local rootfinder = require("neotest-java.core.root_finder")
  vim.fn.mkdir(fixture .. "/git-only/.git", "p")
  equal(rootfinder.find_root(fixture .. "/git-only"), nil, "Git-only Java root excluded")
  vim.fn.writefile({}, fixture .. "/git-only/pom.xml")
  equal(rootfinder.find_root(fixture .. "/git-only"), fixture .. "/git-only", "Maven build root accepted")
  vim.fn.mkdir(fixture .. "/gradle/src/test/java", "p")
  vim.fn.writefile({}, fixture .. "/gradle/build.gradle.kts")
  equal(rootfinder.find_root(fixture .. "/gradle/src/test/java"), fixture .. "/gradle", "Gradle build root accepted")
  local Junit = require("neotest-java.model.junit_result")
  for _, name in ipairs({ "new", "id", "result", "merge_results", "ERROR" }) do
    callable(Junit[name], "JunitResult." .. name)
  end
  local reports = {}
  local removed = 0
  local builder = require("neotest-java.core.result_builder")({
    scan_dir = function()
      return { Path(fixture .. "/TEST-example.xml") }
    end,
    junit_result_reader = {
      read_all = function()
        return reports
      end,
    },
    remove_file = function()
      removed = removed + 1
      return true
    end,
    tempname_fn = function()
      return fixture .. "/junit-output"
    end,
  })
  local method_id = "sample.ExampleTest#method(java.lang.String)"
  local jt = Tree.from_list({ { id = method_id, type = "test" } }, function(data)
    return data.id
  end)
  local rspec = { context = { strategy = "integrated", reports_dir = Path(fixture) } }
  reports = { Junit:new({ _attr = { classname = "sample.ExampleTest", name = "method(java.lang.String)[1]" } }) }
  equal(builder.build_results(rspec, { code = 0 }, jt)[method_id].status, "passed", "Single parameterized invocation maps to method")
  reports[2] = Junit:new({
    _attr = { classname = "sample.ExampleTest", name = "method(java.lang.String)[2]" },
    failure = { _attr = { message = "fixture failure" }, "fixture failure" },
  })
  equal(builder.build_results(rspec, { code = 1 }, jt)[method_id].status, "failed", "Mixed parameterized outcomes aggregate failure")
  equal(removed, 2, "Report cleanup retained")
  equal(builder.build_results(rspec, { code = 2, output = large }, jt)[method_id].status, "failed", "Unexpected test exit maps to failure")
  for _, module in ipairs({ "file_checker", "root_finder", "result_builder" }) do
    local value = require("neotest-java.core." .. module)
    local fn = type(value) == "function" and value or value.find_root
    equal(
      debug.getinfo(fn, "S").source:find(repo .. "/lua/neotest-java/", 1, true) ~= nil,
      true,
      "Java override wins module lookup: " .. module
    )
  end

  -- IntelliJ internal APIs needed by factory, scoped workspace actions, tests,
  -- templates, and DAP integration. This is not a real Java launch/debug run.
  local factory = require("intellij-lsp.client")
  for _, name in ipairs({ "config", "find_root", "find_ancestor_client" }) do
    callable(factory[name], "IntelliJ factory." .. name)
  end
  callable(require("intellij-lsp.progress").is_ready, "IntelliJ readiness")
  callable(require("intellij-lsp.status").is_idle, "IntelliJ idle status")
  callable(require("intellij-lsp.templates").prompt, "IntelliJ template prompt")
  callable(require("intellij-lsp.debug").setup, "IntelliJ debug setup")
  local extensions = require("intellij-lsp.extensions")
  equal(type(extensions.EDITOR_COMMANDS), "table", "IntelliJ editor command registry")
  local plugin = require("intellij-lsp")
  local original_setup, original_factory = plugin.setup, factory.config
  plugin.setup = function() end
  local upstream_attached = 0
  factory.config = function()
    return {
      capabilities = {},
      on_attach = function()
        upstream_attached = upstream_attached + 1
      end,
    }
  end
  local java = require("util.java_intellij")
  java.setup({ accept_eula = true, default_sdk = "/fixture/jdk" })
  local cfg = factory.config(fixture, {})
  equal(cfg.capabilities.textDocument.completion.completionItem.snippetSupport, true, "IntelliJ retains cmp capabilities")
  equal(cfg.capabilities.workspace.fileOperations.willRename, true, "IntelliJ retains file-operation capabilities")
  local completion = vim.lsp.completion.enable
  local completion_args
  vim.lsp.completion.enable = function(...)
    completion_args = { ... }
  end
  cfg.on_attach({ id = 42 }, b)
  equal(upstream_attached, 1, "IntelliJ upstream attach preserved")
  equal(completion_args, { false, 42, b }, "Built-in completion disabled for cmp ownership")
  vim.lsp.completion.enable = completion
  local native_rename = vim.lsp.buf.rename
  local rename_opts
  vim.lsp.buf.rename = function(_, opts)
    rename_opts = opts
  end
  extensions.EDITOR_COMMANDS["editor.action.rename"]()
  equal(rename_opts.name, "intellij", "IntelliJ follow-up rename restricted to owning backend")
  vim.lsp.buf.rename = native_rename
  plugin.setup, factory.config = original_setup, original_factory
  local adapter = require("util.neotest_intellij").create()
  for _, name in ipairs({ "root", "is_test_file", "discover_positions", "build_spec", "results" }) do
    callable(adapter[name], "IntelliJ Neotest adapter." .. name)
  end
  equal(adapter.name, "neotest-intellij-java", "Java bridge constructed without JDTLS")

  -- Bufferline stale-pin recovery depends on this private closure as well as
  -- the removal/refresh functions. Check its live layout before fault fixtures.
  local groups = require("bufferline.groups")
  for _, name in ipairs({ "toggle_pin", "remove_id_from_manual_groupings", "add_element" }) do
    callable(groups[name], "bufferline groups." .. name)
  end
  local found
  for i = 1, 20 do
    local name, value = debug.getupvalue(groups.add_element, i)
    if not name then
      break
    end
    if name == "persist_pinned_buffers" then
      found = value
      break
    end
  end
  callable(found, "bufferline persist_pinned_buffers closure")
  callable(require("bufferline.ui").refresh, "bufferline UI refresh")
  local notice, notify = nil, vim.notify
  vim.notify = function(message)
    notice = message
  end
  package.loaded["bufferline.groups"] = {
    toggle_pin = function()
      error("Invalid buffer id: 987654")
    end,
    remove_id_from_manual_groupings = function(id)
      equal(id, 987654, "Stale pin ID removed")
    end,
    add_element = function() end,
  }
  require("util.bufferline").toggle_pin()
  equal(notice, "Removed a stale bufferline pin", "Stale-pin recovery reports repair")
  package.loaded["bufferline.groups"], vim.notify = groups, notify

  -- Exercise the pinned Glance fork's real reader with a nil libuv result.
  local function upvalue(fn, key)
    for i = 1, 30 do
      local name, value = debug.getupvalue(fn, i)
      if not name then
        break
      end
      if name == key then
        return value
      end
    end
  end
  local List = require("glance.list")
  local process = upvalue(List.setup, "process_locations")
  callable(process, "Glance location processor")
  local get_lines = upvalue(process, "get_lines")
  callable(get_lines, "Glance fork reader")
  local file = fixture .. "/glance-unloaded.txt"
  vim.fn.writefile({ "preview survives nil read" }, file)
  local unloaded = vim.fn.bufadd(file)
  equal(vim.fn.bufloaded(unloaded), 0, "Glance reader fixture initially unloaded")
  local read = vim.uv.fs_read
  vim.uv.fs_read = function()
    return nil, "fixture read failure"
  end
  local reader_ok, preview = pcall(get_lines, unloaded, vim.uri_from_fname(file), { 0 })
  vim.uv.fs_read = read
  equal(reader_ok, true, "Glance fork tolerates nil fs_read")
  equal(preview[0], "preview survives nil read", "Glance falls back to loaded buffer")
  equal(require("plugins.glance")[1].branch, "fix/fs-read-nil-glance-list", "Glance fork selected")
  local glance = require("glance")
  local setup = glance.setup
  local glance_opts
  glance.setup = function(opts)
    glance_opts = opts
  end
  require("plugins.glance")[1].config()
  glance.setup = setup
  equal(glance_opts.winbar.enable, false, "Decompiled-URI winbar remains disabled")

  local conflict_spec = require("plugins.git")[1]
  equal(conflict_spec.opts.disable_diagnostics, false, "Unsupported upstream diagnostic API disabled")
  conflict_spec.config(nil, conflict_spec.opts)
  local conflict_buf = buffer()
  vim.diagnostic.enable(true, { bufnr = conflict_buf })
  vim.api.nvim_exec_autocmds("User", { pattern = "GitConflictDetected" })
  equal(vim.diagnostic.is_enabled({ bufnr = conflict_buf }), false, "Conflict event disables buffer diagnostics")
  vim.api.nvim_exec_autocmds("User", { pattern = "GitConflictResolved" })
  equal(vim.diagnostic.is_enabled({ bufnr = conflict_buf }), true, "Resolved event restores buffer diagnostics")
end
local done, failure
nio.run(function()
  local ok, err = xpcall(run, debug.traceback)
  failure = not ok and err or nil
  done = true
end)
assert(
  vim.wait(30000, function()
    return done
  end, 10),
  "Compatibility checks timed out"
)
vim.fn.delete(fixture, "rf")
assert(not failure, failure)
print("Compatibility patches: " .. passed .. " assertions passed")
