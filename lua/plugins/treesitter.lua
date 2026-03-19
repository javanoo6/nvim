-- ./lua/plugins/treesitter.lua

-- Treesitter: Syntax highlighting and code understanding
return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		lazy = false,
		build = ":TSUpdate",
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"go",
				"gomod",
				"gowork",
				"gotmpl",
				"html",
				"java",
				"javascript",
				"json",
				"lua",
				"markdown",
				"markdown_inline",
				"python",
				"query",
				"vim",
				"vimdoc",
				"yaml",
				"xml",
				"groovy",
				"kotlin",
			},
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
			incremental_selection = {
				enable = true,
				-- THIS WORKS ONLY IN V MODE
				keymaps = {
					init_selection = "<cr>", -- Start selection
					node_incremental = "<tab>", -- Move to parent node
					node_decremental = "<S-tab>", -- Back to previous node
					scope_incremental = "<bs>", -- Move to next scope
				},
			},
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		dependencies = "nvim-treesitter/nvim-treesitter",
		config = function()
			require("nvim-treesitter.configs").setup({
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
						-- Keymaps are defined in lua/config/keymaps.lua for Which-key visibility
					},
					move = {
						enable = true,
						set_jumps = true,
						-- Keymaps are defined in lua/config/keymaps.lua for Which-key visibility
					},
				},
			})
		end,
	},

	-- Rainbow delimiters
	{
		"HiPhish/rainbow-delimiters.nvim",
		event = "LazyFile",
		dependencies = "nvim-treesitter/nvim-treesitter",
		config = function()
			local rainbow_delimiters = require("rainbow-delimiters")
			vim.g.rainbow_delimiters = {
				strategy = {
					[""] = rainbow_delimiters.strategy["global"],
				},
				query = {
					[""] = "rainbow-delimiters",
				},
				priority = {
					[""] = 110,
				},
				highlight = {
					"RainbowDelimiterRed",
					"RainbowDelimiterYellow",
					"RainbowDelimiterBlue",
					"RainbowDelimiterOrange",
					"RainbowDelimiterGreen",
					"RainbowDelimiterViolet",
					"RainbowDelimiterCyan",
				},
			}
		end,
	},
}
