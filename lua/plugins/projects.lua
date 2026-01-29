-- ./lua/plugins/projects.lua

return {
	"coffebar/neovim-project",
	event = "VimEnter",
	opts = {
		projects = { -- define project roots
			"~/.config/*",
			"~/Desktop/*",
			"~/projects/*",
			"~/go/src/*",
			"~/workspace/*",
		},
		picker = {
			type = "telescope", -- one of "telescope", "fzf-lua", or "snacks"
		},
		session_manager_opts = {
			autoload_mode = "Disabled",
		},
	},
	init = function()
		-- enable saving the state of plugins in the session
		vim.opt.sessionoptions:append("globals") -- save global variables that start with an uppercase letter and contain at least one lowercase letter.
	end,
	dependencies = {
		{ "nvim-lua/plenary.nvim" },
		{ "nvim-telescope/telescope.nvim" },
		{ "Shatur/neovim-session-manager" },
	},
	lazy = false,
	priority = 100,
}
