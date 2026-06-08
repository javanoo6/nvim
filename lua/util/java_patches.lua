local M = {}
local spring_boot_execute_client_command_patched = false

local function is_extract_variable_refactor(refactor_type)
  return refactor_type == "extractVariable" or refactor_type == "extractVariableAllOccurrence"
end

local function has_explicit_selection(params)
  return params
    and params.range
    and not (params.range.start.line == params.range["end"].line and params.range.start.character == params.range["end"].character)
end

local function normalize_rename_targets(params)
  if type(params) ~= "table" then
    return nil
  end

  if params.uri and params.offset and params.length then
    return { params }
  end

  if not vim.tbl_isempty(params) then
    return params
  end

  return nil
end

local function select_inferred_selection(selection_res, ui, List)
  local selection = selection_res[1]
  if #selection_res > 1 then
    selection = ui.select("Select expression to extract", selection_res, function(item)
      return item.name
    end, { prompt_single = true })
  end

  if not selection then
    return nil
  end

  local selections = List:new()
  if selection.params and vim.islist(selection.params) then
    local initialize_in = ui.select("Initialize the field in", selection.params)
    if not initialize_in then
      return nil
    end
    selections:push(initialize_in)
  end

  selections:push(selection)
  return selections, selection
end

local function infer_selection_or_fallback(self, refactor_type, params, orig_get_selections, ui, List)
  local selections = orig_get_selections(self, refactor_type, params)
  if selections and not vim.tbl_isempty(selections) then
    return selections
  end

  if not is_extract_variable_refactor(refactor_type) then
    return selections
  end

  local buffer = vim.api.nvim_get_current_buf()
  local selection_res = self.jdtls_client:java_infer_selection(refactor_type, params, buffer)
  if not selection_res or vim.tbl_isempty(selection_res) then
    return selections
  end

  local fallback = List:new()
  local selection = selection_res[1]

  if selection and selection.params and vim.islist(selection.params) then
    local initialize_in = ui.select("Initialize the field in", selection.params)
    if not initialize_in then
      return selections
    end
    fallback:push(initialize_in)
  end

  if selection then
    fallback:push(selection)
  end

  return fallback
end

local function apply_spring_boot_execute_client_command_patch()
  local handler = vim.lsp.handlers["workspace/executeClientCommand"]
  if type(handler) ~= "function" then
    return
  end

  if spring_boot_execute_client_command_patched then
    return
  end

  local wrapped = function(err, params, ctx, config)
    local client = ctx and ctx.client_id and vim.lsp.get_client_by_id(ctx.client_id) or nil
    if not client or client.name ~= "spring-boot" then
      return handler(err, params, ctx, config)
    end

    local ok, result = pcall(handler, err, params, ctx, config)
    if ok then
      return result
    end

    return {}
  end

  vim.lsp.handlers["workspace/executeClientCommand"] = wrapped
  spring_boot_execute_client_command_patched = true
end

function M.apply_refactor_patches(debug_log)
  local Action = require("java-refactor.action")
  local Refactor = require("java-refactor.refactor")
  local JdtlsClient = require("java-core.ls.clients.jdtls-client")
  local ui = require("java.ui.utils")
  local List = require("java-core.utils.list")

  local orig_rename = Action.rename
  local orig_choose_imports = Action.choose_imports
  local orig_get_selections = Refactor.get_selections
  local orig_java_infer_selection = JdtlsClient.java_infer_selection
  local orig_java_get_refactor_edit = JdtlsClient.java_get_refactor_edit
  local orig_perform_refactor_edit = Refactor.perform_refactor_edit
  local orig_run_lsp_client_command = Refactor.run_lsp_client_command

  Action.rename = function(self, params)
    -- nvim-java dispatches rename with dot-call syntax:
    --   action.rename(params)
    -- even though Action:rename is defined with colon syntax.
    -- In that broken call path, `self` is actually the rename target list and
    -- `params` is nil. Accept both shapes until upstream fixes the caller.
    local raw_params = params
    if raw_params == nil and type(self) == "table" and (self.uri or not vim.tbl_isempty(self)) then
      raw_params = self
    end

    local normalized = normalize_rename_targets(raw_params)
    if not normalized then
      vim.notify("Java refactor applied, but rename session did not start", vim.log.levels.INFO, {
        title = "nvim-java",
      })
      return
    end

    return orig_rename(self, normalized)
  end

  Action.choose_imports = function(self, selections)
    if type(selections) ~= "table" then
      vim.notify("Java import chooser received no candidates", vim.log.levels.WARN, {
        title = "nvim-java",
      })
      return {}
    end

    return orig_choose_imports(self, selections)
  end

  JdtlsClient.java_infer_selection = function(self, refactor_type, params, buffer)
    local result = orig_java_infer_selection(self, refactor_type, params, buffer)
    if is_extract_variable_refactor(refactor_type) then
      debug_log("inferSelection", {
        refactor_type = refactor_type,
        range = params and params.range or nil,
        result = result,
      })
    end
    return result
  end

  JdtlsClient.java_get_refactor_edit = function(self, command, action_params, formatting_options, selection_info, buffer)
    local result = orig_java_get_refactor_edit(self, command, action_params, formatting_options, selection_info, buffer)
    if is_extract_variable_refactor(command) then
      debug_log("getRefactorEdit", {
        command = command,
        range = action_params and action_params.range or nil,
        selection_info = selection_info,
        result = result,
      })
    end
    return result
  end

  Refactor.perform_refactor_edit = function(self, changes)
    debug_log("performRefactorEdit", {
      changes = changes,
      command = changes and changes.command or nil,
      command_arguments = changes and changes.command and changes.command.arguments or nil,
    })
    return orig_perform_refactor_edit(self, changes)
  end

  Refactor.run_lsp_client_command = function(self, command_name, arguments)
    debug_log("runLspClientCommand", {
      command_name = command_name,
      arguments = arguments,
    })
    return orig_run_lsp_client_command(self, command_name, arguments)
  end

  Refactor.get_selections = function(self, refactor_type, params)
    if is_extract_variable_refactor(refactor_type) and not has_explicit_selection(params) then
      local buffer = vim.api.nvim_get_current_buf()
      local selection_res = self.jdtls_client:java_infer_selection(refactor_type, params, buffer)
      if not selection_res or vim.tbl_isempty(selection_res) then
        return orig_get_selections(self, refactor_type, params)
      end

      local selections, selection = select_inferred_selection(selection_res, ui, List)
      if not selections then
        return List:new()
      end

      debug_log("chosenInferSelection", {
        refactor_type = refactor_type,
        chosen = selection,
        candidates = selection_res,
      })
      return selections
    end

    return infer_selection_or_fallback(self, refactor_type, params, orig_get_selections, ui, List)
  end

  apply_spring_boot_execute_client_command_patch()
end

return M
