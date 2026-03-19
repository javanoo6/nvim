-- Automatic session management
-- Saves and restores your editing session (open files, splits, cursor position, etc.)

return {
  "rmagatti/auto-session",
  lazy = false, -- Must not be lazy loaded to handle the first file argument properly
  opts = {
    -- Enable auto-save and auto-restore
    auto_save = true,
    auto_restore = true,
    auto_restore_last_session = false, -- Don't restore last session automatically when starting nvim without args
    
    -- Suppress the "Session saved" message
    suppressed_dirs = { "~/", "~/Downloads", "/", "/tmp" },
    
    -- Don't auto-save session for certain directories
    -- args_allowlist = {}, -- allowlisted directories for auto-save
    -- args_ignorelist = {}, -- ignored directories for auto-save
    
    -- Session options (what gets saved)
    -- Similar to 'sessionoptions' in vim
    bypass_save_filetypes = { "alpha", "dashboard" }, -- Don't save session for these filetypes
    
    -- Hooks for custom behavior
    pre_save = nil, -- function to run before saving session
    post_save = nil, -- function to run after saving session
    pre_restore = nil, -- function to run before restoring session
    post_restore = nil, -- function to run after restoring session
    
    -- Logging
    log_level = "error",
  },
  keys = {
    -- Session management keymaps
    { "<leader>Ss", "<cmd>SessionSave<cr>", desc = "Save session" },
    { "<leader>Sr", "<cmd>SessionRestore<cr>", desc = "Restore session" },
    { "<leader>Sd", "<cmd>SessionDelete<cr>", desc = "Delete session" },
    { "<leader>Sf", "<cmd>AutoSession search<cr>", desc = "Find sessions" },
    { "<leader>Sa", "<cmd>AutoSession toggle<cr>", desc = "Toggle auto-save" },
  },
}
