-- Automatic session management
-- Saves and restores your editing session (open files, splits, cursor position, etc.)

local function scrub_invalid_local_options()
  local ok, auto_session = pcall(require, "auto-session")
  if not ok or type(auto_session.get_root_dir) ~= "function" then
    return
  end

  local session_files = vim.fn.globpath(auto_session.get_root_dir(), "*.vim", false, true)
  for _, session_file in ipairs(session_files) do
    local lines = vim.fn.readfile(session_file)
    local has_saved_winminheight = false
    local has_saved_winminwidth = false

    for _, line in ipairs(lines) do
      if line:match("^let s:save_winminheight = ") then
        has_saved_winminheight = true
      elseif line:match("^let s:save_winminwidth = ") then
        has_saved_winminwidth = true
      end
    end

    local changed = false
    local scrubbed = {}

    for _, line in ipairs(lines) do
      local orphaned_winminheight_restore = line:match("^let &winminheight = s:save_winminheight$") and not has_saved_winminheight
      local orphaned_winminwidth_restore = line:match("^let &winminwidth = s:save_winminwidth$") and not has_saved_winminwidth

      if line:match("^setlocal includeformatexpr=") or orphaned_winminheight_restore or orphaned_winminwidth_restore then
        changed = true
      else
        table.insert(scrubbed, line)
      end
    end

    if changed then
      vim.fn.writefile(scrubbed, session_file)
    end
  end
end

return {
  "rmagatti/auto-session",
  lazy = false, -- Must not be lazy loaded to handle the first file argument properly
  opts = {
    -- Enable auto-save and auto-restore
    auto_save = true,
    args_allow_files_auto_save = true,
    auto_restore = true,
    auto_restore_last_session = false, -- Don't restore last session automatically when starting nvim without args
    git_use_branch_name = true,
    git_auto_restore_on_branch_change = true,

    -- Suppress the "Session saved" message
    suppressed_dirs = { "~/", "~/Downloads", "/", "/tmp" },

    -- Don't auto-save session for certain directories
    -- args_allowlist = {}, -- allowlisted directories for auto-save
    -- args_ignorelist = {}, -- ignored directories for auto-save

    -- Session options (what gets saved)
    -- Similar to 'sessionoptions' in vim
    bypass_save_filetypes = { "alpha", "dashboard" }, -- Don't save session for these filetypes

    -- Git branch restores swap the buffer/session state; stop attached LSPs so
    -- restored buffers attach fresh clients for the branch contents.
    lsp_stop_on_restore = true,

    pre_restore_cmds = {
      scrub_invalid_local_options,
    },
    post_save_cmds = {
      scrub_invalid_local_options,
    },

    -- Logging
    log_level = "error",
  },
  keys = {
    -- Session management keymaps
    { "<leader>Ss", "<cmd>AutoSession save<cr>", desc = "Save session" },
    { "<leader>Sr", "<cmd>AutoSession restore<cr>", desc = "Restore session" },
    { "<leader>Sd", "<cmd>AutoSession delete<cr>", desc = "Delete session" },
    { "<leader>Sf", "<cmd>AutoSession search<cr>", desc = "Find sessions" },
    { "<leader>Sa", "<cmd>AutoSession enable<cr>", desc = "Enable auto-save" },
  },
}
