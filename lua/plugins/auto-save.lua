-- Auto-save with LSP diagnostics check
-- Only saves if there are no LSP errors for the current buffer

return {
  "okuuva/auto-save.nvim",
  version = "^1.0.0",
  cmd = "ASToggle",
  event = { "InsertLeave", "TextChanged" },
  opts = {
    enabled = false, -- Start disabled, toggle with <leader>ua
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

      -- Check LSP diagnostics for errors
      local diagnostics = vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR })
      if #diagnostics > 0 then
        -- Throttle notification
        local last_notify = vim.b[buf].last_autosave_notify or 0
        local now = vim.loop.now()
        if (now - last_notify) > 5000 then -- Max once per 5 seconds
          vim.notify(
            "Auto-save blocked: " .. #diagnostics .. " LSP error(s)",
            vim.log.levels.WARN,
            { title = "Auto-save" }
          )
          vim.b[buf].last_autosave_notify = now
        end
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

    -- Auto-format after auto-save
    local group = vim.api.nvim_create_augroup("AutoSaveFormat", {})
    vim.api.nvim_create_autocmd("User", {
      pattern = "AutoSaveWritePost",
      group = group,
      callback = function(args)
        if args.data.saved_buffer then
          local buf = args.data.saved_buffer
          local has_lsp = #vim.lsp.get_active_clients({ bufnr = buf }) > 0
          if has_lsp then
            vim.lsp.buf.format({
              bufnr = buf,
              async = false,
              timeout_ms = 2000,
            })
          end
        end
      end,
    })
  end,
}
