-- ./lua/plugins/linting.lua

-- Linting: nvim-lint for additional static analysis
return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				--java = { "checkstyle" },
				go = { "golangcilint" },
				python = { "ruff" },
			}

			-- Fix: golangci-lint needs cwd set to the file's directory (or module root)
			-- so it can find go.mod, otherwise it exits with code 5 (no Go files found)
			lint.linters.golangcilint = vim.tbl_extend("force", lint.linters.golangcilint, {
				cwd = function()
					return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
				end,
			})

			-- Run linting on save
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
				group = require("util").augroup("lint"),
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
}
