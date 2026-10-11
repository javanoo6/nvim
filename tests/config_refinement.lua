-- Run with: make check-config (uses installed plugins; no installs or servers).
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local plugin_dir = vim.fn.stdpath("data") .. "/lazy/"
vim.opt.runtimepath:prepend(repo)
vim.opt.runtimepath:append(repo .. "/after")
for _, name in ipairs({ "nvim-lspconfig", "nvim-treesitter", "nvim-treesitter-textobjects", "mini.ai" }) do
  assert(vim.fn.isdirectory(plugin_dir .. name) == 1, "Missing installed test dependency: " .. name)
  vim.opt.runtimepath:append(plugin_dir .. name)
end

local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture, "p")
local passed = 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual))
  passed = passed + 1
end
local function write(relative, lines)
  local path = fixture .. "/" .. relative
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines or {}, path)
  return path
end
local function buffer(path, lines)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  if path then
    vim.api.nvim_buf_set_name(buf, path)
  end
  if lines then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
  return buf
end
local function normal(keys)
  vim.cmd("normal! " .. vim.keycode(keys))
end
local function lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function run()
  vim.notify = function() end
  vim.g.mapleader = " "
  vim.cmd("filetype plugin on")
  require("config.autocmds")
  require("config.keymaps")

  -- Real FileType transitions must execute the built-in and custom undo scripts.
  for _, name in ipairs({ "wrap", "spell", "linebreak", "breakindent" }) do
    vim.api.nvim_set_option_value(name, false, { scope = "global" })
  end
  buffer(nil, { "[Heading](#heading)", "", "# Heading" })
  vim.bo.filetype = "markdown"
  equal({ vim.wo.wrap, vim.wo.spell, vim.wo.linebreak }, { true, true, true }, "Markdown local options")
  equal(vim.api.nvim_get_option_value("wrap", { scope = "global" }), false, "Markdown preserves global wrap")
  equal(vim.api.nvim_get_option_value("spell", { scope = "global" }), false, "Markdown preserves global spell")
  local undo = vim.b.undo_ftplugin
  assert(undo:find("cms<", 1, true), "Built-in Markdown undo must survive")
  vim.api.nvim_win_set_cursor(0, { 1, 3 })
  vim.fn.maparg("<CR>", "n", false, true).callback()
  equal(vim.fn.line("."), 3, "Markdown link fallback follows heading")
  vim.bo.filetype = "lua"
  equal({ vim.wo.wrap, vim.wo.spell, vim.wo.linebreak }, { false, false, false }, "Markdown undo restores defaults")
  equal(vim.fn.maparg("<CR>", "n", false, true).buffer, 0, "Markdown fallback removed on filetype change")
  buffer()
  vim.cmd.vsplit()
  equal({ vim.wo.wrap, vim.wo.spell }, { false, false }, "Unrelated buffer/window keeps defaults")
  vim.cmd.close()
  -- Plugin loading elsewhere must not remove Markdown's out-of-vault fallback.
  package.loaded.obsidian = {}
  vim.bo.filetype = "markdown"
  equal(vim.fn.maparg("<CR>", "n", false, true).desc, "Follow markdown link", "Fallback survives global Obsidian load")
  vim.keymap.set("n", "<CR>", function() end, { buffer = true, desc = "Follow link" })
  vim.bo.filetype = "lua"
  equal(vim.fn.maparg("<CR>", "n", false, true).desc, "Follow link", "Undo preserves a replacement mapping")
  package.loaded.obsidian = nil

  -- Chart context controls classification, including nested chart boundaries.
  write("chart/Chart.yaml", { "apiVersion: v2", "name: fixture", "version: 0.1.0" })
  write("chart/charts/sub/Chart.yml", { "apiVersion: v2" })
  for relative, expected in pairs({
    ["plain/templates/example.yaml"] = "yaml",
    ["plain/values.yaml"] = "yaml",
    ["plain/values-dev.yml"] = "yaml",
    ["chart/templates/example.yaml"] = "helm",
    ["chart/templates/NOTES.txt"] = "helm",
    ["chart/templates/_helpers.tpl"] = "helm",
    ["chart/values.yaml"] = "yaml.helm-values",
    ["chart/values-dev.yml"] = "yaml.helm-values",
    ["chart/Chart.yaml"] = "yaml.helm-values",
    ["chart/charts/sub/templates/example.yml"] = "helm",
    ["chart/charts/sub/values.yml"] = "yaml.helm-values",
    ["chart/docs/values.yaml"] = "yaml",
  }) do
    equal(vim.filetype.match({ filename = fixture .. "/" .. relative }), expected, "Filetype: " .. relative)
  end

  local events = {}
  for _, hook in ipairs(vim.api.nvim_get_autocmds({ group = "custom_git_mergetool_keys" })) do
    events[hook.event] = true
  end
  equal(events, { VimEnter = true, BufEnter = true, WinEnter = true }, "Both mergetool registrations survive")
  local startup
  for _, hook in ipairs(vim.api.nvim_get_autocmds({ group = "custom_git_mergetool_keys", event = "VimEnter" })) do
    startup = hook.callback
  end
  -- The runner passes a literal DiffviewOpen argument to exercise argv detection.
  startup()
  equal(vim.fn.maparg("<leader>GQ", "n", false, true).rhs, "<cmd>wqa<cr>", "Nested Diffview finish key")
  equal(vim.fn.maparg("<leader>GA", "n", false, true).rhs, "<cmd>cq<cr>", "Nested Diffview abort key")
  vim.keymap.del("n", "<leader>GQ")
  vim.keymap.del("n", "<leader>GA")
  buffer()
  vim.wo.diff = true
  vim.api.nvim_exec_autocmds("WinEnter", { buffer = 0 })
  equal(vim.fn.maparg("<leader>GQ", "n", false, true).buffer, 1, "vimdiff finish key is buffer-local")
  vim.wo.diff = false

  -- Old marks must never determine the live visual duplication range.
  for _, mode in ipairs({ "V", "v", "<C-v>" }) do
    for _, reversed in ipairs({ false, true }) do
      buffer(nil, { "one", "two", "three", "four" })
      vim.api.nvim_buf_set_mark(0, "<", 1, 0, {})
      vim.api.nvim_buf_set_mark(0, ">", 1, 0, {})
      vim.api.nvim_win_set_cursor(0, { reversed and 3 or 2, 0 })
      normal(mode .. (reversed and "k" or "j"))
      vim.fn.maparg("<C-d>", "x", false, true).callback()
      equal(lines(), { "one", "two", "three", "two", "three", "four" }, "Live duplication " .. mode .. tostring(reversed))
      normal("<Esc>")
    end
  end
  buffer(nil, { "one" })
  normal("V")
  vim.fn.maparg("<C-d>", "x", false, true).callback()
  equal(lines(), { "one", "one" }, "First selection without saved marks")
  normal("<Esc>")
  for _, case in ipairs({
    { "leftRIGHT", 4, "left", "RIGHT" },
    { "éRIGHT", 2, "é", "RIGHT" },
    { "RIGHT", 0, "", "RIGHT" },
    { "", 0, "", "" },
    { "left", 4, "left", "" },
  }) do
    for _, key in ipairs({ "ga", "gA" }) do
      buffer(nil, { case[1] })
      vim.wo.virtualedit = "onemore"
      vim.api.nvim_win_set_cursor(0, { 1, case[2] })
      vim.fn.maparg(key, "n", false, true).callback()
      equal(lines(), key == "ga" and { case[4], case[3] } or { case[3], case[4] }, "Split " .. key .. " " .. case[1])
      equal(vim.fn.line("."), key == "ga" and 1 or 2, "Split cursor " .. key)
    end
  end

  -- Native config merging must retain the installed gopls root callback.
  package.preload["cmp_nvim_lsp"] = function()
    return {
      default_capabilities = function()
        return {}
      end,
    }
  end
  package.preload["lsp-file-operations"] = function()
    return {
      default_capabilities = function()
        return {}
      end,
    }
  end
  package.preload["mason-lspconfig"] = function()
    return { setup = function() end }
  end
  local enabled = {}
  local clients = {}
  vim.lsp.get_clients = function()
    return clients
  end
  vim.lsp.enable = function(names, value)
    for _, name in ipairs(type(names) == "table" and names or { names }) do
      enabled[name] = value ~= false
    end
  end
  require("plugins.lsp")[1].config()
  equal(type(vim.lsp.config.gopls.root_dir), "function", "Native gopls root retained")
  -- Stub only go env discovery; the installed root resolver reads real fixtures.
  local system = vim.system
  vim.system = function(cmd, _, callback)
    assert(cmd[1] == "go" and cmd[2] == "env", "Unexpected process in root fixture")
    callback({ code = 0, stdout = fixture .. "/" .. cmd[3], stderr = "" })
  end
  write("go/module/go.mod", { "module example.com/fixture", "go 1.23" })
  write("go/work/go.work", { "go 1.23", "use ./nested" })
  write("go/work/nested/go.mod", { "module example.com/nested", "go 1.23" })
  vim.fn.mkdir(fixture .. "/go/git/.git", "p")
  for _, case in ipairs({
    { "go/module/main.go", "go/module" },
    { "go/work/nested/main.go", "go/work" },
    { "go/git/main.go", "go/git" },
    { "standalone/main.go", nil },
  }) do
    local buf = buffer(write(case[1], { "package main" }))
    local called, actual = false, nil
    vim.lsp.config.gopls.root_dir(buf, function(root)
      called, actual = true, root
    end)
    equal(called, true, "gopls callback: " .. case[1])
    equal(actual, case[2] and (fixture .. "/" .. case[2]) or nil, "gopls root: " .. case[1])
  end
  vim.system = system
  local python_lsp = require("util.python_lsp")
  clients = { {
    name = "pyright",
    stop = function(self)
      self.stopped = true
    end,
  } }
  vim.cmd.PythonLspUseBasedPyright()
  equal({ enabled.pyright, enabled.basedpyright }, { false, true }, "BasedPyright exclusive")
  vim.cmd.PythonLspUsePyright()
  equal({ enabled.pyright, enabled.basedpyright }, { true, false }, "Pyright exclusive")
  python_lsp.select("basedpyright")
  python_lsp.restart()
  equal(clients[1].stopped, true, "Venv restart stops stale client")
  assert(
    vim.wait(500, function()
      return enabled.basedpyright
    end),
    "Restart did not reactivate"
  )
  equal({ enabled.pyright, enabled.basedpyright }, { false, true }, "Restart preserves selection")
  python_lsp.restart()
  python_lsp.select("pyright")
  vim.wait(150, function()
    return false
  end)
  equal({ enabled.pyright, enabled.basedpyright }, { true, false }, "Delayed restart cannot undo newer selection")
  clients = {}
  python_lsp.restart()
  assert(
    vim.wait(500, function()
      return enabled.pyright
    end),
    "Restart without clients failed"
  )
  equal({ enabled.pyright, enabled.basedpyright }, { true, false }, "Restart works before client attachment")

  -- Exercise the actual venv callback wiring with two selected interpreter paths.
  local active_python, dap_python
  package.preload["venv-selector"] = function()
    return {
      python = function()
        return active_python
      end,
    }
  end
  package.preload["dap-python"] = function()
    return {
      setup = function(python)
        dap_python = python
      end,
    }
  end
  python_lsp.select("basedpyright")
  local activate = require("plugins.python-venv")[1].opts().options.on_venv_activate_callback
  for _, env in ipairs({ "env-a", "env-b" }) do
    active_python = write(env .. "/bin/python")
    activate()
    assert(
      vim.wait(500, function()
        return enabled.basedpyright
      end),
      "Venv callback did not restart"
    )
    equal({ enabled.pyright, enabled.basedpyright }, { false, true }, "Venv callback preserves selection: " .. env)
    equal(dap_python, active_python, "Venv callback updates DAP: " .. env)
    equal(vim.env.PATH:match("^[^:]+"), vim.fs.dirname(active_python), "Venv callback puts interpreter first: " .. env)
  end

  -- Actual parser/highlighter checks across aliases; never install during tests.
  dofile(plugin_dir .. "nvim-treesitter/plugin/filetypes.lua")
  local treesitter = require("nvim-treesitter")
  local get_installed = treesitter.get_installed
  local requested
  treesitter.install = function(languages)
    requested = languages
  end
  for _, installed in ipairs({ {}, { "markdown" } }) do
    treesitter.get_installed = function()
      return installed
    end
    require("plugins.treesitter")[1].config()
    equal(vim.tbl_contains(requested, "markdown_inline"), true, "Request inline parser on clean/partial installation")
  end
  treesitter.get_installed = get_installed
  require("plugins.treesitter")[1].config()
  for _, case in ipairs({
    { "lua", "lua", false, "local answer = 42" },
    { "sh", "bash", false, "echo hello" },
    { "javascriptreact", "javascript", false, "const a = <div />;" },
    { "typescriptreact", "tsx", false, "const a = <div />;" },
    { "markdown", "markdown", true, "# Hello" },
    { "yaml", "yaml", true, "answer: 42" },
    { "yaml.helm-values", "yaml", true, "answer: 42" },
  }) do
    local buf = buffer(nil, { case[4] })
    vim.bo[buf].filetype = case[1]
    equal(vim.treesitter.highlighter.active[buf] ~= nil, true, "Highlighter: " .. case[1])
    equal(vim.treesitter.language.get_lang(case[1]), case[2], "Parser alias: " .. case[1])
    equal(vim.bo[buf].indentexpr == "v:lua.require'nvim-treesitter'.indentexpr()", not case[3], "Indent policy: " .. case[1])
  end
  local markdown_buf = buffer(nil, {
    "# Hello",
    "**bold** *italic* `code` ~~gone~~ [link](https://example.com)",
    "",
    "```lua",
    "local answer = 42",
    "```",
  })
  vim.bo[markdown_buf].filetype = "markdown"
  local markdown_parser = vim.treesitter.get_parser(markdown_buf, "markdown")
  markdown_parser:parse(true)
  local captures, injected = {}, {}
  markdown_parser:for_each_tree(function(tree, language_tree)
    local lang = language_tree:lang()
    injected[lang] = true
    if lang == "markdown_inline" then
      local query = assert(vim.treesitter.query.get(lang, "highlights"))
      for id in query:iter_captures(tree:root(), markdown_buf, 0, -1) do
        captures[query.captures[id]] = true
      end
    end
  end)
  equal(injected.markdown_inline, true, "Markdown inline injection")
  equal(injected.lua, true, "Markdown fenced Lua injection")
  for _, capture in ipairs({
    "markup.strong",
    "markup.italic",
    "markup.raw",
    "markup.strikethrough",
    "markup.link.label",
    "markup.link.url",
  }) do
    equal(captures[capture], true, "Markdown inline capture: " .. capture)
  end
  buffer()
  vim.bo.filetype = "unsupported-audit-filetype"
  equal(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], nil, "Unsupported filetype ignored")
  local get_parser = vim.treesitter.get_parser
  vim.treesitter.get_parser = function(buf, lang, opts)
    if lang == "kotlin" then
      return nil
    end
    return get_parser(buf, lang, opts)
  end
  buffer()
  vim.bo.filetype = "kotlin"
  equal(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], nil, "Missing parser ignored")
  vim.treesitter.get_parser = get_parser

  -- Verify separate direct versus next/last text-object ownership.
  require("plugins.treesitter")[2].config()
  for _, spec in ipairs(require("plugins.coding")) do
    if spec[1] == "echasnovski/mini.ai" then
      require("mini.ai").setup(spec.opts())
    end
  end
  equal(vim.fn.maparg("af", "o", false, true).desc, "Select outer function", "Direct function object remains Treesitter-owned")
  equal(vim.fn.maparg("an", "o", false, true).desc, "Around next textobject", "mini.ai next variant remains")
  local mini = require("mini.ai")
  buffer(nil, { "local function first()", "  return 1", "end", "", "local function second()", "  return 2", "end" })
  vim.bo.filetype = "lua"
  vim.treesitter.get_parser():parse()
  local next_fn = mini.find_textobject(
    "a",
    "f",
    { search_method = "next", reference_region = { from = { line = 4, col = 1 }, to = { line = 4, col = 1 } } }
  )
  equal(next_fn.from.line, 5, "mini.ai next function still uses Treesitter spec")
  local previous_fn = mini.find_textobject(
    "a",
    "f",
    { search_method = "prev", reference_region = { from = { line = 4, col = 1 }, to = { line = 4, col = 1 } } }
  )
  equal(previous_fn.from.line, 1, "mini.ai previous function still works")

  -- Manual dirs retain legacy data; removed tracking never touches real history.
  local data = fixture .. "/data"
  vim.fn.mkdir(data, "p")
  local stdpath = vim.fn.stdpath
  vim.fn.stdpath = function(kind)
    return kind == "data" and data or stdpath(kind)
  end
  package.preload["telescope.pickers"] = function()
    error("Use built-in selection in this fixture")
  end
  local dir_a = fixture .. "/go/module"
  local dir_b = fixture .. "/go/work"
  local history = { projects = { "/retired/project" }, recent = { "/historical/project" }, extra = "preserve" }
  for _, field in ipairs({ "manual", "pinned" }) do
    local input = vim.deepcopy(history)
    input[field] = { dir_a, dir_a }
    vim.fn.writefile({ vim.json.encode(input) }, data .. "/frequent-roots.json")
    package.loaded["util.frequent_roots"] = nil
    local dirs = require("util.frequent_roots")
    dirs.add_manual(dir_b)
    local saved = vim.json.decode(table.concat(vim.fn.readfile(data .. "/frequent-roots.json"), "\n"))
    equal(saved.manual, { dir_b, dir_a }, "Manual add/deduplicate: " .. field)
    equal(
      { saved.projects, saved.recent, saved.extra },
      { history.projects, history.recent, history.extra },
      "Opaque history preserved: " .. field
    )
    vim.ui.select = function(items, _, callback)
      callback(items[1])
    end
    local cwd = vim.fn.getcwd()
    dirs.remove_manual_picker()
    saved = vim.json.decode(table.concat(vim.fn.readfile(data .. "/frequent-roots.json"), "\n"))
    equal(saved.manual, { dir_a }, "Fallback picker removes directory: " .. field)
    equal(vim.fn.getcwd(), cwd, "Remove picker does not open directory")
    vim.ui.select = function(items)
      equal(items[1].path, dir_a, "Manual list contents")
    end
    dirs.list_manual()
    equal(dirs.setup, nil, "No retired project tracker")
    equal(dirs.pick_projects, nil, "No retired project picker")
  end
  vim.fn.stdpath = stdpath
  equal(require("util").has, nil, "Unused has export removed")
  equal(require("util").opts, nil, "Unused opts export removed")
  equal(require("util.ruby").bundler_version, nil, "Unused Bundler constant removed")
end

local ok, err = xpcall(run, debug.traceback)
vim.fn.delete(fixture, "rf")
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit 1")
end
print(string.format("Config refinement: %d assertions passed", passed))
vim.cmd("qa!")
