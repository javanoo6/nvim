-- ./lua/plugins/todo-comments.lua

-- Todo Comments: Highlight TODO, FIXME, NOTE, etc.
return {
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "]t", function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
			{ "[t", function() require("todo-comments").jump_prev() end, desc = "Previous todo comment" },
			{ "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
			{ "<leader>xT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
			{ "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo" },
		},
		config = function()
			require("todo-comments").setup({
				keywords = {
					FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
					TODO = { icon = " ", color = "info" },
					HACK = { icon = " ", color = "warning" },
					WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
					PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
					NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
					TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
				},
				gui_style = {
					fg = "NONE", -- The gui style to use for the fg highlight group.
					bg = "BOLD", -- The gui style to use for the bg highlight group.
				},
				merge_keywords = true, -- when true, custom keywords will be merged with the defaults
				highlight = {
					multiline = true,
					multiline_pattern = "^.",
					multiline_context = 10,
					before = "", -- "fg" or "bg" or empty
					keyword = "wide", -- "fg", "bg", "wide", "wide_bg", "wide_fg" or empty
					after = "fg", -- "fg" or "bg" or empty
					pattern = [[.*<(KEYWORDS)\s*:]], -- pattern or table of patterns
					comments_only = true,
					max_line_len = 400,
					exclude = {},
				},
				colors = {
					error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
					warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
					info = { "DiagnosticInfo", "#2563EB" },
					hint = { "DiagnosticHint", "#10B981" },
					default = { "Identifier", "#7C3AED" },
					test = { "Identifier", "#FF00FF" },
				},
				search = {
					command = "rg",
					args = {
						"--color=never",
						"--no-heading",
						"--with-filename",
						"--line-number",
						"--column",
					},
					pattern = [[\b(KEYWORDS):]], -- ripgrep regex
				},
			})
		end,
	},
}
