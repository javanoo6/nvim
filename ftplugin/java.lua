-- ftplugin/java.lua
-- Starts jdtls when opening Java files

local ok, jdtls = pcall(require, "jdtls")
if not ok then
  vim.notify("nvim-jdtls not found, skipping Java LSP setup", vim.log.levels.WARN)
  return
end

local java = require("lang.java")

local function on_attach(client, bufnr)
  java.keymaps.setup(bufnr, jdtls)

  -- Suppress reloadBundles command error
  client.handlers["workspace/executeCommand"] = function(err, result, ctx)
    if ctx.params.command == "_java.reloadBundles.command" then
      return
    end
    return vim.lsp.handlers["workspace/executeCommand"](err, result, ctx)
  end

  -- Setup DAP
  java.dap.setup_dap()
end

local config = {
  cmd = java.core.get_cmd(),
  root_dir = java.core.get_root_dir(),
  settings = java.core.get_settings(),
  flags = {
    allow_incremental_sync = true,
    debounce_text_changes = 150,
  },
  capabilities = java.core.get_capabilities(),
  init_options = {
    bundles = java.dap.get_bundles(),
    extendedClientCapabilities = java.core.get_extended_capabilities(),
  },
  on_attach = on_attach,
}

jdtls.start_or_attach(config)
