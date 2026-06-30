-- Auto-save for normal file buffers.
-- Formatting remains owned by conform.nvim's BufWritePre hook, which skips
-- formatting when LSP errors are present.

return {
  "okuuva/auto-save.nvim",
  version = "^1.0.0",
  cmd = "ASToggle",
  event = { "InsertLeave", "TextChanged" },
  notify_on_error_block = false,
  opts = {
    enabled = true, -- Start enabled, toggle with <leader>ua
    trigger_events = {
      immediate_save = { "BufLeave", "FocusLost" },
      defer_save = { "InsertLeave", "TextChanged" },
      cancel_deferred_save = { "InsertEnter" },
    },
    -- Condition: return true to allow save, false to block
    condition = function(buf)
      -- Don't auto-save special buffers
      if vim.fn.getbufvar(buf, "&modifiable") ~= 1 then
        return false
      end

      local buftype = vim.fn.getbufvar(buf, "&buftype")
      if buftype ~= "" then
        return false
      end

      return true
    end,
    write_all_buffers = false,
    noautocmd = false,
    lockmarks = false,
    debounce_delay = 1000,
    debug = false,
  },
  keys = {
    { "<leader>ua", "<cmd>ASToggle<cr>", desc = "Toggle auto-save" },
  },
  config = function(_, opts)
    require("auto-save").setup(opts)
    -- auto-save uses a normal :write, so conform.nvim's BufWritePre hook remains
    -- the single formatting path for both manual saves and auto-saves.
  end,
}
