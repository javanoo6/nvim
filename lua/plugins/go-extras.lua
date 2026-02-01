-- ./lua/plugins/go-extras.lua

-- Go development helpers: struct tags, iferr, etc.
return {
	{
		"olexsmir/gopher.nvim",
		ft = "go",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		build = function()
			vim.cmd.GoInstallDeps()
		end,
		config = function(_, opts)
			require("gopher").setup(opts)
		end,
		keys = {
			{ "<leader>gsj", "<cmd>GoTagAdd json<cr>", desc = "Add JSON struct tags" },
			{ "<leader>gsy", "<cmd>GoTagAdd yaml<cr>", desc = "Add YAML struct tags" },
			{ "<leader>gsd", "<cmd>GoTagAdd db<cr>", desc = "Add DB struct tags" },
			{ "<leader>gie", "<cmd>GoIfErr<cr>", desc = "Add if err != nil" },
		},
	},
}
