local M = {}

function M.setup(normalizer)
  vim.opt.langmap = normalizer.langmap
  vim.opt.langremap = false
  for _, alias in ipairs(normalizer.aliases) do
    local modified = alias.kind == "modified"
    -- Plain aliases make English mappings run after translation (Д -> mapped
    -- L, not native L). Keep these out of Select and text-entry modes.
    local modes = modified and { "n", "x", "s", "o", "i", "c", "t" } or { "n", "x", "o" }
    -- Recursive forwarding preserves lazy loaders and buffer-local overrides.
    vim.keymap.set(modes, alias.lhs, alias.rhs, { remap = true, silent = modified, desc = "which_key_ignore" })
  end
end

return M
