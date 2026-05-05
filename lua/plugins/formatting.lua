-- ./lua/plugins/formatting.lua

-- Formatting: conform.nvim configuration
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo", "FormatEnable", "FormatDisable" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format",
      },
    },
    opts = {
      formatters = {
        idea_formatter = {
          command = "java",
          args = function()
            local home = vim.env.HOME
            return {
              "-jar",
              home .. "/.config/nvim/intellij-code-formatter/formatter-cli/target/formatter-cli-full.jar",
              "--format",
              "--optimize-imports",
              "--rearrange",
              "--editorconfig",
              home .. "/.config/nvim/.editorconfig",
              "$FILENAME",
            }
          end,
          stdin = false,
        },
        ["goimports-reviser"] = {
          command = "goimports-reviser",
          args = { "-output", "stdout", "$FILENAME" },
          stdin = false,
        },
        golines = {
          command = "golines",
          args = { "--max-len", "120", "--base-formatter", "gofumpt" },
        },
      },
      formatters_by_ft = {
        lua = { "stylua" },
        go = { "gofumpt", "goimports-reviser", "golines" },
        python = { "idea_formatter" },
        json = { "prettier" },
        yaml = { "idea_formatter" },
        markdown = { "idea_formatter" },
        java = { "idea_formatter" },
        xml = { "idea_formatter" },
        sh = { "idea_formatter" },
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        if vim.bo[bufnr].filetype == "go" then
          return
        end

        -- Skip formatting if there are LSP errors
        local diagnostics = vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR })
        if #diagnostics > 0 then
          return
        end

        return { timeout_ms = 500, lsp_format = "fallback" }
      end,
    },
    config = function(_, opts)
      require("conform").setup(opts)

      -- Enable auto-formatting by default
      vim.g.disable_autoformat = false

      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          vim.b.disable_autoformat = true
        else
          vim.g.disable_autoformat = true
        end
      end, { bang = true, desc = "Disable format on save" })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, { desc = "Enable format on save" })
    end,
  },
}
