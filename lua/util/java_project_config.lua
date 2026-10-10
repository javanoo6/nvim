local M = {}

function M.update(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "intellij" })[1]
  if not client then
    local path = vim.api.nvim_buf_get_name(bufnr)
    client = require("intellij-lsp.client").find_ancestor_client(path ~= "" and path or vim.uv.cwd())
  end
  if not client then
    vim.notify("No IntelliJ workspace for this buffer", vim.log.levels.WARN, { title = "Java project config" })
    return
  end
  local root = client.config.root_dir
  local opts = require("util.java_intellij").project_options(root, require("intellij-lsp").config)
  client:request("intellij/reloadWorkspace", {
    initializationOptions = require("intellij-lsp.client").init_options(root, opts),
  }, function(err)
    vim.notify(
      err and ("Workspace reload failed: " .. err.message) or ("Workspace reloaded: " .. root),
      err and vim.log.levels.ERROR or vim.log.levels.INFO,
      { title = "Java project config" }
    )
  end, bufnr)
end

function M.register_commands()
  vim.api.nvim_create_user_command("JavaProjectUpdate", function()
    M.update()
  end, { desc = "Reload the current IntelliJ workspace" })
end

return M
