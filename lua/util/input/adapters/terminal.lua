local M = {}

function M.setup(buf, normalizer, translate)
  for _, alias in ipairs(normalizer.aliases) do
    if alias.kind ~= "modified" then
      vim.keymap.set("t", alias.lhs, function()
        return translate() and alias.rhs or alias.text
      end, { buffer = buf, expr = true, replace_keycodes = false, desc = "which_key_ignore" })
    end
  end
end

return M
