local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(repo)
for _, name in ipairs({ "neotest", "nvim-nio", "plenary.nvim" }) do
  vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/" .. name)
end

local helper = require("util.neotest_summary")
local config = require("neotest.config")
config.summary.open = helper.open
local new_summary = require("neotest.consumers.summary.summary")
local summary = new_summary({}) -- Existing instances must gain the guard too.
helper.install()
helper.install()

local nio = require("nio")
local function async(fn)
  local done, failure = false, nil
  nio.run(fn, function(ok, err)
    failure = not ok and err or nil
    done = true
  end)
  assert(
    vim.wait(5000, function()
      return done
    end),
    "Summary operation timed out"
  )
  assert(not failure, tostring(failure))
end

local function run()
  local source = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(source, "/tmp/neotest-summary-recovery.py")
  vim.api.nvim_buf_set_lines(source, 0, -1, false, { "unsaved work" })
  local editor = vim.api.nvim_get_current_win()
  async(function()
    summary:open({ enter = true })
    summary:close()
  end)
  assert(vim.api.nvim_get_current_win() == editor, "Ordinary close preserves editor window")
  assert(#vim.api.nvim_tabpage_list_wins(0) == 1, "Ordinary close adds no windows")

  async(function()
    summary:open({ enter = true })
  end)
  vim.api.nvim_win_close(editor, true)
  local float_buf = vim.api.nvim_create_buf(false, true)
  local float = vim.api.nvim_open_win(float_buf, false, {
    relative = "editor",
    row = 0,
    col = 0,
    width = 10,
    height = 2,
    focusable = false,
  })
  local closes = 0
  vim.api.nvim_create_autocmd("User", {
    pattern = "NeotestSummaryClose",
    callback = function()
      closes = closes + 1
    end,
  })
  async(function()
    summary:close()
  end)
  assert(not summary.win:is_open(), "Last-window close releases the summary")
  assert(closes == 1, "Close event still fires once")
  assert(vim.api.nvim_get_current_buf() == source, "Listed source buffer is restored")
  assert(vim.bo[source].modified, "Unsaved edits survive recovery")
  assert(not vim.wo.winfixbuf, "Recovered editor allows buffer switching")
  assert(not vim.wo.winfixwidth, "Recovered editor allows resizing")
  vim.api.nvim_win_close(float, true)
  local next_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(next_buf)
  assert(vim.api.nvim_get_current_buf() == next_buf, "Recovered editor accepts another buffer")

  async(function()
    summary:open({ enter = true })
  end)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= summary.win._win then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.bo[source].buflisted = false
  vim.bo[next_buf].buflisted = false
  async(function()
    summary:close()
    summary:close()
  end)
  assert(vim.bo.buftype == "" and vim.bo.buflisted, "No-buffer recovery creates a listed editor buffer")
  assert(vim.api.nvim_buf_get_name(0) == "", "Fallback editor is empty")
  assert(#vim.api.nvim_tabpage_list_wins(0) == 1, "Repeated close adds no windows")
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit 1")
end
print("neotest summary recovery: passed")
vim.cmd("qa!")
