-- Real plugin lifecycle, Git notifications, and a fresh process; disposable data.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(repo)
for _, name in ipairs({ "auto-session", "bufferline.nvim" }) do
  vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/" .. name)
end
vim.env.AUTOSESSION_UNIT_TESTING = "1"
local root = arg[1] or vim.fn.tempname()
local child = arg[2] == "restore"
vim.fn.mkdir(root .. "/sessions", "p")
local passed = 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. "\nactual: " .. vim.inspect(actual) .. "\nexpected: " .. vim.inspect(expected))
  passed = passed + 1
end
local function git(...)
  local command = { "git", "-C", root .. "/project" }
  vim.list_extend(command, { ... })
  local result = vim.system(command, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return vim.trim(result.stdout)
end
local auto = require("auto-session")
local spec = require("plugins.sessions")
local opts = vim.deepcopy(spec.opts)
opts.root_dir = root .. "/sessions"
opts.suppressed_dirs = {}
opts.session_lens = { load_on_setup = false }
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
require("bufferline").setup({})
require("util.bufferline").setup()
spec.config(nil, opts)
local groups = require("bufferline.groups")
local state = require("bufferline.state")
local paths = { root .. "/project/a.lua", root .. "/project/b, special.lua", root .. "/project/c.lua" }
local function current()
  -- Render the actual bar so assertions cover the order users see, not just
  -- the stored custom_sort array.
  vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true, maxwidth = 300 })
  local payload = vim.json.decode(require("util.bufferline").save_session()).bufferline
  return payload
end
local function restore(path)
  equal(auto.restore_session_file(path, { show_message = false }), true, "Session restores")
end
local function run()
  if child then
    restore(root .. "/restart.vim")
    equal(
      current(),
      { order = { paths[2], paths[1], paths[3] }, pins = { paths[2], paths[1] } },
      "Fresh process restores pins and arranged order"
    )
    return
  end
  vim.fn.mkdir(root .. "/project/nested", "p")
  git("init", "-b", "main")
  git("-c", "user.name=Session Test", "-c", "user.email=session@example.invalid", "commit", "--allow-empty", "-m", "fixture")
  git("branch", "other")
  for _, path in ipairs(paths) do
    vim.fn.writefile({ "return true" }, path)
  end
  vim.cmd.cd(root .. "/project/nested")
  equal(auto.auto_restore_session_at_vim_enter(), false, "Fresh workspace has no session")
  equal(require("auto-session.git").uv_git_watcher ~= nil, true, "Fresh startup watches nested repository")
  for _, path in ipairs(paths) do
    vim.cmd.edit(path)
  end
  local ids = vim.tbl_map(vim.fn.bufnr, paths)
  groups.add_element("pinned", { id = ids[2] })
  groups.add_element("pinned", { id = ids[1] })
  -- This is the custom order Bufferline's move command records.
  state.set({ components = {}, custom_sort = { ids[2], ids[1], ids[3] } })
  local expected_main = current()
  equal(
    expected_main,
    { order = { paths[2], paths[1], paths[3] }, pins = { paths[2], paths[1] } },
    "Captures pins and order by exact paths"
  )
  auto.save_session(nil, { show_message = false })
  local main = vim.v.this_session
  vim.fn.writefile(vim.fn.readfile(main), root .. "/restart.vim")
  vim.fn.writefile(vim.fn.readfile(main:gsub("%.vim$", "x.vim")), root .. "/restartx.vim")
  local result = vim
    .system(
      { vim.v.progpath, "--headless", "-u", "NONE", "-i", "NONE", "-l", repo .. "/tests/session_workspace.lua", root, "restore" },
      { text = true }
    )
    :wait()
  equal(result.code, 0, "Fresh-process restore: " .. result.stderr)
  git("switch", "other")
  local other_name = require("auto-session.lib").combine_session_name_with_git_and_tag(vim.fn.getcwd(), "other", nil, false)
  -- A missing destination keeps buffers; wait for the watcher to save main.
  local observed = false
  local auto_save = auto.auto_save_session
  auto.auto_save_session = function(...)
    observed = true
    return auto_save(...)
  end
  assert(
    vim.wait(3000, function()
      return observed
    end, 20),
    "Fresh-start watcher missed branch change"
  )
  auto.auto_save_session = auto_save
  equal(current(), expected_main, "New branch retains current buffers when no session exists")
  vim.cmd("silent %bw!")
  vim.cmd.edit(paths[3])
  groups.add_element("pinned", { id = vim.api.nvim_get_current_buf() })
  state.set({ components = {}, custom_sort = vim.NIL })
  local expected_other = current()
  auto.save_session(other_name, { show_message = false })
  local other = vim.v.this_session
  git("switch", "main")
  assert(
    vim.wait(3000, function()
      return vim.v.this_session == main
    end, 20),
    "Watcher did not restore main"
  )
  equal(current(), expected_main, "Branch return restores main pins and order")
  git("switch", "other")
  assert(
    vim.wait(3000, function()
      return vim.v.this_session == other
    end, 20),
    "Rearmed watcher did not restore other"
  )
  equal(current(), expected_other, "Other branch has its own buffers and pins")
  restore(main)
  equal(current(), expected_main, "Repeated manual restore recovers main metadata")
  restore(other)
  equal(current(), expected_other, "Repeated restore replaces previous pins")
  groups.remove_element("pinned", { id = vim.fn.bufnr(paths[3]) })
  auto.save_session(nil, { show_message = false })
  restore(main)
  restore(other)
  equal(current().pins, {}, "Explicitly unpinned session stays unpinned")
  vim.fn.delete((main:gsub("%.vim$", "x.vim")))
  restore(main)
  equal(current().pins, {}, "Legacy session does not inherit previous pins")
  -- Git worktrees have a .git file rather than a directory.
  require("util.session_branch").stop()
  git("worktree", "add", "-b", "worktree", root .. "/worktree")
  vim.cmd.cd(root .. "/worktree")
  equal(require("auto-session.git").uv_git_watcher ~= nil, true, "Worktree HEAD resolved")
  vim.cmd.cd(root)
  equal(require("auto-session.git").uv_git_watcher, nil, "Leaving Git stops watcher")
end
local ok, err = xpcall(run, debug.traceback)
require("util.session_branch").stop()
require("auto-session.config").auto_save = false
vim.cmd.cd(repo)
if not child then
  vim.fn.delete(root, "rf")
end
assert(ok, err)
print("Session workspace: " .. passed .. " assertions passed")
