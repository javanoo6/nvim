-- quicker.nvim - editable quickfix list
return {
	"stevearc/quicker.nvim",
	event = "FileType qf",
	keys = {
		{
			"<leader>xq",
			function()
				require("quicker").toggle()
			end,
			desc = "Quickfix (editable)",
		},
	},
	opts = {
		keys = {
			{
				">",
				function()
					require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
				end,
				desc = "Expand context",
			},
			{
				"<",
				function()
					require("quicker").collapse()
				end,
				desc = "Collapse context",
			},
		},
	},
}
