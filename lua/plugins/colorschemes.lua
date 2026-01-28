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

	-- Nordic
	{
		"AlexvZyl/nordic.nvim",
		lazy = true,
		priority = 1000,
		opts = {
			cursorline = {
				bold = false,
				bold_number = true,
				theme = "dark",
				blend = 0.85,
			},
			noice = {
				style = "classic",
			},
			telescope = {
				style = "flat",
			},
			leap = {
				dim_backdrop = false,
			},
			ts_context = {
				dark_background = true,
			},
			transparent = {
				bg = false,
				float = false,
			},
			swap_backgrounds = false,
			on_palette = function(palette) end,
			on_highlight = function(highlights, palette) end,
		},
	},

	-- Vague
	{
		"vague-theme/vague.nvim",
		lazy = true,
		priority = 1000,
		opts = {},
	},

	-- OneNord
	{
		"rmehri01/onenord.nvim",
		lazy = true,
		priority = 1000,
		opts = {},
	},

	-- Evergarden
	{
		"everviolet/nvim",
		name = "evergarden",
		lazy = true,
		priority = 1000,
		opts = {},
	},

	-- Poimandres
	{
		"olivercederborg/poimandres.nvim",
		lazy = true,
		priority = 1000,
		opts = {
			disable_background = false,
			disable_float_background = false,
			disable_italics = false,
		},
	},

	-- Color scheme switcher
	{
		"zaldih/themery.nvim",
		event = "VeryLazy",
		opts = {
			themes = {
				{ name = "TokyoNight Night", colorscheme = "tokyonight-night" },
				{ name = "TokyoNight Storm", colorscheme = "tokyonight-storm" },
				{ name = "Kanagawa Wave",    colorscheme = "kanagawa-wave",   before = [[require("lazy").load({ plugins = { "kanagawa.nvim" } })]] },
				{ name = "Kanagawa Dragon",  colorscheme = "kanagawa-dragon", before = [[require("lazy").load({ plugins = { "kanagawa.nvim" } })]] },
				{ name = "Kanagawa Lotus",   colorscheme = "kanagawa-lotus",  before = [[require("lazy").load({ plugins = { "kanagawa.nvim" } })]] },
				{ name = "JB",               colorscheme = "jb",              before = [[require("lazy").load({ plugins = { "jb.nvim" } })]] },
				{ name = "Oxocarbon",        colorscheme = "oxocarbon",       before = [[require("lazy").load({ plugins = { "oxocarbon.nvim" } })]] },
				{ name = "Nordic",           colorscheme = "nordic",          before = [[require("lazy").load({ plugins = { "nordic.nvim" } })]] },
				{ name = "Vague",            colorscheme = "vague",           before = [[require("lazy").load({ plugins = { "vague.nvim" } })]] },
				{ name = "OneNord",          colorscheme = "onenord",         before = [[require("lazy").load({ plugins = { "onenord.nvim" } })]] },
				{ name = "Evergarden",       colorscheme = "evergarden",      before = [[require("lazy").load({ plugins = { "evergarden" } })]] },
				{ name = "Poimandres",       colorscheme = "poimandres",      before = [[require("lazy").load({ plugins = { "poimandres.nvim" } })]] },
			},
		},
		keys = {
			{ "<leader>tc", "<cmd>Themery<cr>", desc = "Color schemes" },
		},
	},
}
