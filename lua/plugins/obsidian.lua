return {
	"epwalsh/obsidian.nvim",
	version = "*",
	lazy = true,
	ft = "markdown",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "personal",
				path = "/home/konkov/Obsidian",
			},
		},
		-- Use Telescope for search
		picker = {
			name = "telescope.nvim",
		},
		-- Follow links with gf
		follow_url_func = function(url)
			vim.fn.jobstart({ "xdg-open", url })
		end,
		ui = {
			enable = true,
			checkboxes = {
				[" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
				["x"] = { char = "", hl_group = "ObsidianDone" },
			},
		},
		mappings = {
			-- Follow link under cursor
			["<CR>"] = {
				action = function()
					return require("obsidian").util.gf_passthrough()
				end,
				opts = { noremap = false, expr = true, buffer = true, desc = "Follow link" },
			},
-- Toggle checkbox
		["<leader>Oc"] = {
			action = function()
				return require("obsidian").util.toggle_checkbox()
			end,
			opts = { buffer = true, desc = "Toggle checkbox" },
		},
		},
	},
	keys = {
		{ "<leader>On", "<cmd>ObsidianNew<cr>",         desc = "New note" },
		{ "<leader>Oo", "<cmd>ObsidianOpen<cr>",        desc = "Open in Obsidian" },
		{ "<leader>Of", "<cmd>ObsidianQuickSwitch<cr>", desc = "Find note" },
		{ "<leader>Os", "<cmd>ObsidianSearch<cr>",      desc = "Search notes" },
		{ "<leader>Ob", "<cmd>ObsidianBacklinks<cr>",   desc = "Backlinks" },
		{ "<leader>Ol", "<cmd>ObsidianLinks<cr>",       desc = "Links in note" },
		{ "<leader>Ot", "<cmd>ObsidianTags<cr>",        desc = "Tags" },
		{ "<leader>Od", "<cmd>ObsidianDailies<cr>",     desc = "Daily notes" },
		{ "<leader>Or", "<cmd>ObsidianRename<cr>",      desc = "Rename note" },
		{ "<leader>Op", "<cmd>ObsidianPasteImg<cr>",    desc = "Paste image" },
	},
}
