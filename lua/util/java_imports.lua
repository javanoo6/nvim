local M = {}

local function client()
  local c = vim.lsp.get_clients({ bufnr = 0, name = "intellij" })[1]
  if not c or not require("intellij-lsp.progress").is_ready(c.id) then
    vim.notify("IntelliJ Java workspace is not ready; see :JavaInfo", vim.log.levels.WARN)
    return nil
  end
  return c
end

local function diagnostics(c, bufnr, callback)
  c:request("textDocument/diagnostic", { textDocument = { uri = vim.uri_from_bufnr(bufnr) } }, function(err, result)
    if err then
      vim.notify("Java import diagnostics failed: " .. vim.inspect(err), vim.log.levels.ERROR)
      return
    end
    callback(result and result.items or {})
  end, bufnr)
end

local function import_fix(diagnostic)
  for _, fix in ipairs(diagnostic.data and diagnostic.data.fixes or {}) do
    if fix.name == "Import class" and fix.modCommandData then
      return fix
    end
  end
end

local function apply(c, bufnr, fix)
  c:exec_cmd({ command = "applyModCommand", arguments = { fix.modCommandData } }, { bufnr = bufnr })
end

function M.import_class_at_cursor()
  local c = client()
  if not c then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = vim.lsp.util.character_offset(bufnr, row, cursor[2], c.offset_encoding)
  diagnostics(c, bufnr, function(items)
    for _, diagnostic in ipairs(items) do
      local range = diagnostic.range
      local fix = import_fix(diagnostic)
      if
        fix
        and range.start.line <= row
        and range["end"].line >= row
        and (row ~= range.start.line or col >= range.start.character)
        and (row ~= range["end"].line or col <= range["end"].character)
      then
        apply(c, bufnr, fix)
        return
      end
    end
    vim.notify("No IntelliJ import fix at the cursor", vim.log.levels.INFO)
  end)
end

function M.import_unambiguous_classes()
  local c = client()
  if not c then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local seen = {}
  local step
  step = function()
    if not vim.api.nvim_buf_is_loaded(bufnr) or c:is_stopped() then
      return
    end
    diagnostics(c, bufnr, function(items)
      for _, diagnostic in ipairs(items) do
        local fix = import_fix(diagnostic)
        -- A pull immediately after an edit can still contain the prior diagnostics.
        local symbol = diagnostic.message:match("Cannot resolve symbol '([^']+)'")
        if symbol then
          for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
            if line:match("^%s*import%s+.-%." .. vim.pesc(symbol) .. "%s*;") then
              seen[diagnostic.message] = true
              break
            end
          end
        end
        if fix and not seen[diagnostic.message] then
          seen[diagnostic.message] = true
          local tick = vim.b[bufnr].changedtick
          apply(c, bufnr, fix)
          local started = vim.uv.hrtime()
          local function next_import()
            if not vim.api.nvim_buf_is_loaded(bufnr) then
              return
            end
            if vim.b[bufnr].changedtick ~= tick then
              vim.defer_fn(step, 300)
              return
            end
            if vim.uv.hrtime() - started > 10000000000 then
              vim.notify("Bulk imports paused: finish or cancel the IntelliJ picker, then retry", vim.log.levels.INFO)
              return
            end
            vim.defer_fn(next_import, 100)
          end
          vim.defer_fn(next_import, 100)
          return
        end
      end
      vim.notify("Java import pass complete", vim.log.levels.INFO)
    end)
  end
  vim.defer_fn(step, 300)
end

return M
