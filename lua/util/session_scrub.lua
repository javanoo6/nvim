local M = {}

-- Restore hook names are display labels, so inspect the exact SourcePre path
-- instead. Only files directly inside auto-session's configured root qualify.
function M.scrub(path)
  local auto_session = package.loaded["auto-session"]
  if not auto_session or not path or path == "" or not path:match("%.vim$") then
    return
  end

  path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  local root = vim.fs.normalize(vim.fn.fnamemodify(auto_session.get_root_dir(), ":p"))
  if vim.fs.dirname(path) ~= root or vim.fn.filereadable(path) == 0 then
    return
  end

  local lines = vim.fn.readfile(path)
  local has_saved_winminheight = false
  local has_saved_winminwidth = false
  for _, line in ipairs(lines) do
    if line:match("^let s:save_winminheight = ") then
      has_saved_winminheight = true
    elseif line:match("^let s:save_winminwidth = ") then
      has_saved_winminwidth = true
    end
  end

  local scrubbed = {}
  for _, line in ipairs(lines) do
    local orphaned_height = line:match("^let &winminheight = s:save_winminheight$") and not has_saved_winminheight
    local orphaned_width = line:match("^let &winminwidth = s:save_winminwidth$") and not has_saved_winminwidth
    if not (line:match("^setlocal includeformatexpr=") or orphaned_height or orphaned_width) then
      scrubbed[#scrubbed + 1] = line
    end
  end

  if #scrubbed ~= #lines then
    if vim.fn.writefile(scrubbed, path) ~= 0 then
      error("Failed to sanitize session: " .. path)
    end
  end
end

function M.post_save()
  M.scrub(vim.v.this_session)
end

function M.setup()
  vim.api.nvim_create_autocmd("SourcePre", {
    group = vim.api.nvim_create_augroup("custom_session_scrub", { clear = true }),
    pattern = "*.vim",
    callback = function(event)
      M.scrub(event.file)
    end,
  })
end

return M
