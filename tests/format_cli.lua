-- Run: nvim --headless -u NONE -i NONE -l tests/format_cli.lua
-- Exercise real formatter subprocesses against disposable files only.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")
local checks = 0

local function check(condition, message)
  assert(condition, message)
  checks = checks + 1
end

local function run(args)
  local cmd = { root .. "/format.sh" }
  vim.list_extend(cmd, args)
  return vim.system(cmd, { cwd = temp, text = true }):wait(30000)
end

local function write(name, lines)
  vim.fn.writefile(lines, temp .. "/" .. name)
end

local function read(name)
  return table.concat(vim.fn.readfile(temp .. "/" .. name), "\n")
end

local function suite()
  local helper = require("util.format")
  local config = require("plugins.formatting")[1].opts
  for _, ft in ipairs({
    "java",
    "json",
    "jsonc",
    "json5",
    "markdown",
    "python",
    "sh",
    "zsh",
    "toml",
    "html",
    "xhtml",
    "xml",
    "xslt",
    "yaml",
    "yaml.helm-values",
  }) do
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = ft
    check(config.formatters_by_ft[ft][1] == "idea_formatter", ft .. " must use the jar")
    local opts, err = helper.options(buf)
    check(opts and opts.lsp_format == "never", ft .. ": " .. tostring(err))
    check(config.format_on_save(buf).timeout_ms == 10000, ft .. " needs the standalone timeout")
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  check(config.formatters_by_ft.javascript[1] == "prettier", "JavaScript keeps its formatter")

  check(run({ "--help" }).code == 0, "Help failed")
  check(run({}).code == 2, "No paths must be a usage error")
  check(run({ "--unknown" }).code == 2, "Unknown option must be a usage error")
  local name = "space ' quote ; $(touch INJECTED).lua"
  write(name, { "local   value=1" })
  local result = run({ name, name })
  check(result.code == 0, result.stdout .. result.stderr)
  check(read(name) == "local value = 1", "Lua was not formatted")
  check(vim.fn.filereadable(temp .. "/INJECTED") == 0, "Path executed as shell code")
  local _, count = result.stdout:gsub("formatted:", "")
  check(count == 1, "Duplicate files must be formatted once")
  local before = vim.uv.fs_stat(temp .. "/" .. name).mtime
  check(run({ name }).code == 0, "Idempotent run failed")
  check(vim.deep_equal(before, vim.uv.fs_stat(temp .. "/" .. name).mtime), "Unchanged file was rewritten")

  write("-leading.lua", { "local   value=2" })
  check(run({ "--", "-leading.lua" }).code == 0, "Dash-leading path failed")
  check(read("-leading.lua") == "local value = 2", "Dash-leading file was not formatted")

  write("untouched.lua", { "local   value=3" })
  result = run({ "untouched.lua", "missing.lua" })
  check(result.code == 1 and result.stdout:find("error:", 1, true), "Missing file must fail")
  check(read("untouched.lua") == "local   value=3", "Preflight failure wrote an earlier file")
  write("unsupported.txt", { "plain text" })
  check(run({ "unsupported.txt" }).code == 1, "Unsupported file must fail")

  write("broken.lua", { "local = !!!" })
  result = run({ "broken.lua" })
  check(result.code == 1 and result.stdout:find("error:", 1, true), "Formatter failure must exit nonzero")
  check(read("broken.lua") == "local = !!!", "Failed formatting changed the source")

  write("document.md", { "# Example", "", "Some **Markdown**." })
  check(run({ "document.md" }).code == 0, "Standalone Markdown formatting failed")
  check(read("document.md"):find("Some **Markdown**.", 1, true), "Markdown content lost")

  local samples = {
    { "Sample.java", { "class Sample{int sum(int a,int b){return a+b;}}" }, "return a + b;" },
    { "sample.py", { "def add(a,b):", "    return a+b" }, "def add(a, b):" },
    { "sample.pyw", { "def add(a,b):", "    return a+b" }, "def add(a, b):" },
    { "sample.pyi", { "def add(a:int,b:int)->int: ..." }, "def add(a: int, b: int) -> int:" },
    { "sample.json", { '{"key":1}' }, '"key": 1' },
    { "sample.jsonc", { "// keep this comment", '{"key":1}' }, '"key": 1' },
    { "sample.json5", { "{key:'value',}" }, "key: 'value'" },
    { "sample.toml", { "[section]", "key=1" }, "key = 1" },
    { "sample.xml", { "<root><child>value</child></root>" }, "\n  <child>" },
    { "sample.html", { "<html><body><div><p>Hello</p></div></body></html>" }, "<html>\n" },
    { "sample.xhtml", { '<html xmlns="http://www.w3.org/1999/xhtml"><body><div><p>Hello</p></div></body></html>' }, "<body>\n" },
    {
      "sample.xsl",
      {
        '<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"><xsl:template match="/"><output/></xsl:template></xsl:stylesheet>',
      },
      "\n  <xsl:template",
    },
    { "sample.yaml", { "root:", "   child:  1" }, "\n  child: 1" },
    { "sample.yml", { "root:", "   child:  1" }, "\n  child: 1" },
    { "sample.sh", { "#!/bin/bash", "if true;then", "echo  hello", "fi" }, "if true; then" },
    { "sample.bash", { "#!/bin/bash", "if true;then", "echo  hello", "fi" }, "if true; then" },
    { "sample.zsh", { "#!/bin/zsh", "if true;then", "echo  hello", "fi" }, "if true; then" },
    { "shell-script", { "#!/usr/bin/env bash", "if true;then", "echo  hello", "fi" }, "if true; then" },
  }
  local paths = {}
  for _, sample in ipairs(samples) do
    write(sample[1], sample[2])
    paths[#paths + 1] = sample[1]
  end
  result = run(paths)
  check(result.code == 0, result.stdout .. result.stderr)
  for _, sample in ipairs(samples) do
    check(read(sample[1]):find(sample[3], 1, true), sample[1] .. " was not formatted: " .. read(sample[1]))
  end
  check(read("sample.jsonc"):find("// keep this comment", 1, true), "JSONC comment lost")

  write("invalid.sh", { "#!/bin/bash", "if true; then" })
  result = run({ "invalid.sh" })
  check(result.code == 1, "Invalid shell script must fail")
  check(read("invalid.sh") == "#!/bin/bash\nif true; then", "Failed shell formatting changed the source")
end

local ok, err = pcall(suite)
vim.fn.delete(temp, "rf")
if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
end
print("PASS: " .. checks .. " format.sh checks")
vim.cmd("qa!")
