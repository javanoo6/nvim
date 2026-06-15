local M = {}

local function action_title(action)
  return type(action.title) == "string" and action.title or ""
end

local function import_symbol(action)
  return action_title(action):match("^Import '([^']+)' %(")
end

local function is_import_action(action)
  return import_symbol(action) ~= nil
end

local function apply_action(action, client, ctx)
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  end

  local action_command = action.command
  if action_command then
    local command = type(action_command) == "table" and action_command or action
    client:exec_cmd(command, ctx)
  end
end

local function resolve_and_apply(action, client, ctx, bufnr)
  if type(action.title) == "string" and type(action.command) == "string" then
    apply_action(action, client, ctx)
    return
  end

  if action.disabled then
    vim.notify(action.disabled.reason or "Java import action is disabled", vim.log.levels.ERROR, { title = "Java import" })
    return
  end

  if not (action.edit and action.command) and client:supports_method("codeAction/resolve") then
    client:request("codeAction/resolve", action, function(err, resolved_action)
      if err then
        if action.edit or action.command then
          apply_action(action, client, ctx)
        else
          vim.notify(err.message or tostring(err), vim.log.levels.ERROR, { title = "Java import" })
        end
        return
      end

      apply_action(resolved_action, client, ctx)
    end, bufnr)
    return
  end

  apply_action(action, client, ctx)
end

local function java_buffer_ready(bufnr)
  if vim.bo[bufnr].filetype ~= "java" then
    vim.notify("Java smart import only runs in Java buffers", vim.log.levels.INFO, { title = "Java import" })
    return false
  end

  if #vim.lsp.get_clients({ bufnr = bufnr, name = "jdtls", method = "textDocument/codeAction" }) == 0 then
    vim.notify("JDTLS code actions are not available", vim.log.levels.WARN, { title = "Java import" })
    return false
  end

  return true
end

local function lsp_diagnostic(diagnostic)
  return diagnostic.user_data and diagnostic.user_data.lsp
end

local function diagnostic_key(diagnostic)
  return table.concat({
    diagnostic.lnum or 0,
    diagnostic.col or 0,
    diagnostic.end_lnum or diagnostic.lnum or 0,
    diagnostic.end_col or diagnostic.col or 0,
    diagnostic.message or "",
  }, ":")
end

local function diagnostic_matches_cursor_symbol(diagnostic, line, col, symbol)
  if diagnostic.message and diagnostic.message:find(symbol, 1, true) then
    return true
  end

  local start_line = diagnostic.lnum or 0
  local end_line = diagnostic.end_lnum or start_line
  local start_col = diagnostic.col or 0
  local end_col = diagnostic.end_col or start_col

  if line < start_line or line > end_line then
    return false
  end

  if line == start_line and col < start_col then
    return false
  end

  if line == end_line and col > end_col then
    return false
  end

  return true
end

local function params_for_diagnostic(bufnr, client, diagnostic)
  local lsp_diag = lsp_diagnostic(diagnostic)
  local range = lsp_diag and lsp_diag.range

  local params
  if range then
    params = {
      textDocument = vim.lsp.util.make_text_document_params(bufnr),
      range = range,
    }
  else
    local start_pos = { (diagnostic.lnum or 0) + 1, diagnostic.col or 0 }
    local end_pos = { (diagnostic.end_lnum or diagnostic.lnum or 0) + 1, diagnostic.end_col or diagnostic.col or 0 }
    params = vim.lsp.util.make_given_range_params(start_pos, end_pos, bufnr, client.offset_encoding)
  end

  params.context = {
    only = { "quickfix" },
    diagnostics = lsp_diag and { lsp_diag } or {},
    triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
  }

  return params
end

local function request_import_actions(bufnr, diagnostic, callback)
  vim.lsp.buf_request_all(bufnr, "textDocument/codeAction", function(client)
    return params_for_diagnostic(bufnr, client, diagnostic)
  end, function(results)
    local actions = {}

    for _, result in pairs(results) do
      local client = vim.lsp.get_client_by_id(result.context.client_id)
      if client and client.name == "jdtls" then
        for _, action in ipairs(result.result or {}) do
          if is_import_action(action) then
            actions[#actions + 1] = {
              action = action,
              client = client,
              ctx = result.context,
            }
          end
        end
      end
    end

    callback(actions)
  end)
end

local function dedupe_actions(actions)
  local seen = {}
  local deduped = {}

  for _, item in ipairs(actions) do
    local key = action_title(item.action)
    if not seen[key] then
      seen[key] = true
      deduped[#deduped + 1] = item
    end
  end

  return deduped
end

local function select_import(actions, callback)
  vim.ui.select(actions, {
    prompt = "Select Java import:",
    format_item = function(item)
      return action_title(item.action)
    end,
  }, callback)
end

local function apply_or_select(actions, bufnr, on_applied, on_skipped)
  actions = dedupe_actions(actions)

  if #actions == 0 then
    on_skipped()
    return
  end

  if #actions == 1 then
    local item = actions[1]
    resolve_and_apply(item.action, item.client, item.ctx, bufnr)
    on_applied(false)
    return
  end

  select_import(actions, function(item)
    if not item then
      on_skipped()
      return
    end

    resolve_and_apply(item.action, item.client, item.ctx, bufnr)
    on_applied(true)
  end)
end

function M.import_class_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  if not java_buffer_ready(bufnr) then
    return
  end

  local symbol = vim.fn.expand("<cword>")
  if symbol == "" then
    vim.notify("No Java symbol under cursor", vim.log.levels.INFO, { title = "Java import" })
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local col = cursor[2]
  local diagnostics = vim.tbl_filter(function(diagnostic)
    return lsp_diagnostic(diagnostic) ~= nil
  end, vim.diagnostic.get(bufnr, { lnum = line }))

  local diagnostic = vim.iter(diagnostics):find(function(item)
    return diagnostic_matches_cursor_symbol(item, line, col, symbol)
  end) or diagnostics[1]
  if not diagnostic then
    diagnostic = {
      lnum = line,
      col = col,
      end_lnum = line,
      end_col = col + #symbol,
      message = symbol,
    }
  end

  request_import_actions(bufnr, diagnostic, function(actions)
    actions = vim.tbl_filter(function(item)
      return import_symbol(item.action) == symbol
    end, actions)

    apply_or_select(actions, bufnr, function()
      return nil
    end, function()
      vim.notify("No import quickfix for " .. symbol, vim.log.levels.INFO, { title = "Java import" })
    end)
  end)
end

function M.import_unambiguous_classes()
  local bufnr = vim.api.nvim_get_current_buf()
  if not java_buffer_ready(bufnr) then
    return
  end

  local skipped = {}
  local auto_applied = 0
  local selected = 0

  local function next_diagnostic()
    for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
      local key = diagnostic_key(diagnostic)
      if not skipped[key] and lsp_diagnostic(diagnostic) then
        return diagnostic, key
      end
    end
  end

  local function finish()
    local parts = {}

    if auto_applied > 0 then
      parts[#parts + 1] = tostring(auto_applied) .. " automatic"
    end

    if selected > 0 then
      parts[#parts + 1] = tostring(selected) .. " selected"
    end

    if #parts == 0 then
      vim.notify("No Java import quickfixes found", vim.log.levels.INFO, { title = "Java import" })
    else
      vim.notify("Applied Java imports: " .. table.concat(parts, ", "), vim.log.levels.INFO, { title = "Java import" })
    end
  end

  local step
  step = function()
    local diagnostic, key = next_diagnostic()
    if not diagnostic then
      finish()
      return
    end

    request_import_actions(bufnr, diagnostic, function(actions)
      if #actions == 0 then
        skipped[key] = true
        step()
        return
      end

      apply_or_select(actions, bufnr, function(was_selected)
        skipped[key] = true

        if was_selected then
          selected = selected + 1
        else
          auto_applied = auto_applied + 1
        end

        vim.defer_fn(step, 150)
      end, function()
        skipped[key] = true
        step()
      end)
    end)
  end

  step()
end

return M
