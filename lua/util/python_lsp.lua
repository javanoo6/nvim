local M = {}

local servers = { "pyright", "basedpyright" }
local selected = "pyright"
local generation = 0

function M.select(server)
  assert(vim.tbl_contains(servers, server), "Unsupported Python LSP: " .. tostring(server))
  generation = generation + 1
  selected = server
  for _, name in ipairs(servers) do
    if name ~= selected then
      vim.lsp.enable(name, false)
    end
  end
  vim.lsp.enable(selected)
end

function M.restart()
  generation = generation + 1
  local current_generation = generation
  vim.lsp.enable(servers, false)
  -- A venv switch must not reuse a client launched with the old interpreter.
  for _, client in ipairs(vim.lsp.get_clients()) do
    if vim.tbl_contains(servers, client.name) then
      client:stop(true)
    end
  end
  vim.defer_fn(function()
    -- A newer restart/selection supersedes this delayed activation.
    if generation == current_generation then
      vim.lsp.enable(selected)
    end
  end, 100)
end

return M
