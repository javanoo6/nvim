local M = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Java project config" })
end

function M.update(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or (bufnr or vim.api.nvim_get_current_buf())

  local client = vim.lsp.get_clients({
    bufnr = bufnr,
    name = "jdtls",
    method = "workspace/executeCommand",
  })[1]

  if not client then
    notify("No JDTLS client attached to current buffer", vim.log.levels.WARN)
    return
  end

  notify("Requested JDTLS project configuration update")
  client:request("workspace/executeCommand", {
    command = "java.projectConfiguration.update",
  }, function(err)
    if err then
      local message = err.message or tostring(err)
      notify("Project configuration update failed: " .. message, vim.log.levels.ERROR)
      return
    end

    notify("JDTLS project configuration update finished")
  end, bufnr)
end

function M.register_commands()
  vim.api.nvim_create_user_command("JavaProjectUpdate", function()
    M.update(0)
  end, {
    desc = "Ask JDTLS to update Java project configuration",
  })
end

return M
