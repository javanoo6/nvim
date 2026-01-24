-- ./lua/plugins/mason.lua
-- Mason: Package manager for LSP servers, DAP, linters, formatters

return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        -- Java
        "jdtls",
        "java-debug-adapter",
        "java-test",
        "google-java-format",
        -- Lua
        "stylua",
        -- General
        "bash-language-server",
        "json-lsp",
        "yaml-language-server",
      },
    },
  },
}
