-- Isolated editing-path regressions; no plugins, sessions, or language servers.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo)
local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture, "p")
local passed = 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. ": " .. vim.inspect(actual))
  passed = passed + 1
end
local function buffer(path, lines)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, path)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or { "word" })
  return buf
end

local function run()
  vim.cmd.cd(fixture)
  local deep = fixture .. "/project"
  vim.fn.mkdir(deep, "p")
  vim.fn.writefile({}, deep .. "/.git")
  for i = 1, 18 do
    deep = deep .. "/level" .. i
  end
  vim.fn.mkdir(deep, "p")
  local current = buffer(deep .. "/example.lua")
  vim.api.nvim_set_current_buf(current)
  local root = require("util.statusline_root")
  local util = require("util")
  local resolve = util.get_root_basename
  local calls = 0
  util.get_root_basename = function(...)
    calls = calls + 1
    return resolve(...)
  end
  equal(root.get(), "project", "initial root label")
  local start = vim.uv.hrtime()
  for _ = 1, 500 do
    root.get()
  end
  local elapsed = (vim.uv.hrtime() - start) / 1e6
  equal(calls, 1, "500 redraws avoid repeated root searches")
  print(string.format("Cached root label: %.4f ms/call over 500 calls", elapsed / 500))

  vim.cmd.lcd(deep)
  equal(root.get(), "level18", "window cwd narrows label immediately")
  vim.cmd.cd(fixture)
  equal(root.get(), "project", "cwd reset restores label")
  local other = buffer(fixture .. "/other.lua")
  vim.api.nvim_set_current_buf(other)
  equal(root.get(), vim.fs.basename(fixture), "buffer switch updates label")
  vim.api.nvim_buf_set_name(other, deep .. "/renamed.lua")
  equal(root.get(), "project", "rename updates label")
  for _, event in ipairs({ "LspAttach", "LspDetach", "BufWritePost", "FocusGained" }) do
    local before = calls
    vim.api.nvim_exec_autocmds(event, { buffer = other })
    root.get()
    equal(calls, before + 1, event .. " invalidates label")
  end
  -- External marker changes have no Neovim event; the TTL must recover them.
  vim.fn.writefile({}, deep .. "/package.json")
  vim.wait(1050, function()
    return false
  end)
  equal(root.get(), "level18", "external marker appears after TTL")
  vim.fn.delete(deep .. "/package.json")
  util.get_root_basename = resolve

  vim.api.nvim_set_current_buf(current)
  local visible = buffer(fixture .. "/visible.lua")
  vim.cmd.vsplit()
  vim.api.nvim_set_current_buf(visible)
  local get_buffers = require("util.completion_buffers").get
  equal(get_buffers(), { visible, current }, "current buffer first, visible split included")
  for i = 1, 100 do
    buffer(fixture .. "/hidden" .. i .. ".lua")
  end
  equal(get_buffers(), { visible, current }, "session-sized hidden buffers excluded")
  vim.cmd.vsplit()
  equal(get_buffers(), { visible, current }, "duplicate split buffers indexed once")
  vim.bo[visible].buftype = "nofile"
  equal(get_buffers(), { current }, "plugin panels excluded")
  vim.bo[visible].buftype = ""
  vim.api.nvim_buf_set_lines(visible, 0, -1, false, { string.rep("x", 512 * 1024) })
  equal(get_buffers(), { current }, "large buffer excluded")

  -- Three individually eligible buffers must still obey the aggregate budget.
  local large = string.rep("x", 400 * 1024)
  vim.api.nvim_buf_set_lines(visible, 0, -1, false, { large })
  vim.api.nvim_buf_set_lines(current, 0, -1, false, { large })
  local third = buffer(fixture .. "/third.lua", { large })
  vim.api.nvim_set_current_buf(third)
  local selected = get_buffers()
  equal(selected[1], third, "current buffer gets priority under budget")
  equal(#selected, 2, "aggregate indexing budget enforced")
end

local ok, err = xpcall(run, debug.traceback)
vim.fn.delete(fixture, "rf")
if not ok then
  print(err)
  vim.cmd.cquit()
end
print(string.format("Responsiveness: %d checks passed", passed))
vim.cmd("qa!")
