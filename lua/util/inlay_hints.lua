local M = {}

local namespace = vim.api.nvim_create_namespace("nvim.lsp.inlayhint")
local edit_clear_group = vim.api.nvim_create_augroup("custom_inlay_hint_edit_clear", { clear = true })
local edit_clear_filetypes = {
  go = true,
  java = true,
  python = true,
}
local insert_disabled_buffers = {}

local function each_loaded_buffer(callback)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      callback(bufnr)
    end
  end
end

local function set_enabled(bufnr, enabled)
  vim.lsp.inlay_hint.enable(enabled, { bufnr = bufnr })
end

local function buffer_supports_inlay_hints(bufnr)
  return #vim.lsp.get_clients({
    bufnr = bufnr,
    method = "textDocument/inlayHint",
  }) > 0
end

function M.clear_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  vim.api.nvim__redraw({ buf = bufnr, valid = true, flush = false })
end

function M.refresh_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_loaded(bufnr) or not M.is_enabled() or not buffer_supports_inlay_hints(bufnr) then
    return
  end

  M.clear_buffer(bufnr)
  set_enabled(bufnr, false)
  vim.schedule(function()
    if vim.api.nvim_buf_is_loaded(bufnr) and M.is_enabled() then
      set_enabled(bufnr, true)
    end
  end)
end

function M.is_enabled()
  return vim.g.inlay_hints_enabled ~= false
end

function M.set_enabled(enabled, opts)
  opts = opts or {}
  vim.g.inlay_hints_enabled = enabled

  if opts.notify ~= false then
    vim.notify("Inlay hints: " .. (enabled and "on" or "off"))
  end

  each_loaded_buffer(function(bufnr)
    set_enabled(bufnr, enabled)
  end)
end

function M.apply_for_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  set_enabled(bufnr, M.is_enabled())
end

function M.toggle()
  M.set_enabled(not M.is_enabled())
end

function M.setup()
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = edit_clear_group,
    desc = "Hide inlay hints while editing allowlisted filetypes",
    callback = function(event)
      if not M.is_enabled() or not edit_clear_filetypes[vim.bo[event.buf].filetype] or not buffer_supports_inlay_hints(event.buf) then
        return
      end

      insert_disabled_buffers[event.buf] = true
      set_enabled(event.buf, false)
    end,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = edit_clear_group,
    desc = "Restore inlay hints after editing allowlisted filetypes",
    callback = function(event)
      if not insert_disabled_buffers[event.buf] then
        return
      end

      insert_disabled_buffers[event.buf] = nil
      if vim.api.nvim_buf_is_loaded(event.buf) and M.is_enabled() then
        set_enabled(event.buf, true)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
    group = edit_clear_group,
    desc = "Clear stale inlay hints immediately after edits",
    callback = function(event)
      if M.is_enabled() and edit_clear_filetypes[vim.bo[event.buf].filetype] and buffer_supports_inlay_hints(event.buf) then
        M.clear_buffer(event.buf)
      end
    end,
  })

  vim.api.nvim_create_user_command("InlayHintsRefresh", function()
    M.refresh_buffer(0)
  end, { desc = "Clear and re-request LSP inlay hints for the current buffer", force = true })
end

vim.g.inlay_hints_enabled = vim.g.inlay_hints_enabled ~= false

return M
