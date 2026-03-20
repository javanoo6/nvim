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

			-- BROKEN: linter.cwd must be a string, not a function —
			-- passing a function causes "Invalid 'args': Cannot convert given Lua type"
			-- at vim.cmd.cd() inside nvim-lint's with_cwd()
			-- lint.linters.golangcilint = vim.tbl_extend("force", lint.linters.golangcilint, {
			-- 	cwd = function()
			-- 		return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
			-- 	end,
			-- })

			-- FIX: pass cwd per-invocation via try_lint opts instead
			-- https://github.com/mfussenegger/nvim-lint#usage (try_lint opts.cwd)
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
				group = require("util").augroup("lint"),
				callback = function()
					local cwd = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
					lint.try_lint(nil, { cwd = cwd })
				end,
			})
		end,
	},
}
