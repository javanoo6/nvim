local M = {}

function M.close_lazygit()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    if vim.bo[bufnr].filetype == "lazygit" then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "lazygit" then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end

  LAZYGIT_BUFFER = nil
  LAZYGIT_LOADED = false
  vim.g.lazygit_opened = 0
end

return M
