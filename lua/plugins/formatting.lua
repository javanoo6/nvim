-- ./lua/plugins/formatting.lua

-- Formatting: conform.nvim configuration
return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
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
			formatters = {
				prettier_java = {
					command = "prettier",
					args = { "--stdin-filepath", "$FILENAME", "--plugin", "prettier-plugin-java" },
					stdin = true,
				},
			},
			formatters_by_ft = {
				lua = { "stylua" },
				java = { "prettier_java" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
		},
	},
}
