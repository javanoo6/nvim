-- ./lua/plugins/autosave.lua

-- Auto-save - auto save on insert leave or text change
return {
	"okuuva/auto-save.nvim",
	event = { "InsertLeave", "TextChanged" },
	opts = {
		trigger_events = { "InsertLeave", "TextChanged" },
		debounce_delay = 1000,
	},
}
