-- ./lua/plugins/colorschemes.lua

-- Multiple color schemes with easy switching
return {
	-- Current: TokyoNight (default)
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			style = "night",
			transparent = false,
			styles = {
				sidebars = "dark",
				floats = "dark",
			},
		},
		config = function(_, opts)
			require("tokyonight").setup(opts)
			vim.cmd.colorscheme("tokyonight")
		end,
	},

	-- Kanagawa
	{
		"rebelot/kanagawa.nvim",
		lazy = true,
		priority = 1000,
		opts = {
			compile = false,
			undercurl = true,
			commentStyle = { italic = true },
			functionStyle = {},
			keywordStyle = { italic = true },
			statementStyle = { bold = true },
			typeStyle = {},
			transparent = false,
			dimInactive = false,
			terminalColors = true,
			colors = {
				palette = {},
				theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
			},
			theme = "wave",
			background = {
				dark = "wave",
				light = "lotus",
			},
		},
	},

	-- JB (JetBrains)
	{
		"nickkadutskyi/jb.nvim",
		lazy = true,
		priority = 1000,
		opts = {},
	},

	-- Oxocarbon
	{
		"nyoom-engineering/oxocarbon.nvim",
		lazy = true,
		priority = 1000,
	},

	-- Nyoom (this includes the color scheme)
	{
		"nyoom-engineering/nyoom.nvim",
		lazy = true,
		priority = 1000,
		config = function()
			-- Nyoom needs special loading
			vim.cmd("colorscheme nyoom")
		end,
	},

	-- Color scheme switcher
	{
		"zaldih/themery.nvim",
		event = "VeryLazy",
		opts = {
			themes = {
				{
					name = "TokyoNight Night",
					colorscheme = "tokyonight-night",
				},
				{
					name = "TokyoNight Storm",
					colorscheme = "tokyonight-storm",
				},
				{
					name = "Kanagawa Wave",
					colorscheme = "kanagawa-wave",
				},
				{
					name = "Kanagawa Dragon",
					colorscheme = "kanagawa-dragon",
				},
				{
					name = "Kanagawa Lotus",
					colorscheme = "kanagawa-lotus",
				},
				{
					name = "JB",
					colorscheme = "jb",
				},
				{
					name = "Oxocarbon",
					colorscheme = "oxocarbon",
				},
				{
					name = "Nyoom",
					colorscheme = "nyoom",
				},
			},
			livePreview = true,
		},
		keys = {
			{ "<leader>tc", "<cmd>Themery<cr>", desc = "Color schemes" },
		},
	},
}
