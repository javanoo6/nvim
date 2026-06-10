-- ./lua/plugins/formatting.lua

-- Formatting: conform.nvim configuration
local format_skip_notices = {}

local function notify_format_skipped_for_errors(bufnr, error_count)
  local changedtick = vim.b[bufnr].changedtick or 0
  local last_notice = format_skip_notices[bufnr]
  if last_notice and last_notice.changedtick == changedtick and last_notice.error_count == error_count then
    return
  end

  format_skip_notices[bufnr] = {
    changedtick = changedtick,
    error_count = error_count,
  }

  local message = string.format("Format on save skipped: %d LSP error(s)", error_count)
  vim.notify(message, vim.log.levels.WARN, { title = "Conform" })
end

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo", "FormatterInfo", "FormatEnable", "FormatDisable", "FormatDir", "FormatDirPick" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ timeout_ms = 10000, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format",
      },
      {
        "<leader>cF",
        "<cmd>FormatDirPick<cr>",
        desc = "Format current dir or prompt",
      },
    },
    opts = {
      formatters = {
        idea_formatter = {
          command = "java",
          timeout = 10000, -- 10 seconds for daemon startup
          args = function()
            local home = vim.env.HOME
            local jar = home .. "/.config/nvim/intellij-code-formatter/formatter-cli/target/formatter-cli-full.jar"
            local editorconfig = home .. "/.config/nvim/.editorconfig"
            return {
              "-jar",
              jar,
              "--format",
              "--optimize-imports",
              "--rearrange",
              "--editorconfig",
              editorconfig,
              "$FILENAME",
            }
          end,
          condition = function()
            local home = vim.env.HOME
            local jar = home .. "/.config/nvim/intellij-code-formatter/formatter-cli/target/formatter-cli-full.jar"
            return vim.fn.executable("java") == 1 and vim.fn.filereadable(jar) == 1
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
          notify_format_skipped_for_errors(bufnr, #diagnostics)
          return
        end

        format_skip_notices[bufnr] = nil
        return { timeout_ms = 500, lsp_format = "fallback" }
      end,
    },
    config = function(_, opts)
      local conform = require("conform")
      conform.setup(opts)

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

      require("util.format_dir").register_commands(conform, opts.formatters_by_ft or {})
    end,
  },
}
