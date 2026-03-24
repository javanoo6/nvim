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
			{
				"<leader>cI",
				function()
					require("conform").format({ formatters = { "idea_formatter" }, async = true })
				end,
				mode = { "n", "v" },
				desc = "Format with IntelliJ formatter",
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
			formatters = {
				idea_formatter = {
					command = "java",
					args = {
						"-jar",
						"/home/konkov/Desktop/repos/idea-code-formatter/idea-code-formatter/target/idea-code-formatter-1.0.0-SNAPSHOT.jar",
						"$FILENAME",
					},
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
				python = { "black" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
			},
			format_on_save = function(bufnr)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end
				if vim.bo[bufnr].filetype == "java" or vim.bo[bufnr].filetype == "go" then
					return
				end
				return { timeout_ms = 500, lsp_format = "fallback" }
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
