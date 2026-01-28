-- ./lua/plugins/scrollbar.lua

-- nvim-scrollbar - scrollbar with LSP diagnostics integration
return {
	"petertriho/nvim-scrollbar",
	event = "BufReadPost",
	opts = {
		handlers = {
			cursor = true,
			diagnostic = true,
			gitsigns = true,
			handle = true,
			search = false,
		},
	},
}
