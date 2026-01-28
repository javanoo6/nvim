-- ./lua/plugins/editor.lua

-- Editor: Navigation, file explorer, git integration
return {
	-- Telescope
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		version = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				enabled = vim.fn.executable("make") == 1,
				config = function()
					require("telescope").load_extension("fzf")
				end,
			},
		},
		keys = {
			{ "<leader><space>", "<cmd>Telescope find_files<cr>",            desc = "Find files" },
			{ "<leader>ff",      "<cmd>Telescope find_files<cr>",            desc = "Find files" },
			{ "<leader>fg",      "<cmd>Telescope live_grep<cr>",             desc = "Grep" },
			{ "<leader>fb",      "<cmd>Telescope buffers<cr>",               desc = "Buffers" },
			{ "<leader>fr",      "<cmd>Telescope oldfiles<cr>",              desc = "Recent files" },
			{ "<leader>fh",      "<cmd>Telescope help_tags<cr>",             desc = "Help" },
			{ "<leader>:",       "<cmd>Telescope command_history<cr>",       desc = "Command history" },
			{ "<leader>ss",      "<cmd>Telescope lsp_document_symbols<cr>",  desc = "Document symbols" },
			{ "<leader>sS",      "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace symbols" },
		},
		opts = function()
			local actions = require("telescope.actions")
			return {
				defaults = {
					prompt_prefix = " ",
					selection_caret = " ",
					mappings = {
						i = {
							["<C-j>"] = actions.move_selection_next,
							["<C-k>"] = actions.move_selection_previous,
							["<C-n>"] = actions.cycle_history_next,
							["<C-p>"] = actions.cycle_history_prev,
							["<esc>"] = actions.close,
						},
					},
				},
			}
		end,
		config = function(_, opts)
			require("telescope").setup(opts)
			require("util").picker = require("telescope.builtin")
			require("telescope").load_extension("yank_history")
		end,
	},

	-- File explorer
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		cmd = "Neotree",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		keys = {
			{
				"<leader>e",
				function()
					require("neo-tree.command").execute({ toggle = true, dir = require("util").get_root() })
				end,
				desc = "Explorer (root)",
			},
			{
				"<leader>E",
				function()
					require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
				end,
				desc = "Explorer (cwd)",
			},
		},
		opts = {
			filesystem = {
				follow_current_file = { enabled = true },
				hijack_netrw_behavior = "open_current",
				commands = {
					-- Expand node and all single-child descendants
					expand_single_children = function(state)
						local node = state.tree:get_node()
						if node.type ~= "directory" then return end

						local fs = require("neo-tree.sources.filesystem")
						local renderer = require("neo-tree.ui.renderer")

						local function expand_node(n)
							if n.type ~= "directory" then return end
							if not n:is_expanded() then
								n:expand()
							end
							fs.navigate(state, state.path, n:get_id(), function()
								local children = state.tree:get_nodes(n:get_id())
								-- Single child that's a directory -> keep expanding
								if #children == 1 and children[1].type == "directory" then
									expand_node(children[1])
								end
								renderer.redraw(state)
							end)
						end

						expand_node(node)
					end,
				},
				window = {
					mappings = {
						-- Override default open behavior
						["<cr>"] = "expand_single_children",
						["o"] = "open",
					},
				},
			},
		},
	},

	-- Git signs
	{
		"lewis6991/gitsigns.nvim",
		event = "LazyFile",
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
				untracked = { text = "▎" },
			},
			on_attach = function(buffer)
				local gs = package.loaded.gitsigns
				local map = require("util").map

				map("n", "]h", gs.next_hunk, { buffer = buffer, desc = "Next hunk" })
				map("n", "[h", gs.prev_hunk, { buffer = buffer, desc = "Prev hunk" })
				map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", { buffer = buffer, desc = "Stage hunk" })
				map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", { buffer = buffer, desc = "Reset hunk" })
				map("n", "<leader>ghS", gs.stage_buffer, { buffer = buffer, desc = "Stage buffer" })
				map("n", "<leader>ghu", gs.undo_stage_hunk, { buffer = buffer, desc = "Undo stage hunk" })
				map("n", "<leader>ghR", gs.reset_buffer, { buffer = buffer, desc = "Reset buffer" })
				map("n", "<leader>ghp", gs.preview_hunk, { buffer = buffer, desc = "Preview hunk" })
				map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, { buffer = buffer, desc = "Blame line" })
				map("n", "<leader>ghd", gs.diffthis, { buffer = buffer, desc = "Diff this" })
			end,
		},
	},

	-- Better escape
	{
		"max397574/better-escape.nvim",
		event = "InsertEnter",
		opts = {},
	},

	-- Lazygit
	{
		"kdheepak/lazygit.nvim",
		cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
		},
	},

	-- Harpoon
	{
		"ThePrimeagen/harpoon",
		branch = "master",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader>ha", function() require("harpoon.mark").add_file() end,        desc = "Add file" },
			{ "<leader>hh", function() require("harpoon.ui").toggle_quick_menu() end, desc = "Harpoon menu" },
			{ "<leader>h1", function() require("harpoon.ui").nav_file(1) end,         desc = "File 1" },
			{ "<leader>h2", function() require("harpoon.ui").nav_file(2) end,         desc = "File 2" },
			{ "<leader>h3", function() require("harpoon.ui").nav_file(3) end,         desc = "File 3" },
			{ "<leader>h4", function() require("harpoon.ui").nav_file(4) end,         desc = "File 4" },
		},
		opts = { menu = { width = 120 } },
	},
}
