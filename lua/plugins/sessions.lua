-- Automatic session management
-- Saves and restores your editing session (open files, splits, cursor position, etc.)

return {
  "rmagatti/auto-session",
  lazy = false, -- Must not be lazy loaded to handle the first file argument properly
  config = function(_, opts)
    -- Install before setup so startup restores also sanitize their exact path.
    require("util.session_scrub").setup()
    require("util.session_branch").setup()
    local preferences = require("util.preferences")
    opts.auto_save = preferences.get("session_autosave")
    opts.auto_restore = preferences.get("session_autorestore")
    local session = require("auto-session")
    session.setup(opts)
  end,
  opts = {
    -- Runtime auto-save/restore preferences are supplied during setup.
    args_allow_files_auto_save = true,
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

    save_extra_data = function()
      return require("util.bufferline").save_session()
    end,
    restore_extra_data = function(_, data)
      require("util.bufferline").load_session(data)
    end,
    pre_restore_cmds = {
      function()
        require("util.bufferline").before_restore()
      end,
    },
    post_restore_cmds = {
      function()
        require("util.bufferline").after_restore()
      end,
    },
    no_restore_cmds = {
      function(is_startup)
        if is_startup then
          require("util.session_branch").start()
        end
      end,
    },

    post_save_cmds = {
      function()
        require("util.session_scrub").post_save()
      end,
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
    {
      "<leader>Sa",
      function()
        require("util.preferences").set("session_autosave", true)
      end,
      desc = "Enable session auto-save",
    },
  },
}
