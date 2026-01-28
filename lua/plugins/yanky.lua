-- ./lua/plugins/yanky.lua

-- Yanky.nvim - better yank history and ring
return {
	"gbprod/yanky.nvim",
	dependencies = { "kkharji/sqlite.lua" },
	keys = {
		{
			"<leader>p",
			function()
				require("telescope").extensions.yank_history.yank_history({})
			end,
			desc = "Paste from history",
		},
		{ "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank" },
		{ "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Paste after" },
		{ "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Paste before" },
		{ "[y", "<Plug>(YankyCycleForward)", desc = "Cycle yank forward" },
		{ "]y", "<Plug>(YankyCycleBackward)", desc = "Cycle yank backward" },
	},
	opts = {
		highlight = { timer = 150 },
		ring = { storage = "sqlite" },
	},
}
