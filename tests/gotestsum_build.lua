-- Offline build-hook checks: fake Go subprocess, no downloads or real installs.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo)
local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture, "p")
local passed = 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. " expected " .. vim.inspect(expected) .. " got " .. vim.inspect(actual))
  passed = passed + 1
end
local original_path, original_system = vim.env.PATH, vim.system
local function run()
  local build = require("plugins.neotest")[2].build
  local target = "gotest.tools/gotestsum@v1.13.0"
  local fake_go = fixture .. "/go"
  vim.env.PATH = fixture
  local function fails(fragment)
    local ok, err = pcall(build)
    equal(ok, false, "Build reports failure")
    equal(tostring(err):find(fragment, 1, true) ~= nil, true, "Underlying cause retained")
    equal(tostring(err):find(target, 1, true) ~= nil, true, "Pinned target identified")
    equal(tostring(err):find(":Lazy build neotest-golang", 1, true) ~= nil, true, "Retry instruction present")
  end
  fails("go executable not found")
  local function executable(lines)
    vim.fn.writefile(lines, fake_go)
    assert(vim.fn.setfperm(fake_go, "rwx------") == 1, "Cannot make fixture Go executable")
  end
  executable({ "#!/bin/sh", '[ "$1" = install ] && [ "$2" = ' .. target .. ' ] && [ "$#" = 2 ] || exit 9', "exit 0" })
  equal(pcall(build), true, "Successful pinned install completes")
  for _, message in ipairs({ "network unavailable", "compiler failed" }) do
    executable({ "#!/bin/sh", 'echo "' .. message .. '" >&2', "exit 7" })
    fails(message)
  end
  executable({ "#!/bin/sh", "exit 3" })
  fails("No process output")
  vim.system = function()
    error("fixture spawn failure")
  end
  fails("fixture spawn failure")
  vim.system = function()
    return {
      wait = function()
        error("fixture wait failure")
      end,
    }
  end
  fails("fixture wait failure")
  vim.system = function()
    return {
      wait = function()
        return { code = 143, signal = 15, stderr = "", stdout = "" }
      end,
    }
  end
  fails("signal 15")
end
local ok, err = xpcall(run, debug.traceback)
vim.env.PATH, vim.system = original_path, original_system
vim.fn.delete(fixture, "rf")
if not ok then
  print(err)
  vim.cmd("cquit 1")
end
print(string.format("Gotestsum build: %d assertions passed", passed))
