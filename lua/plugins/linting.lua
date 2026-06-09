-- ./lua/plugins/linting.lua

-- Linting: nvim-lint for additional static analysis
return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

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
        lua = { "selene" },
        markdown = { "markdownlint-cli2" },
        python = { "ruff" },
        sh = { "shellcheck" },
        yaml = { "yamllint" },
        zsh = { "shellcheck" },
      }

      -- nvim-lint expects linter.cwd to be a string. Pass cwd per invocation
      -- instead so each buffer lints from its own directory.
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        group = require("util").augroup("lint"),
        callback = function(args)
          local cwd = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":h")
          local names = available_linters(args.buf)

          if #names == 0 then
            return
          end

          lint.try_lint(names, { cwd = cwd })
        end,
      })
    end,
  },
}
