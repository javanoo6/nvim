local M = {}

local function current_position()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  return row - 1, col
end

local function command_exists(name)
  return vim.fn.exists(":" .. name) == 2
end

local function append(lines, label, value)
  lines[#lines + 1] = string.format("%-24s %s", label .. ":", value)
end

local function inspect_position(lines, bufnr, row, col)
  local ok, result = pcall(vim.inspect_pos, bufnr, row, col)
  if not ok or type(result) ~= "table" then
    append(lines, "inspect_pos", "<unavailable>")
    return
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "Highlight stack:"
  for _, item in ipairs(result.semantic_tokens or {}) do
    lines[#lines + 1] = "  semantic: " .. vim.inspect(item)
  end
  for _, item in ipairs(result.treesitter or {}) do
    lines[#lines + 1] = "  treesitter: " .. vim.inspect(item)
  end
  for _, item in ipairs(result.syntax or {}) do
    lines[#lines + 1] = "  syntax: " .. vim.inspect(item)
  end
  for _, item in ipairs(result.extmarks or {}) do
    lines[#lines + 1] = "  extmark: " .. vim.inspect(item)
  end
end

local function inspect_treesitter(lines, bufnr, row, col)
  local parser_ok = pcall(vim.treesitter.get_parser, bufnr)
  append(lines, "treesitter parser", parser_ok and "attached" or "missing")

  local captures_ok, captures = pcall(vim.treesitter.get_captures_at_pos, bufnr, row, col)
  if captures_ok and type(captures) == "table" and not vim.tbl_isempty(captures) then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Treesitter captures:"
    for _, capture in ipairs(captures) do
      lines[#lines + 1] = "  " .. vim.inspect(capture)
    end
  else
    append(lines, "treesitter captures", "<none>")
  end
end

local function open_report(lines)
  vim.cmd("botright new")
  local bufnr = vim.api.nvim_get_current_buf()
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "markdown"
  vim.api.nvim_buf_set_name(bufnr, "UiInspect")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
end

function M.inspect()
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = current_position()
  local lines = {
    "# UI Inspect",
    "",
  }

  append(lines, "buffer", tostring(bufnr))
  append(lines, "filetype", vim.bo[bufnr].filetype ~= "" and vim.bo[bufnr].filetype or "<none>")
  append(lines, "position", string.format("%d:%d", row + 1, col + 1))
  append(lines, "colorscheme", vim.g.colors_name or "<none>")
  append(lines, "diagnostics enabled", tostring(vim.diagnostic.is_enabled({ bufnr = bufnr })))
  append(lines, "conceallevel", tostring(vim.wo.conceallevel))
  append(lines, "spell", tostring(vim.wo.spell))
  append(lines, "wrap", tostring(vim.wo.wrap))
  append(lines, ":Inspect", command_exists("Inspect") and "available" or "missing")
  append(lines, ":Noice", command_exists("Noice") and "available" or "missing")

  inspect_treesitter(lines, bufnr, row, col)
  inspect_position(lines, bufnr, row, col)

  lines[#lines + 1] = ""
  lines[#lines + 1] = "Related commands:"
  lines[#lines + 1] = "  :Inspect"
  lines[#lines + 1] = "  :InspectTree"
  lines[#lines + 1] = "  :TSCaptureUnderCursor"
  lines[#lines + 1] = "  :Noice"
  lines[#lines + 1] = "  :UiToggleTreesitter"
  lines[#lines + 1] = "  :UiToggleIlluminate"

  open_report(lines)
end

function M.toggle_treesitter(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.b[bufnr].treesitter_disabled = not vim.b[bufnr].treesitter_disabled

  if vim.b[bufnr].treesitter_disabled then
    pcall(vim.treesitter.stop, bufnr)
    vim.notify("treesitter disabled for buffer")
    return
  end

  local ok, err = pcall(vim.treesitter.start, bufnr)
  if not ok then
    vim.notify("treesitter start failed: " .. tostring(err), vim.log.levels.WARN)
    return
  end
  vim.notify("treesitter enabled for buffer")
end

function M.toggle_illuminate(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.b[bufnr].illuminate_disabled = not vim.b[bufnr].illuminate_disabled

  local ok, illuminate = pcall(require, "illuminate")
  if not ok then
    vim.notify("vim-illuminate is unavailable", vim.log.levels.WARN)
    return
  end

  if vim.b[bufnr].illuminate_disabled then
    if illuminate.pause_buf then
      illuminate.pause_buf()
    end
    vim.notify("reference highlighting disabled for buffer")
    return
  end

  if illuminate.resume_buf then
    illuminate.resume_buf()
  end
  vim.notify("reference highlighting enabled for buffer")
end

function M.register_commands()
  vim.api.nvim_create_user_command("UiInspect", M.inspect, {
    desc = "Open highlight and UI inspection report",
  })
  vim.api.nvim_create_user_command("UiToggleTreesitter", function()
    M.toggle_treesitter()
  end, {
    desc = "Toggle Treesitter highlighting for current buffer",
  })
  vim.api.nvim_create_user_command("UiToggleIlluminate", function()
    M.toggle_illuminate()
  end, {
    desc = "Toggle reference highlighting for current buffer",
  })
end

return M
