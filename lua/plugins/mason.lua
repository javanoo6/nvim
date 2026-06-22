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
        "stylua",
        "selene",
        "bash-language-server",
        "json-lsp",
        "yaml-language-server",
        "typescript-language-server",
        "pyright",
        "ruff",
        "prettier",
        "eslint_d",
        "shellcheck",
        "markdownlint-cli2",
        "yamllint",
        "golangci-lint",
        "gopls",
        "gofumpt",
        "goimports-reviser",
        "golines",
        "delve",
      },
    },
  },
}
