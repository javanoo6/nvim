-- ./lua/plugins/coding.lua

-- Coding: Mini.nvim utilities for coding
return {
	-- Comments
	{
		"echasnovski/mini.comment",
		event = "VeryLazy",
		opts = {
			mappings = {
				comment = "gc",    -- Toggle comment (operator)
				comment_line = "gcc", -- Toggle comment on current line
				comment_visual = "gc", -- Toggle comment on selection
				textobject = "gc", -- Textobject for comments
			},
		},
	},

	-- Surround
	{
		"echasnovski/mini.surround",
		event = "VeryLazy",
		opts = {
			mappings = {
				add = "gsa",
				delete = "gsd",
				find = "gsf",
				find_left = "gsF",
				highlight = "gsh",
				replace = "gsr",
				update_n_lines = "gsn",
			},
		},
	},

	-- Better text objects
	{
		"echasnovski/mini.ai",
		event = "VeryLazy",
		opts = function()
			local ai = require("mini.ai")
			return {
				n_lines = 500,
				custom_textobjects = {
					o = ai.gen_spec.treesitter({
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}, {}),
					f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
					c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
					t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
				},
			}
		end,
	},

	-- Yank history
	{
		"gbprod/yanky.nvim",
		event = "VeryLazy",
		opts = {
			ring = { history_length = 50 },
		},
		keys = {
			{ "p",     "<Plug>(YankyPutAfter)",      mode = "n",                  desc = "Put after" },
			{ "P",     "<Plug>(YankyPutBefore)",     mode = "n",                  desc = "Put before" },
			{ "p",     '"_dP',                       mode = "x",                  desc = "Put (preserve yank)" },
			{ "P",     '"_dP',                       mode = "x",                  desc = "Put before (preserve yank)" },
			{ "<C-p>", "<Plug>(YankyPreviousEntry)", desc = "Cycle yank backward" },
			{ "<C-n>", "<Plug>(YankyNextEntry)",     desc = "Cycle yank forward" },
		},
	},

	-- Refactoring (extract function/variable, inline variable)
	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
		keys = {
			{ "<leader>Re", function() require("refactoring").refactor("Extract Function") end,          mode = "x", desc = "Extract function" },
			{ "<leader>Rf", function() require("refactoring").refactor("Extract Function To File") end,  mode = "x", desc = "Extract function to file" },
			{ "<leader>Rv", function() require("refactoring").refactor("Extract Variable") end,          mode = "x", desc = "Extract variable" },
			{ "<leader>Ri", function() require("refactoring").refactor("Inline Variable") end,           mode = { "n", "x" }, desc = "Inline variable" },
			{ "<leader>Rb", function() require("refactoring").refactor("Extract Block") end,             mode = "n", desc = "Extract block" },
			{ "<leader>RB", function() require("refactoring").refactor("Extract Block To File") end,     mode = "n", desc = "Extract block to file" },
		},
		opts = {},
	},

	-- Auto pairs
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		dependencies = "hrsh7th/nvim-cmp",
		config = function()
			local npairs = require("nvim-autopairs")
			npairs.setup({
				check_ts = true,
				ts_config = {
					lua = { "string", "source" },
					java = { "string" },
				},
			})
			-- Integrate with cmp
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},
}
