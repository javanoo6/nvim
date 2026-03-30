return {
	-- Diffview (keymaps live in keymaps.lua)
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
		keys = {
			"<leader>GD",
			"<leader>GF",
			"<leader>GH",
			"<leader>GL",
			"<leader>Gm",
			"<leader>GM",
		},
		opts = {
			hooks = {
				diff_buf_read = function()
					vim.opt_local.wrap = false
				end,
			},
		},
	},

	-- Merge conflict resolution helpers
	{
		"akinsho/git-conflict.nvim",
		event = "BufReadPre",
		opts = {
			default_mappings = {
				ours = "co",
				theirs = "ct",
				none = "c0",
				both = "cb",
				next = "]x",
				prev = "[x",
			},
			highlights = {
				incoming = "DiffAdd",
				current = "DiffText",
			},
		},
	},

	-- Gitsigns (on_attach keymaps are buffer-local, must stay here)
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
				untracked = { text = "▎" },
			},
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation
				map("n", "]h", function()
					if vim.wo.diff then
						return "]h"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Next hunk" })

				map("n", "[h", function()
					if vim.wo.diff then
						return "[h"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Prev hunk" })

				-- Hunk actions (<leader>Gh* prefix)
				map("n", "<leader>Ghs", gs.stage_hunk, { desc = "Stage hunk" })
				map("n", "<leader>Ghr", gs.reset_hunk, { desc = "Reset hunk" })
				map("v", "<leader>Ghs", function()
					gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "Stage hunk" })
				map("v", "<leader>Ghr", function()
					gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "Reset hunk" })
				map("n", "<leader>GhS", gs.stage_buffer, { desc = "Stage buffer" })
				map("n", "<leader>GhR", gs.reset_buffer, { desc = "Reset buffer" })
				map("n", "<leader>Ghu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
				map("n", "<leader>Ghp", gs.preview_hunk, { desc = "Preview hunk" })
				map("n", "<leader>Ghb", function()
					gs.blame_line({ full = true })
				end, { desc = "Blame line" })
				map("n", "<leader>GhB", gs.toggle_current_line_blame, { desc = "Toggle blame" })
				map("n", "<leader>Ghd", gs.diffthis, { desc = "Diff this" })

				-- Toggles
				map("n", "<leader>Ghw", gs.toggle_word_diff, { desc = "Toggle word diff" })
				map("n", "<leader>Ghl", gs.toggle_linehl, { desc = "Toggle line highlight" })
				map("n", "<leader>Ghv", gs.toggle_deleted, { desc = "Toggle deleted lines" })

				-- Text object
				map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
			end,
		},
	},
}
