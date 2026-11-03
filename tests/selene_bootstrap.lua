-- Offline checks for first-install selection, concurrency, and retry behavior.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo)
local helper = require("util.selene")
local original = { uname = vim.uv.os_uname, executable = vim.fn.executable, system = vim.system, notify = vim.notify }
local host, available, calls, pending = { sysname = "Linux", machine = "aarch64" }, {}, {}, nil
vim.uv.os_uname = function()
  return host
end
vim.fn.executable = function(name)
  return available[name] and 1 or 0
end
vim.notify = function() end
vim.system = function(cmd, _, callback)
  calls[#calls + 1] = cmd
  pending = callback
  return {}
end
local function run()
  assert(helper.source_install(), "Linux ARM64 uses source builds")
  host.machine = "x86_64"
  assert(not helper.source_install(), "Other platforms use Mason")
  host = { sysname = "Darwin", machine = "arm64" }
  assert(not helper.source_install(), "Other platforms use Mason")
  host = { sysname = "Linux", machine = "arm64" }
  assert(helper.source_install(), "Linux ARM64 uses source builds")
  available.selene = true
  helper.install()
  assert(#calls == 0, "Existing executable skips builds")
  available = { mise = true }
  helper.install()
  assert(vim.deep_equal(vim.list_slice(calls[1], 1, 5), { "mise", "exec", "rust@stable", "--", "cargo" }), "mise supplies Rust")
  assert(table.concat(calls[1], " "):find("--version 0.31.0 --locked", 1, true), "Crate and dependencies are pinned")
  helper.install()
  assert(#calls == 1, "Concurrent install must be suppressed")
  pending({ code = 1, stderr = "network unavailable" })
  vim.wait(100, function()
    return false
  end)
  available = { cargo = true }
  helper.install()
  assert(#calls == 2 and calls[2][1] == "cargo", "Failed build must allow Cargo retry")
  pending({ code = 0 })
  vim.wait(100, function()
    return false
  end)
  available = {}
  helper.install()
  assert(#calls == 2, "Missing build tools must not spawn")
end
local ok, err = xpcall(run, debug.traceback)
vim.uv.os_uname, vim.fn.executable, vim.system, vim.notify = original.uname, original.executable, original.system, original.notify
if not ok then
  print(err)
  vim.cmd("cquit 1")
end
print("Selene bootstrap: passed")
