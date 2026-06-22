-- ./lua/plugins/linting.lua

-- Linting: nvim-lint for additional static analysis
return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local util = require("util")
      local lint = require("lint")
      local lint_timers = {}

      local function available_linters(bufnr)
        local filetype = vim.bo[bufnr].filetype
        local names = lint.linters_by_ft[filetype] or {}
        local available = {}

        for _, name in ipairs(names) do
          local linter = lint.linters[name]
          local cmd = linter and linter.cmd

          if type(cmd) == "function" then
            cmd = cmd()
          end

          if type(cmd) ~= "string" or vim.fn.executable(cmd) == 1 then
            table.insert(available, name)
          end
        end

        return available
      end

      lint.linters_by_ft = {
        bash = { "shellcheck" },
        go = { "golangcilint" },
        javascript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        lua = { "selene" },
        markdown = { "markdownlint-cli2" },
        python = { "ruff" },
        sh = { "shellcheck" },
        typescript = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        yaml = { "yamllint" },
        zsh = { "shellcheck" },
      }

      local markdownlint = lint.linters["markdownlint-cli2"]
      if markdownlint then
        local mason = vim.fn.stdpath("data") .. "/mason"
        local node = vim.fn.glob(mason .. "/packages/basedpyright/venv/lib/python*/site-packages/nodejs_wheel/bin/node", false, true)[1]
        local script = mason .. "/packages/markdownlint-cli2/node_modules/markdownlint-cli2/markdownlint-cli2-bin.mjs"
        if node and vim.fn.executable(node) == 1 and vim.fn.filereadable(script) == 1 then
          markdownlint.cmd = node
          markdownlint.args = { script, "-" }
        end
      end

      local function lint_buffer(bufnr)
        if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
          return
        end

        local names = available_linters(bufnr)

        if #names == 0 then
          return
        end

        local cwd = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
        local root = util.get_root(bufnr) or cwd
        local selene = {}
        local others = {}

        for _, name in ipairs(names) do
          if name == "selene" then
            selene[#selene + 1] = name
          else
            others[#others + 1] = name
          end
        end

        vim.api.nvim_buf_call(bufnr, function()
          -- Selene only sees the repo-local Neovim std/config when it runs from
          -- the config root. Keep the other linters buffer-relative.
          if #selene > 0 then
            lint.try_lint(selene, { cwd = root })
          end

          if #others > 0 then
            lint.try_lint(others, { cwd = cwd })
          end
        end)
      end

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        group = require("util").augroup("lint"),
        callback = function(args)
          if args.event == "BufWritePost" then
            lint_buffer(args.buf)
            return
          end

          local existing = lint_timers[args.buf]
          if existing then
            existing:stop()
            existing:close()
          end

          local timer = vim.uv.new_timer()
          lint_timers[args.buf] = timer
          timer:start(300, 0, function()
            timer:stop()
            timer:close()
            lint_timers[args.buf] = nil
            vim.schedule(function()
              lint_buffer(args.buf)
            end)
          end)
        end,
      })
    end,
  },
}
