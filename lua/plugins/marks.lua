-- ./lua/plugins/marks.lua

-- Marks.nvim - better marks with persistence
return {
	"chentoast/marks.nvim",
	event = "VeryLazy",
	opts = {
		default_mappings = true,
		builtin_marks = { ".", "<", ">", "^" },
		cyclic = true,
		force_write_shada = false,
		refresh_interval = 250,
	},
}
