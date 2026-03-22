-- toggleterm.nvim - persistent togglable terminal
return {
	"akinsho/toggleterm.nvim",
	version = "*",
	keys = {
		{ "<A-a>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal", mode = { "n", "t" } },
	},
	opts = {
		open_mapping = false, -- managed via keys above
		hide_numbers = true,
		direction = "float",
		float_opts = {
			border = "rounded",
		},
		-- <A-c> to hide from within terminal mode
		on_create = function(term)
			vim.keymap.set("t", "<A-c>", function()
				term:toggle()
			end, { buffer = term.bufnr, desc = "Hide terminal" })
		end,
	},
}
