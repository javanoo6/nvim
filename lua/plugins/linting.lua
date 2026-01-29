-- ./lua/plugins/linting.lua

-- Linting: nvim-lint for additional static analysis
return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				java = { "checkstyle" },
				go = { "golangcilint" },
				python = { "ruff" },
			}

			-- Run linting on save
			vim.api.nvim_create_autocmd({ "BufWritePost" }, {
				group = require("util").augroup("lint"),
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
}
