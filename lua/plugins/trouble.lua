-- ./lua/plugins/trouble.lua

-- Trouble.nvim - better diagnostics UI
return {
	"folke/trouble.nvim",
	cmd = { "TroubleToggle", "Trouble" },
	dependencies = "nvim-tree/nvim-web-devicons",
	keys = {
		{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",              desc = "Diagnostics (Trouble)" },
		{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
		{ "<leader>cs", "<cmd>Trouble symbols toggle<cr>",                  desc = "Symbols" },
		{ "<leader>cl", "<cmd>Trouble lsp toggle<cr>",                      desc = "LSP Definitions/references" },
		{ "<leader>xL", "<cmd>Trouble loclist toggle<cr>",                  desc = "Location List" },
		{ "<leader>xQ", "<cmd>Trouble qflist toggle<cr>",                   desc = "Quickfix List" },
		{
			"]q",
			function() require("trouble").next({ skip_groups = true, jump = true }) end,
			desc = "Next trouble",
		},
		{
			"[q",
			function() require("trouble").prev({ skip_groups = true, jump = true }) end,
			desc = "Prev trouble",
		},
	},
	opts = {},
}
