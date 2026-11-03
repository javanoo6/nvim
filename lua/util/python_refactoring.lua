local plugins = {
  pylsp_rope = { enabled = true, rename = false },
}
-- Pyright owns language features, Ruff owns linting, Conform owns formatting.
for _, name in ipairs({
  "autopep8",
  "flake8",
  "jedi_completion",
  "jedi_definition",
  "jedi_hover",
  "jedi_references",
  "jedi_rename",
  "jedi_signature_help",
  "jedi_symbols",
  "jedi_type_definition",
  "mccabe",
  "preload",
  "pycodestyle",
  "pydocstyle",
  "pyflakes",
  "pylint",
  "rope_autoimport",
  "rope_completion",
  "rope_rename",
  "yapf",
}) do
  plugins[name] = { enabled = false }
end

return {
  cmd = { vim.fn.stdpath("data") .. "/mason/bin/pylsp" },
  settings = { pylsp = { plugins = plugins } },
  on_init = function(client)
    -- pylsp advertises some methods even when their plugins are disabled.
    local keep = {
      textDocumentSync = true,
      codeActionProvider = true,
      executeCommandProvider = true,
      positionEncoding = true,
      workspace = true,
    }
    for capability in pairs(client.server_capabilities) do
      if not keep[capability] then
        client.server_capabilities[capability] = nil
      end
    end
  end,
}
