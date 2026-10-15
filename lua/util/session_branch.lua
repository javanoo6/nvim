local M = {}

-- Upstream starts watching only after a restore and assumes cwd/.git/HEAD.
-- Resolve HEAD through Git so nested directories and worktrees work as well.
function M.setup()
  local git = require("auto-session.git")
  if M.installed then
    return
  end
  M.installed = true
  local start_watcher = git.start_watcher
  local stop_watcher = git.stop_watcher
  git.stop_watcher = function()
    local watcher = git.uv_git_watcher
    stop_watcher()
    if watcher and not watcher:is_closing() then
      watcher:close()
    end
  end
  git.start_watcher = function(cwd)
    local result = vim.system({ "git", "-C", cwd, "rev-parse", "--path-format=absolute", "--git-path", "HEAD" }, { text = true }):wait()
    -- Upstream stops handles without closing them, including when rearming.
    M.stop()
    if result.code == 0 then
      start_watcher(cwd, vim.trim(result.stdout))
    end
  end
  vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("custom_session_branch", { clear = true }),
    pattern = "global",
    callback = function()
      if not require("auto-session").restore_in_progress then
        M.start()
      end
    end,
  })
end

function M.stop()
  require("auto-session.git").stop_watcher()
end

function M.start()
  local config = require("auto-session.config")
  if config.enabled and config.git_use_branch_name and config.git_auto_restore_on_branch_change then
    require("auto-session.git").start_watcher(vim.fn.getcwd(-1, -1))
  else
    M.stop()
  end
end

return M
