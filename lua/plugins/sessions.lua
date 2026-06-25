-- Automatic session management
-- Saves and restores your editing session (open files, splits, cursor position, etc.)

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

    -- Logging
    log_level = "error",
  },
  keys = {
    -- Session management keymaps
    { "<leader>Ss", "<cmd>AutoSession save<cr>", desc = "Save session" },
    { "<leader>Sr", "<cmd>AutoSession restore<cr>", desc = "Restore session" },
    { "<leader>Sd", "<cmd>SessionDelete<cr>", desc = "Delete session" },
    { "<leader>Sf", "<cmd>AutoSession search<cr>", desc = "Find sessions" },
    { "<leader>Sa", "<cmd>AutoSession enable<cr>", desc = "Enable auto-save" },
  },
}
