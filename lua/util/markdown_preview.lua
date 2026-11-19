local M = {}

local function render_state(win)
  local ok, state = pcall(vim.api.nvim_win_get_var, win, "md_render_state")
  if
    ok
    and type(state) == "table"
    and state.mode == "render"
    and vim.api.nvim_win_get_buf(win) == state.render_buf
    and vim.api.nvim_buf_is_valid(state.source_buf)
  then
    return state
  end
end

function M.toggle_split()
  local current = vim.api.nvim_get_current_win()
  local state = render_state(current)
  local source = state and state.source_buf or vim.api.nvim_get_current_buf()
  local source_win, previews = nil, {}
  -- Use upstream's window state rather than names or cached handles: this also
  -- finds splits created before this helper loaded, and ignores stale state.
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      if vim.api.nvim_win_get_buf(win) == source then
        source_win = source_win or win
      end
      local preview = render_state(win)
      if preview and preview.source_buf == source then
        previews[#previews + 1] = win
      end
    end
  end
  if #previews == 0 then
    vim.cmd("vert MdRender split")
    return
  end
  if not source_win then
    -- The source may have been closed, or <leader>mt used first. Restore it
    -- through upstream so its window options and cursor are restored too.
    source_win = state and current or previews[1]
    vim.api.nvim_set_current_win(source_win)
    require("md-render").preview.toggle()
  end
  vim.api.nvim_set_current_win(source_win)
  for _, win in ipairs(previews) do
    if win ~= source_win then
      vim.api.nvim_win_close(win, false)
    end
  end
end

return M
