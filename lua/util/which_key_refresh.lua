local M = {}

function M.refresh_current_buffer()
  vim.schedule(function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok_buf, buf = pcall(require, "which-key.buf")
    local ok_triggers, triggers = pcall(require, "which-key.triggers")
    if not ok_buf then
      return
    end

    if ok_triggers then
      triggers.suspended = {}
    end

    pcall(buf.clear, { buf = bufnr })
    pcall(buf.get, { buf = bufnr, mode = "n", update = true })
    pcall(buf.get, { buf = bufnr, mode = "x", update = true })
  end)
end

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("custom_which_key_refresh", { clear = true }),
    pattern = "DiffviewViewClosed",
    desc = "Rebuild which-key triggers after Diffview closes",
    callback = function()
      M.refresh_current_buffer()
    end,
  })

  vim.api.nvim_create_user_command("WhichKeyRefresh", M.refresh_current_buffer, {
    desc = "Rebuild which-key triggers for the current buffer",
  })
end

return M
