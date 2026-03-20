-- ./lua/plugins/projects.lua

return {
	-- Project management with Telescope integration
	{
		"ahmedkhalf/project.nvim",
		event = "VimEnter",
		opts = {
			-- Manual mode - don't auto-add projects, use patterns below
			manual_mode = true,
			-- Detection methods: "lsp" (lsp root), "pattern" (git/etc markers)
			detection_methods = { "pattern", "lsp" },
			-- Patterns that indicate a project root
			patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", "go.mod", "pom.xml" },
			-- Show hidden files in project root
			show_hidden = false,
			-- Silent mode
			silent_chdir = true,
			-- Don't change directory automatically
			scope_chdir = "global",
			-- Path to store project history
			datapath = vim.fn.stdpath("data"),
		},
		config = function(_, opts)
			require("project_nvim").setup(opts)
			-- Load the Telescope extension
			require("telescope").load_extension("projects")
		end,
		dependencies = {
			"nvim-telescope/telescope.nvim",
		},
	},
}
