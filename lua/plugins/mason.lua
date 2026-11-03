-- ./lua/plugins/mason.lua

-- Mason: Package manager for LSP servers, DAP, linters, formatters
return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {
      registries = { "lua:util.mason_registry", "github:mason-org/mason-registry" },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    init = function()
      require("util.selene").setup()
    end,
    opts = {
      ensure_installed = {
        "stylua",
        {
          "selene",
          condition = function()
            return not require("util.selene").source_install() and vim.fn.executable("selene") == 0
          end,
        },
        "bash-language-server",
        "json-lsp",
        "yaml-language-server",
        "typescript-language-server",
        "pyright",
        "python-lsp-server",
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
        "debugpy",
      },
    },
  },
}
