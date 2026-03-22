-- ftplugin/java.lua — Java-specific config, loaded once per Java buffer

-- Reorders imports in the current buffer to match the project convention:
--   [others: lombok/org/spring/reactor]
--   blank line
--   [java/javax/jakarta]
--   blank line  (only when static imports exist)
--   [static]
--
-- Intended to run after JDTLS organizeImports (which handles unused removal).
local function fix_import_order()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local import_start, import_end
  for i, line in ipairs(lines) do
    if line:match("^import ") then
      if not import_start then import_start = i end
      import_end = i
    end
  end
  if not import_start then return end

  local static_imports, java_imports, other_imports = {}, {}, {}
  for i = import_start, import_end do
    local line = lines[i]
    if line:match("^import static ") then
      table.insert(static_imports, line)
    elseif line:match("^import java%.") or line:match("^import javax%.") or line:match("^import jakarta%.") then
      table.insert(java_imports, line)
    elseif line:match("^import ") then
      table.insert(other_imports, line)
    end
  end

  local new_lines = {}

  for _, l in ipairs(other_imports) do
    table.insert(new_lines, l)
  end
  if #java_imports > 0 then
    if #other_imports > 0 then table.insert(new_lines, "") end
    for _, l in ipairs(java_imports) do
      table.insert(new_lines, l)
    end
  end
  if #static_imports > 0 then
    if #other_imports > 0 or #java_imports > 0 then table.insert(new_lines, "") end
    for _, l in ipairs(static_imports) do
      table.insert(new_lines, l)
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, import_start - 1, import_end, false, new_lines)
end

-- Override <leader>ci for Java buffers: JDTLS removes unused imports,
-- then fix_import_order corrects the section ordering.
vim.keymap.set("n", "<leader>ci", function()
  vim.lsp.buf.code_action({
    context = { only = { "source.organizeImports" } },
    apply = true,
  })
  vim.defer_fn(fix_import_order, 500)
end, { buffer = true, desc = "Organize imports" })
