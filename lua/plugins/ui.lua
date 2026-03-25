-- ./lua/plugins/ui.lua

-- UI: Visual elements - statusline, bufferline, notifications
return {
	-- Icons
	{ "nvim-tree/nvim-web-devicons", lazy = true },

	-- Which-key
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "modern",
			plugins = { spelling = true },
			win = {
				border = "rounded",
				padding = { 1, 2 },
				no_overlap = true,
			},
			layout = {
				width = { min = 30, max = 50 },
				height = { min = 4, max = 25 },
				spacing = 1,
				align = "right",
			},
			sort = { "local", "order", "group", "alphanum" },
			filter = function(mapping)
				return true
			end,
		},
		config = function(_, opts)
			local wk = require("which-key")
			wk.setup(opts)
			wk.add({
				{ "<leader>b",     group = "buffer" },
				{ "<leader>c",     group = "code",              mode = { "n", "v" } },
				{ "<leader>co",    group = "outline" },
				{ "<leader>d",     group = "debug",              mode = { "n", "v" } },
				{ "<leader>dg",    group = "debug go" },
				{ "<leader>f",     group = "file/find" },
				{ "<leader>g",     group = "go" },
				{ "<leader>gi",    group = "go insert" },
				{ "<leader>gs",    group = "go struct tags" },
				{ "<leader>G",     group = "git",               mode = { "n", "v" } },
				{ "<leader>Gh",    group = "hunks",             mode = { "n", "v" } },
				{ "<leader>h",     group = "harpoon" },
				{ "<leader>H",     group = "history" },
				{ "<leader>l",     group = "lsp" },
				{ "<leader>j",     group = "java" },
				{ "<leader>jR",    group = "refactor",          mode = { "n", "v" } },
				{ "<leader>jg",    group = "generate" },
				{ "<leader>o",     group = "obsidian" },
				{ "<leader>p",     group = "plugins" },
				{ "<leader>q",     group = "quit/session" },
				{ "<leader>r",     group = "replace",           mode = { "n", "v" } },
				{ "<leader>R",     group = "refactor",          mode = { "n", "v", "x" } },
				{ "<leader>s",     group = "search" },
				{ "<leader>S",     group = "sessions" },
				{ "<leader>t",     group = "test" },
				{ "<leader>u",     group = "ui" },
				{ "<leader>w",     group = "windows" },
				{ "<leader>x",     group = "diagnostics/quickfix" },
				{ "<leader><tab>", group = "tabs" },
				{ "[",             group = "prev" },
				{ "]",             group = "next" },
				{ "g",             group = "goto/misc" },
				{ "gc",            group = "comment",           mode = { "n", "v" } },
				{ "gs",            group = "surround",          mode = { "n", "v" } },
				{ "z",             group = "fold" },
			})
		end,
	},

	-- Statusline
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = function()
			return {
				options = {
					theme = "auto",
					globalstatus = true,
					component_separators = { left = "|", right = "|" },
					section_separators = { left = "", right = "" },
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch" },
					lualine_c = {
						{
							"diagnostics",
							symbols = {
								error = " ",
								warn = " ",
								info = " ",
								hint = " ",
							},
						},
						{
							"filetype",
							icon_only = true,
							separator = "",
							padding = { left = 1, right = 0 },
						},
						{ "filename", path = 1, symbols = { modified = "  ", readonly = "", unnamed = "" } },
					},
					lualine_x = {
						{
							function()
								return require("util").get_root()
							end,
							icon = " ",
							color = { fg = "#6272a4" },
						},
						{
							"diff",
							symbols = {
								added = " ",
								modified = " ",
								removed = " ",
							},
						},
					},
					lualine_y = {
						{ "progress", separator = " ",                  padding = { left = 1, right = 0 } },
						{ "location", padding = { left = 0, right = 1 } },
					},
					lualine_z = {
						function()
							return " " .. os.date("%R")
						end,
					},
				},
				extensions = { "lazy", "neo-tree" },
			}
		end,
	},

	-- Buffer line
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		keys = {
			{ "<leader>bp", "<Cmd>BufferLineTogglePin<CR>",            desc = "Toggle pin" },
			{ "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
			{ "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>",          desc = "Delete other buffers" },
			{ "<leader>br", "<Cmd>BufferLineCloseRight<CR>",           desc = "Delete buffers to the right" },
			{ "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>",            desc = "Delete buffers to the left" },
			{ "<S-h>",      "<cmd>BufferLineCyclePrev<cr>",            desc = "Prev buffer" },
			{ "<S-l>",      "<cmd>BufferLineCycleNext<cr>",            desc = "Next buffer" },
			{ "[b",         "<cmd>BufferLineCyclePrev<cr>",            desc = "Prev buffer" },
			{ "]b",         "<cmd>BufferLineCycleNext<cr>",            desc = "Next buffer" },
		},
		opts = {
			highlights = {
				buffer_selected = {
					italic = true,
					bold = false,
					fg = { highlight = "Function", attribute = "fg" },
				},
				separator = {
					fg = { highlight = "Normal", attribute = "bg" },
				},
				separator_selected = {
					fg = { highlight = "Normal", attribute = "bg" },
				},
				separator_visible = {
					fg = { highlight = "Normal", attribute = "bg" },
				},
			},
			options = {
				diagnostics = "nvim_lsp",
				always_show_bufferline = false,
				separator_style = "slant",
				indicator = { style = "none" },
				color_icons = true,
				offsets = {
					{
						filetype = "neo-tree",
						text = "Neo-tree",
						highlight = "Directory",
						text_align = "left",
					},
				},
			},
		},
	},

	-- Indent guides
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "LazyFile",
		opts = {
			indent = {
				char = "│",
				tab_char = "│",
			},
			scope = { enabled = false },
			exclude = {
				filetypes = {
					"help",
					"lazy",
					"mason",
					"notify",
				},
			},
		},
		main = "ibl",
	},

	-- Notifications
	{
		"rcarriga/nvim-notify",
		keys = {
			{
				"<leader>un",
				function()
					require("notify").dismiss({ silent = true, pending = true })
				end,
				desc = "Dismiss all notifications",
			},
		},
		opts = {
			timeout = 3000,
			background_colour = "#1a1b26", -- tokyonight bg color
			max_height = function()
				return math.floor(vim.o.lines * 0.75)
			end,
			max_width = function()
				return math.floor(vim.o.columns * 0.75)
			end,
		},
		init = function()
			vim.notify = require("notify")
		end,
	},

	-- Better UI
	{
		"stevearc/dressing.nvim",
		lazy = true,
		init = function()
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.select = function(...)
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.select(...)
			end
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.input = function(...)
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.input(...)
			end
		end,
	},

	-- Highlight word under cursor and all its occurrences
	{
		"RRethy/vim-illuminate",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			delay = 100,
			large_file_cutoff = 2000,
			large_file_overrides = {
				providers = { "lsp" },
			},
		},
		config = function(_, opts)
			require("illuminate").configure(opts)
		end,
	},
}
