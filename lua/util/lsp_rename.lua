local M = {}
local method = "textDocument/rename"
local installed = setmetatable({}, { __mode = "k" })

-- Native rename selects the client handler before falling back to the global
-- handler. Wrap once per client, including its existing custom edit handling.
function M.attach(client)
  if not client or (installed[client] and installed[client] == client.handlers[method]) then
    return
  end

  local original = client.handlers[method]
  local function handler(err, result, ctx, config)
    local delegate = original or vim.lsp.handlers[method]
    local values = vim.F.pack_len(delegate(err, result, ctx, config))
    if not err and result then
      vim.schedule(function()
        require("util.inlay_hints").refresh_loaded_buffers()
      end)
    end
    return vim.F.unpack_len(values)
  end
  client.handlers[method] = handler
  installed[client] = handler
end

function M.rename()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.lsp.buf.rename(nil, {
    bufnr = bufnr,
    name = vim.bo[bufnr].filetype == "java" and "intellij" or nil,
  })
end

return M
