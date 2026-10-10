-- ./lua/plugins/formatting.lua

-- Formatting: conform.nvim configuration
local format_skip_notices = {}
local rubocop_availability = {}

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

local slow_formatter_filetypes = {
  java = true,
  markdown = true,
  python = true,
  ruby = true,
  sh = true,
  xml = true,
  yaml = true,
}

local function ruby_rubocop_command(ctx)
  local ruby = require("util.ruby")
  local root = ruby.root_dir(ctx.filename)
  local gemfile = ruby.bundle_gemfile_for(ctx.filename)
  local command = gemfile and "bundle exec rubocop" or "rubocop"

  return ruby.rvm_script(command .. ' -x --force-exclusion "$@"', { root = root, gemfile = gemfile })
end

local function ruby_rubocop_available(ctx)
  local ruby = require("util.ruby")
  local root = ruby.root_dir(ctx.filename)
  local gemfile = ruby.bundle_gemfile_for(ctx.filename)
  local command = gemfile and "bundle exec rubocop" or "rubocop"
  local key = table.concat({ root or "", gemfile or "", command }, "\n")

  if rubocop_availability[key] ~= nil then
    return rubocop_availability[key]
  end

  local script = ruby.rvm_script(command .. " --version >/dev/null 2>&1", { root = root, gemfile = gemfile })
  vim.fn.system({ "zsh", "-lc", script })
  rubocop_availability[key] = vim.v.shell_error == 0

  return rubocop_availability[key]
end

local function format_on_save_timeout(bufnr)
  if slow_formatter_filetypes[vim.bo[bufnr].filetype] then
    return 10000
  end

  return 500
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
          require("util.format").format(0)
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
        -- Our standalone formatter is more capable than the pinned LSP formatter
        -- for Java cleanup and the demonstrated non-Java formatting routes.
        -- Capability                 | Standalone jar       | LSP 263.6379.0
        -- Java formatting            | Yes                  | Yes
        -- Optimize Java imports      | Yes                  | Yes (separate command)
        -- Rearrange Java members     | Yes                  | Unavailable
        -- Markdown / XML formatting  | Verified in baseline | Unavailable
        -- Python / YAML              | Enabled by request   | Unavailable
        -- Shell                      | Enabled by request   | Unavailable
        idea_formatter = {
          command = "java",
          args = function(_, ctx)
            local args = {
              "-jar",
              vim.fn.stdpath("config") .. "/intellij-code-formatter/formatter-cli/target/formatter-cli-full.jar",
              "--format",
            }
            -- Range formatting uses Conform's filtered edits; keep cleanup out of it.
            if not ctx.range then
              vim.list_extend(args, { "--optimize-imports", "--rearrange" })
            end
            vim.list_extend(args, { "--editorconfig", vim.fn.stdpath("config") .. "/.editorconfig", "$FILENAME" })
            return args
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
        rubocop_rvm = {
          command = "zsh",
          args = function(_, ctx)
            return {
              "-lc",
              ruby_rubocop_command(ctx),
              "rubocop-format",
              "$FILENAME",
            }
          end,
          cwd = function(_, ctx)
            return require("util.ruby").root_dir(ctx.filename)
          end,
          condition = function(_, ctx)
            return vim.fn.executable("zsh") == 1
              and vim.fn.filereadable(vim.env.HOME .. "/.rvm/scripts/rvm") == 1
              and ruby_rubocop_available(ctx)
          end,
          exit_codes = { 0, 1 },
          stdin = false,
        },
      },
      formatters_by_ft = {
        lua = { "stylua" },
        go = { "gofumpt", "goimports-reviser", "golines" },
        python = { "idea_formatter", lsp_format = "never" },
        ruby = { "rubocop_rvm" },
        json = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        yaml = { "idea_formatter", lsp_format = "never" },
        markdown = { "idea_formatter", lsp_format = "never" },
        java = { "idea_formatter", lsp_format = "never" },
        xml = { "idea_formatter", lsp_format = "never" },
        sh = { "idea_formatter", lsp_format = "never" },
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
        local opts, err = require("util.format").options(bufnr, { timeout_ms = format_on_save_timeout(bufnr) })
        if err then
          vim.notify(err, vim.log.levels.WARN, { title = "Formatting" })
        end
        return opts
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
