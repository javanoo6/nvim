local M = {}
local spring_boot_execute_client_command_patched = false
local jdtls_client_lookup_patched = false

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

local function apply_jdtls_client_lookup_patch()
  if jdtls_client_lookup_patched then
    return
  end

  local lsp_utils = require("java-core.utils.lsp")
  local err = require("java-core.utils.errors")

  lsp_utils.get_jdtls = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({
      bufnr = bufnr,
      name = "jdtls",
    })

    if #clients > 0 then
      return clients[1]
    end

    clients = vim.lsp.get_clients({ name = "jdtls" })
    if #clients == 0 then
      vim.print(debug.traceback())
      err.throw("No JDTLS client found")
    end

    return clients[1]
  end

  jdtls_client_lookup_patched = true
end

function M.apply_runtime_patches()
  apply_jdtls_client_lookup_patch()
  apply_spring_boot_execute_client_command_patch()
end

return M
