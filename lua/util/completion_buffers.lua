local M = {}

-- Bound cmp-buffer indexing to the current editing context, even after a large
-- session restore. Hidden files and plugin panels should not become indexes.
function M.get()
  local buffers, seen = {}, {}
  local remaining = 1024 * 1024
  local function add(buf)
    if seen[buf] then
      return
    end
    seen[buf] = true
    if not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].buftype ~= "" then
      return
    end
    local size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
    if size >= 0 and size <= 512 * 1024 and size <= remaining then
      buffers[#buffers + 1] = buf
      remaining = remaining - size
    end
  end

  add(vim.api.nvim_get_current_buf())
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    add(vim.api.nvim_win_get_buf(win))
  end
  return buffers
end

return M
