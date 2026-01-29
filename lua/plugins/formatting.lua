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
					require("conform").format({ lsp_fallback = true })
				end,
				mode = { "n", "v" },
				desc = "Format",
			},
		},
		opts = {
--[[			formatters = {
				prettier_java = {
					command = "prettier",
					args = { "--stdin-filepath", "$FILENAME", "--plugin", "prettier-plugin-java" },
					stdin = true,
				},
			},]]
			formatters_by_ft = {
				lua = { "stylua" },
				go = { "gofmt" },
				python = { "black" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
			},
			format_on_save = function(bufnr)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end
				return { timeout_ms = 500, lsp_fallback = true }
			end,
		},
		config = function(_, opts)
			require("conform").setup(opts)

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
