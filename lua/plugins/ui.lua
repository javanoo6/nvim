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
		},
		config = function(_, opts)
			local wk = require("which-key")
			wk.setup(opts)
			wk.add({
				{ "<leader>b",     group = "buffer" },
				{ "<leader>c",     group = "code" },
				{ "<leader>d",     group = "debug" },
				{ "<leader>f",     group = "file/find" },
				{ "<leader>g",     group = "git" },
				{ "<leader>h",     group = "harpoon" },
				{ "<leader>j",     group = "java" },
				{ "<leader>q",     group = "quit/session" },
				{ "<leader>s",     group = "search" },
				{ "<leader>t",     group = "test/theme" },
				{ "<leader>u",     group = "ui" },
				{ "<leader>w",     group = "windows" },
				{ "<leader>x",     group = "diagnostics/quickfix" },
				{ "<leader><tab>", group = "tabs" },
				{ "[",             group = "prev" },
				{ "]",             group = "next" },
				{ "g",             group = "goto" },
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
						{ "filetype", icon_only = true, separator = "",                                            padding = { left = 1, right = 0 } },
						{ "filename", path = 1,         symbols = { modified = "  ", readonly = "", unnamed = "" } },
					},
					lualine_x = {
						{
							function() return require("util").get_root() end,
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
			options = {
				diagnostics = "nvim_lsp",
				always_show_bufferline = false,
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
}
