-- ./lua/plugins/undotree.lua

-- Undotree - better undo history
return {
	"mbbill/undotree",
	cmd = "UndotreeToggle",
	keys = {
		{ "<leader>U", "<cmd>UndotreeToggle<cr>", desc = "Undotree" },
	},
	config = function()
		vim.g.undotree_SetFocusWhenToggle = 1
		vim.g.undotree_WindowLayout = 2
	end,
}
