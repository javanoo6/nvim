-- ./lua/plugins/formatting.lua

-- Formatting: conform.nvim configuration
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo", "FormatEnable", "FormatDisable", "FormatDir" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ timeout_ms = 10000, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format",
      },
    },
    opts = {
      formatters = {
        idea_formatter = {
          command = "java",
          timeout = 10000,  -- 10 seconds for daemon startup
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
      local conform = require("conform")
      conform.setup(opts)

      local function format_buffer(bufnr)
        return conform.format({
          bufnr = bufnr,
          timeout_ms = 10000,
          lsp_format = "fallback",
          quiet = true,
        })
      end

      local function detect_filetype(bufnr, path)
        if vim.bo[bufnr].filetype ~= "" then
          return vim.bo[bufnr].filetype
        end

        local filetype = vim.filetype.match({ buf = bufnr, filename = path })
        if filetype and filetype ~= "" then
          vim.bo[bufnr].filetype = filetype
        end
        return vim.bo[bufnr].filetype
      end

      local function format_file(path)
        if vim.fn.filereadable(path) ~= 1 then
          return false, "unreadable"
        end

        local existing = vim.fn.bufnr(path)
        local had_existing_buffer = existing ~= -1
        local bufnr = had_existing_buffer and existing or vim.fn.bufadd(path)

        vim.fn.bufload(bufnr)
        detect_filetype(bufnr, path)

        local formatters, lsp = conform.list_formatters_to_run(bufnr)
        if vim.tbl_isempty(formatters) and not lsp then
          if not had_existing_buffer then
            pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
          end
          return false, "no formatter"
        end

        local ok, format_err, did_edit = pcall(format_buffer, bufnr)
        if not ok or format_err then
          if not had_existing_buffer then
            pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
          end
          return false, format_err or "format failed"
        end

        local modified = did_edit or vim.bo[bufnr].modified
        if modified then
          vim.api.nvim_buf_call(bufnr, function()
            vim.cmd("silent update")
          end)
        end

        if not had_existing_buffer then
          pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
        end

        return modified, nil
      end

      local function collect_files(dir)
        local files = vim.fn.globpath(dir, "**/*", false, true)
        return vim.tbl_filter(function(path)
          return vim.fn.filereadable(path) == 1
        end, files)
      end

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

      vim.api.nvim_create_user_command("FormatDir", function(command)
        local dir = command.args ~= "" and vim.fn.fnamemodify(command.args, ":p") or vim.uv.cwd()
        if vim.fn.isdirectory(dir) ~= 1 then
          vim.notify("FormatDir: not a directory: " .. dir, vim.log.levels.ERROR)
          return
        end

        local files = collect_files(dir)
        local changed = 0
        local skipped = 0
        local failed = 0

        for _, path in ipairs(files) do
          local did_change, err = format_file(path)
          if err == "no formatter" or err == "unreadable" then
            skipped = skipped + 1
          elseif err then
            failed = failed + 1
            vim.notify("FormatDir failed: " .. path .. "\n" .. tostring(err), vim.log.levels.WARN)
          elseif did_change then
            changed = changed + 1
          end
        end

        vim.notify(
          string.format("FormatDir complete: %d changed, %d skipped, %d failed", changed, skipped, failed),
          failed > 0 and vim.log.levels.WARN or vim.log.levels.INFO
        )
      end, {
        nargs = "?",
        complete = "dir",
        desc = "Format all files in a directory recursively",
      })
    end,
  },
}
