-- ./lua/plugins/glance.lua

-- Glance - beautiful LSP references/definitions preview
return {
	"dnlhc/glance.nvim",
	cmd = "Glance",
	keys = {
		{ "gd", "<cmd>Glance definitions<cr>", desc = "Glance definitions" },
		{ "gr", "<cmd>Glance references<cr>", desc = "Glance references" },
		{ "gy", "<cmd>Glance type_definitions<cr>", desc = "Glance type definitions" },
		{ "gI", "<cmd>Glance implementations<cr>", desc = "Glance implementations" },
	},
	opts = {
		hooks = {
			before_open = function(results, open, jump)
				if #results == 1 then
					jump(results[1])
				else
					open(results)
				end
			end,
		},
	},
}
