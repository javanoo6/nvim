-- Real Gitsigns cache and live view, plus unavailable/error fixtures.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo)
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/gitsigns.nvim")
local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture, "p")
local passed = 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. "\nactual: " .. vim.inspect(actual))
  passed = passed + 1
end
local function git(...)
  local args = { "git", "-C", fixture }
  vim.list_extend(args, { ... })
  local result = vim.system(args, { text = true }):wait()
  assert(result.code == 0, result.stderr)
end
local live = require("util.live_hunks")
local gs = require("gitsigns")
local systemlist = vim.fn.systemlist
local gs_get_hunks = gs.get_hunks
vim.fn.systemlist = function()
  error("Live hunks must not invoke synchronous Git")
end
local source, source_win, view, view_win
local function view_text()
  return table.concat(vim.api.nvim_buf_get_lines(view, 0, -1, false), "\n")
end
local function locate_view()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.b[b].live_hunks_source_buf == source then
      view = b
    end
  end
  assert(view, "Missing live hunks buffer")
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(w) == view then
      view_win = w
    end
  end
end
local function run()
  git("init", "--quiet")
  local lines = {}
  for i = 1, 80 do
    lines[i] = "line " .. i
  end
  vim.fn.writefile(lines, fixture .. "/tracked.txt")
  git("add", "tracked.txt")
  git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "--quiet", "-m", "fixture")
  vim.cmd.edit(fixture .. "/tracked.txt")
  source = vim.api.nvim_get_current_buf()
  source_win = vim.api.nvim_get_current_win()
  live.setup()
  gs.setup({ auto_attach = false, update_debounce = 10 })
  equal(gs.get_hunks(source), nil, "Actual Gitsigns returns nil before attachment")
  live.open()
  locate_view()
  equal(vim.api.nvim_buf_get_lines(view, 0, 1, false), { "Gitsigns is not attached to this buffer" }, "Unavailable differs from clean")
  gs.attach(source)
  assert(
    vim.wait(5000, function()
      return gs.get_hunks(source) ~= nil
    end, 20),
    "Gitsigns did not attach"
  )
  assert(
    vim.wait(2000, function()
      return view_text():find("No unstaged hunks", 1, true)
    end, 20),
    "Attach event did not refresh view"
  )
  equal(gs.get_hunks(source), {}, "Attached clean buffer returns empty table")
  -- Unsaved edits demonstrate that the view really uses Gitsigns buffer data.
  vim.api.nvim_buf_set_lines(source, 39, 40, false, { "changed once" })
  vim.api.nvim_exec_autocmds("TextChanged", { buffer = source })
  assert(
    vim.wait(3000, function()
      return view_text():find("+changed once", 1, true)
    end, 20),
    "Unsaved hunk not rendered"
  )
  equal(view_text():find("-line 40", 1, true) ~= nil, true, "Removed line rendered")
  for i = 1, 8 do
    vim.api.nvim_buf_set_lines(source, 39, 40, false, { "latest " .. i })
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = source })
  end
  assert(
    vim.wait(3000, function()
      return view_text():find("+latest 8", 1, true)
    end, 20),
    "Rapid edits did not settle on latest data"
  )
  equal(view_text():find("+changed once", 1, true), nil, "Old edit replaced")
  local other = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(other)
  live.refresh(source)
  equal(view_text():find("+latest 8", 1, true) ~= nil, true, "Refreshing another buffer uses original source")
  vim.api.nvim_set_current_buf(source)
  vim.api.nvim_win_set_cursor(source_win, { 60, 0 })
  vim.cmd("normal! zt")
  vim.api.nvim_exec_autocmds("WinScrolled", { pattern = tostring(source_win) })
  equal(vim.api.nvim_win_call(view_win, vim.fn.winsaveview).topline, vim.fn.winsaveview().topline, "View scroll follows source")
  gs_get_hunks = gs.get_hunks
  package.loaded.gitsigns = {}
  live.refresh(source)
  equal(vim.api.nvim_buf_get_lines(view, 0, 1, false), { "Gitsigns is unavailable" }, "Missing API displayed without fallback")
  package.loaded.gitsigns = gs
  gs.get_hunks = function()
    error("fixture provider failure")
  end
  live.refresh(source)
  equal(vim.api.nvim_buf_get_lines(view, 0, 1, false), { "Gitsigns could not read hunks" }, "Provider error displayed without fallback")
  gs.get_hunks = gs_get_hunks
  gs.detach(source)
  live.refresh(source)
  equal(vim.api.nvim_buf_get_lines(view, 0, 1, false), { "Gitsigns is not attached to this buffer" }, "Detached state clears old hunks")
  live.schedule_refresh(source, 10)
  live.close()
  vim.wait(50, function()
    return false
  end)
  equal(vim.api.nvim_buf_is_valid(view), false, "Closing view cancels pending work")
end
local ok, err = xpcall(run, debug.traceback)
gs.get_hunks = gs_get_hunks
package.loaded.gitsigns = gs
vim.fn.systemlist = systemlist
if source and vim.api.nvim_buf_is_valid(source) then
  vim.api.nvim_set_current_buf(source)
  live.close()
  gs.detach(source)
  vim.bo[source].modified = false
end
vim.fn.delete(fixture, "rf")
assert(ok, err)
print("Live hunks: " .. passed .. " assertions passed")
