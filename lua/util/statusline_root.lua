local M = {}
local cached

-- Keep filesystem traversal out of repeated redraws. Navigation still resolves
-- roots live; only the display label may lag external marker changes by 1s.
function M.get()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  local cwd = vim.fn.getcwd()
  local tab_cwd = vim.fn.getcwd(-1, 0)
  local global_cwd = vim.fn.getcwd(-1, -1)
  local now = vim.uv.hrtime()
  if
    cached
    and cached.buf == buf
    and cached.name == name
    and cached.cwd == cwd
    and cached.tab_cwd == tab_cwd
    and cached.global_cwd == global_cwd
    and now - cached.at < 1e9
  then
    return cached.value
  end

  cached = {
    buf = buf,
    name = name,
    cwd = cwd,
    tab_cwd = tab_cwd,
    global_cwd = global_cwd,
    at = now,
    value = require("util").get_root_basename(buf),
  }
  return cached.value
end

vim.api.nvim_create_autocmd({ "DirChanged", "BufFilePost", "BufWritePost", "LspAttach", "LspDetach", "FocusGained" }, {
  group = vim.api.nvim_create_augroup("custom_statusline_root", { clear = true }),
  callback = function()
    cached = nil
  end,
})

return M
