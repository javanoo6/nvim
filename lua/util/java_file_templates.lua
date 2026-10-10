local M = {}
local pending = {}

local function key(path)
  return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

function M.on_file_added(path)
  if type(path) ~= "string" or not path:match("%.java$") then
    return
  end
  local stat = vim.uv.fs_stat(path)
  if stat and stat.type == "file" and stat.size == 0 then
    pending[key(path)] = true
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("java_neotree_file_templates", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "LspAttach" }, {
    group = group,
    desc = "Offer IntelliJ templates when opening new empty Neo-tree Java files",
    callback = function(event)
      local bufnr = event.buf
      local path = key(vim.api.nvim_buf_get_name(bufnr))
      if not pending[path] then
        return
      end
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_get_current_buf() ~= bufnr or not pending[path] then
          return
        end
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        if #lines > 1 or (lines[1] or "") ~= "" then
          pending[path] = nil
          return
        end
        local cfg = require("intellij-lsp").config
        if cfg.file_templates == false then
          pending[path] = nil
          return
        end
        local client = vim.lsp.get_clients({ bufnr = bufnr, name = "intellij" })[1]
        if not client or not client.initialized then
          return
        end
        -- Consume before prompting: cancellation and reattachment must not reopen it.
        pending[path] = nil
        require("intellij-lsp.templates").prompt(client, bufnr, cfg)
      end)
    end,
  })
end

return M
