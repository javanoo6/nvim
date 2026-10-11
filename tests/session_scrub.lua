-- Actual auto-session save/restore lifecycle, with disposable session files.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo)
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/auto-session")
local root = vim.fn.tempname()
local sessions = root .. "/sessions"
vim.fn.mkdir(sessions, "p")
local scrub = require("util.session_scrub")
local auto = require("auto-session")
local spec = require("plugins.sessions")
local opts = vim.deepcopy(spec.opts)
opts.root_dir = sessions
opts.auto_save, opts.auto_restore = false, false
opts.git_use_branch_name, opts.git_auto_restore_on_branch_change = false, false
opts.session_lens = { load_on_setup = false }
spec.config(nil, opts)
local passed = 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. "\nactual: " .. vim.inspect(actual) .. "\nexpected: " .. vim.inspect(expected))
  passed = passed + 1
end
local readfile, writefile = vim.fn.readfile, vim.fn.writefile
local reads, writes = {}, {}
vim.fn.readfile = function(path, ...)
  if path:match("%.vim$") then
    reads[path] = (reads[path] or 0) + 1
  end
  return readfile(path, ...)
end
vim.fn.writefile = function(lines, path, ...)
  if path:match("%.vim$") then
    writes[path] = (writes[path] or 0) + 1
  end
  return writefile(lines, path, ...)
end
local function run()
  local dirty = {
    "let g:session_scrub_marker = 1",
    "setlocal includeformatexpr=bad",
    "let &winminheight = s:save_winminheight",
    "let &winminwidth = s:save_winminwidth",
  }
  local active = sessions .. "/active space %.vim"
  local other = sessions .. "/unused.vim"
  writefile(dirty, active)
  writefile(dirty, other)
  scrub.scrub(active)
  equal(readfile(active), { dirty[1] }, "Invalid option and both orphaned restores removed")
  equal(reads[active], 1, "Only active file read")
  equal(reads[other], nil, "Unrelated legacy session never read")
  equal(readfile(other), dirty, "Unused legacy session remains untouched")
  equal(writes[active], 1, "Changed file written once")
  scrub.scrub(active)
  equal(reads[active], 2, "Next scrub inspects only active file")
  equal(writes[active], 1, "Clean file not rewritten")
  local valid = sessions .. "/valid.vim"
  local valid_lines = {
    "let s:save_winminheight = &winminheight",
    "let s:save_winminwidth = &winminwidth",
    "let &winminheight = s:save_winminheight",
    "let &winminwidth = s:save_winminwidth",
    '" keep everything else',
  }
  writefile(valid_lines, valid)
  scrub.scrub(valid)
  equal(readfile(valid), valid_lines, "Paired restores and valid contents preserved")
  equal(writes[valid], nil, "Valid file not rewritten")
  local outside = root .. "/outside.vim"
  writefile(dirty, outside)
  scrub.scrub(outside)
  equal(reads[outside], nil, "Files outside managed root ignored")
  equal(readfile(outside), dirty, "Unmanaged file untouched")
  scrub.scrub("")
  scrub.scrub(sessions .. "/missing.vim")
  equal(reads[sessions .. "/missing.vim"], nil, "Missing file skipped")
  -- SourcePre repairs the exact old file before Vim reads its invalid lines.
  writefile(dirty, active)
  vim.cmd.source(vim.fn.fnameescape(active))
  equal(vim.g.session_scrub_marker, 1, "SourcePre repairs before source executes")
  equal(readfile(active), { dirty[1] }, "SourcePre cleans exact managed source path")
  equal(reads[other], nil, "SourcePre does not scan unrelated sessions")
  -- Newly generated saved sessions use v:this_session, including special names.
  local user_post_save = opts.post_save_cmds[1]
  require("auto-session.config").post_save_cmds = {
    function()
      local generated = readfile(vim.v.this_session)
      generated[#generated + 1] = "setlocal includeformatexpr=bad"
      writefile(generated, vim.v.this_session)
    end,
    user_post_save,
  }
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  local source = root .. "/Example.lua"
  writefile({ "return 1" }, source)
  vim.api.nvim_buf_set_name(buf, source)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "return 1" })
  vim.bo.modified = false
  equal(auto.save_session("manual % name [branch]", { show_message = false }), true, "Actual auto-session save succeeds")
  local saved = vim.v.this_session
  equal(vim.fs.dirname(saved), sessions, "Saved path belongs to fixture")
  equal(table.concat(readfile(saved), "\n"):find("includeformatexpr", 1, true), nil, "Post-save cleans newly generated session")
  equal(reads[other], nil, "Saving does not read unrelated sessions")
  -- Old damage is repaired just in time during an actual plugin restore.
  local saved_lines = readfile(saved)
  saved_lines[#saved_lines + 1] = "setlocal includeformatexpr=bad"
  saved_lines[#saved_lines + 1] = "let &winminheight = s:save_winminheight"
  saved_lines[#saved_lines + 1] = "let &winminwidth = s:save_winminwidth"
  -- Real mksession saves these variables, so remove their declarations to
  -- produce the historical orphaned restore failure deliberately.
  saved_lines = vim.tbl_filter(function(line)
    return not line:match("^let s:save_winmin")
  end, saved_lines)
  writefile(saved_lines, saved)
  vim.cmd.cd(vim.fn.fnameescape(root))
  equal(auto.restore_session_file(saved, { show_message = false }), true, "Actual auto-session restore succeeds after repair")
  equal(table.concat(readfile(saved), "\n"):find("includeformatexpr", 1, true), nil, "Restore cleans legacy option")
  equal(reads[other], nil, "Restoring does not scan old history")
  equal(vim.v.this_session, saved, "Restore uses intended named session")
  local before = writes[saved]
  scrub.scrub(saved)
  equal(writes[saved], before, "Repaired session remains untouched on next scrub")
  -- A failed write must not pretend the session was repaired.
  writefile(dirty, active)
  local tracking_write = vim.fn.writefile
  vim.fn.writefile = function()
    return -1
  end
  local ok = pcall(scrub.scrub, active)
  vim.fn.writefile = tracking_write
  equal(ok, false, "Repair write failures surface")
end
local ok, err = xpcall(run, debug.traceback)
vim.fn.readfile, vim.fn.writefile = readfile, writefile
vim.api.nvim_clear_autocmds({ group = "custom_session_scrub" })
require("auto-session.config").auto_save = false
vim.cmd.cd(vim.fn.fnameescape(repo))
vim.fn.delete(root, "rf")
assert(ok, err)
print("Session scrub: " .. passed .. " assertions passed")
