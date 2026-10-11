-- Run real bootstrap code against disposable data and a simulated Git process.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture .. "/bin", "p")
local stdpath, system = vim.fn.stdpath, vim.fn.system
local runtimepath, original_path = vim.o.runtimepath, vim.env.PATH
local passed, clone_calls = 0, 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. "\nactual: " .. vim.inspect(actual))
  passed = passed + 1
end
local fakegit = fixture .. "/bin/git"
vim.env.PATH = fixture .. "/bin"
local function script(lines)
  vim.fn.writefile(vim.list_extend({ "#!/bin/sh" }, lines), fakegit)
  assert(vim.fn.setfperm(fakegit, "rwx------") == 1, "Could not make fake Git executable")
end
local target
vim.fn.stdpath = function(kind)
  if kind == "data" then
    return target
  end
  return stdpath(kind)
end
vim.fn.system = function(args)
  clone_calls = clone_calls + 1
  equal(args[1], "git", "Git executable requested")
  equal(args[2], "clone", "Clone operation preserved")
  equal(args[#args], target .. "/lazy/lazy.nvim", "Clone destination is disposable")
  return system(args)
end
local function reset(name)
  target = fixture .. "/" .. name
  vim.o.runtimepath = runtimepath
  package.loaded.lazy = nil
  package.loaded["lazy.core.handler.event"] = nil
  vim.g.bootstrap_setup_called = nil
end
local function run()
  script({ 'echo "fatal: unable to access repository: fixture network failure" >&2', "exit 128" })
  reset("failed")
  local ok, err = pcall(dofile, repo .. "/lua/config/lazy.lua")
  equal(ok, false, "Failed clone aborts config")
  equal(err:find("fixture network failure", 1, true) ~= nil, true, "Actual Git failure shown")
  equal(err:find(target .. "/lazy/lazy.nvim", 1, true) ~= nil, true, "Destination named")
  equal(err:find("Check Git", 1, true) ~= nil, true, "Actionable next step given")
  equal(vim.o.runtimepath, runtimepath, "Failed path not added to runtimepath")
  equal(package.loaded.lazy, nil, "Lazy not loaded after failure")
  equal(package.loaded["lazy.core.handler.event"], nil, "Event handler not loaded after failure")
  vim.fn.delete(fakegit)
  reset("missing-git")
  ok, err = pcall(dofile, repo .. "/lua/config/lazy.lua")
  equal(ok, false, "Missing Git aborts config")
  equal(err:find("Failed to install lazy.nvim", 1, true) ~= nil, true, "Spawn exception receives bootstrap context")
  equal(err:find("git", 1, true) ~= nil, true, "Missing executable cause retained")
  equal(vim.o.runtimepath, runtimepath, "Missing executable does not alter runtimepath")
  script({
    "for destination do :; done",
    '/bin/mkdir -p "$destination/lua/lazy/core/handler"',
    'echo "return { mappings = {} }" > "$destination/lua/lazy/core/handler/event.lua"',
    'echo "return { setup = function(opts) vim.g.bootstrap_setup_called = opts.defaults.lazy == false end }" > "$destination/lua/lazy/init.lua"',
    "exit 0",
  })
  reset("successful space %")
  ok, err = pcall(dofile, repo .. "/lua/config/lazy.lua")
  assert(ok, err)
  equal(vim.g.bootstrap_setup_called, true, "Successful clone continues to setup")
  equal(vim.opt.runtimepath:get()[1], target .. "/lazy/lazy.nvim", "Successful path prepended")
  equal(
    require("lazy.core.handler.event").mappings.LazyFile.event,
    { "BufReadPost", "BufNewFile", "BufWritePre" },
    "LazyFile wiring preserved"
  )
  local before = clone_calls
  vim.g.bootstrap_setup_called = nil
  dofile(repo .. "/lua/config/lazy.lua")
  equal(clone_calls, before, "Existing installation skips clone")
  equal(vim.g.bootstrap_setup_called, true, "Existing installation still configures Lazy")
end
local ok, err = xpcall(run, debug.traceback)
vim.fn.stdpath, vim.fn.system = stdpath, system
vim.o.runtimepath, vim.env.PATH = runtimepath, original_path
package.loaded.lazy, package.loaded["lazy.core.handler.event"] = nil, nil
vim.fn.delete(fixture, "rf")
assert(ok, err)
print("Lazy bootstrap: " .. passed .. " assertions passed")
