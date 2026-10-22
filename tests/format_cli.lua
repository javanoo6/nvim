-- Run: nvim --headless -u NONE -i NONE -l tests/format_cli.lua
-- Exercise real formatter subprocesses against disposable files only.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
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
end

local ok, err = pcall(suite)
vim.fn.delete(temp, "rf")
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
print("PASS: " .. checks .. " format.sh checks")
vim.cmd("qa!")
