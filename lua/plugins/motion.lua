-- ./lua/plugins/motion.lua

-- Motion plugins: flash, spider, treehopper
return {
	-- Flash.nvim - lightning fast navigation
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{ "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
			{ "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
			{ "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
			{ "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
			{ "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
		},
	},

	-- Spider.nvim - camelCase/PascalCase motion
	{
		"chrisgrieser/nvim-spider",
		lazy = true,
		keys = {
			{ "w", "<cmd>lua require('spider').motion('w')<CR>", mode = { "n", "o", "x" } },
			{ "e", "<cmd>lua require('spider').motion('e')<CR>", mode = { "n", "o", "x" } },
			{ "b", "<cmd>lua require('spider').motion('b')<CR>", mode = { "n", "o", "x" } },
			{ "ge", "<cmd>lua require('spider').motion('ge')<CR>", mode = { "n", "o", "x" } },
		},
	},

	-- nvim-treehopper - quick treesitter node selection
	{
		"mfussenegger/nvim-treehopper",
		dependencies = "nvim-treesitter/nvim-treesitter",
		keys = {
			{ "m", ":<C-u>lua require('tsht').nodes()<CR>", mode = "o", desc = "Select treesitter node" },
			{ "m", ":lua require('tsht').nodes()<CR>", mode = "v", desc = "Select treesitter node" },
		},
	},
}
