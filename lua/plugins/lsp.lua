return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "williamboman/mason.nvim", config = true },
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local map = require("util").map

      vim.api.nvim_create_autocmd("LspAttach", {
        group = require("util").augroup("lsp_attach"),
        callback = function(event)
          local opts = { buffer = event.buf }
          map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Goto definition" }))
          map("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Goto references" }))
          map("n", "gI", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Goto implementation" }))
          map("n", "gy", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "Goto type definition" }))
          map("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Goto declaration" }))
          map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))
          map("n", "gK", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
          map("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
          map("n", "<leader>cr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
        end,
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      require("mason").setup()

      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "bashls",
          "jsonls",
          "yamlls",
        },
        handlers = {
          function(server_name)
            if server_name ~= "jdtls" then
              require("lspconfig")[server_name].setup({
                capabilities = capabilities,
              })
            end
          end,
          ["lua_ls"] = function()
            require("lspconfig").lua_ls.setup({
              capabilities = capabilities,
              settings = {
                Lua = {
                  diagnostics = { globals = { "vim" } },
                  workspace = { checkThirdParty = false },
                },
              },
            })
          end,
        },
      })

      require("mason-tool-installer").setup({
        ensure_installed = {
          "java-debug-adapter",
          "java-test",
          "stylua",
        },
      })

      -- Floating borders
      local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
      function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
        opts = opts or {}
        opts.border = "rounded"
        return orig_util_open_floating_preview(contents, syntax, opts, ...)
      end
    end,
  },

  { "mfussenegger/nvim-jdtls", ft = "java" },
}
