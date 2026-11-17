-- Run: nvim --headless -u NONE -l tests/lazygit_unstash.lua
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local helper = repo .. "/scripts/lazygit-unstash.sh"
local fixtures = {}
local function run(dir, args, allow_failure)
  local result = vim.system(args, { cwd = dir, text = true }):wait()
  assert(allow_failure or result.code == 0, result.stderr .. result.stdout)
  return result
end
local function git(dir, ...)
  return vim.trim(run(dir, { "git", ... }).stdout)
end
local function write(dir, name, content)
  vim.fn.writefile({ content }, dir .. "/" .. name)
end
local function fixture()
  local dir = vim.fn.tempname()
  fixtures[#fixtures + 1] = dir
  vim.fn.mkdir(dir, "p")
  git(dir, "init", "--quiet")
  git(dir, "config", "user.name", "Fixture")
  git(dir, "config", "user.email", "fixture@example.invalid")
  for _, name in ipairs({ "tracked", "deleted", "prior" }) do
    write(dir, name, "base")
  end
  git(dir, "add", ".")
  git(dir, "commit", "--quiet", "-m", "base")
  return dir
end
local function check()
  for _, action in ipairs({ "apply", "pop" }) do
    local dir = fixture()
    write(dir, "tracked", "restored")
    write(dir, "new file", "new")
    vim.fn.delete(dir .. "/deleted")
    git(dir, "add", ".")
    git(dir, "stash", "push", "-m", "restore me")
    -- Select an older stash to verify the selected index is honored.
    write(dir, "prior", "newer stash")
    git(dir, "stash", "push", "-m", "leave me")
    write(dir, "prior", "already staged")
    git(dir, "add", "prior")
    write(dir, "prior", "also unstaged")
    local before = git(dir, "write-tree")
    run(dir, { "sh", helper, action, "1" })
    assert(git(dir, "write-tree") == before, "Pre-existing staged content changed")
    assert(vim.fn.readfile(dir .. "/prior")[1] == "also unstaged", "Working edits changed")
    assert(vim.fn.readfile(dir .. "/tracked")[1] == "restored", "Tracked edit missing")
    assert(vim.fn.readfile(dir .. "/new file")[1] == "new", "Added file missing")
    assert(vim.fn.filereadable(dir .. "/deleted") == 0, "Deletion missing")
    assert(git(dir, "ls-files", "--", "new file") == "", "Restored addition staged")
    local count = #vim.split(git(dir, "stash", "list"), "\n")
    assert(count == (action == "pop" and 1 or 2), "Wrong stash removed")
    print(action .. ": additions/edits/deletions unstaged; prior index and working edits preserved")
  end
  local dir = fixture()
  write(dir, "tracked", "stashed version")
  git(dir, "stash", "push", "-m", "conflict")
  write(dir, "tracked", "committed version")
  git(dir, "add", "tracked")
  git(dir, "commit", "--quiet", "-m", "diverge")
  local result = run(dir, { "sh", helper, "pop", "0" }, true)
  assert(result.code ~= 0, "Conflicting pop succeeded")
  assert(git(dir, "ls-files", "-u") ~= "", "Unmerged index was overwritten")
  assert(git(dir, "stash", "list") ~= "", "Conflicting stash was dropped")
  local conflicted_index = git(dir, "ls-files", "--stage")
  result = run(dir, { "sh", helper, "apply", "0" }, true)
  assert(result.code ~= 0, "Unmerged index should prevent applying")
  assert(git(dir, "ls-files", "--stage") == conflicted_index, "Existing conflict changed")
  print("conflicts: stash retained and unmerged index preserved; existing conflicts refused")
end
local ok, err = xpcall(check, debug.traceback)
for _, dir in ipairs(fixtures) do
  vim.fn.delete(dir, "rf")
end
assert(ok, err)
