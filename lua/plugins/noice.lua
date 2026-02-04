-- ./lua/plugins/noice.lua

-- Noice.nvim - modern UI for messages, command line, and notifications
return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
	opts = {
		lsp = {
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				["cmp.entry.get_documentation"] = true,
			},
			-- Disable hover/signature help to avoid inlay hint conflicts
			hover = { enabled = false },
			signature = { enabled = false },
		},
		presets = {
			bottom_search = true,
			command_palette = true,
			long_message_to_split = true,
			inc_rename = false,
			lsp_doc_border = true,
		},
		routes = {
			-- Suppress inlay hint errors
			{
				filter = {
					event = "msg_show",
					find = "inlayhint.*Invalid.*col",
				},
				opts = { skip = true },
			},
			{
				filter = {
					event = "notify",
					find = "inlayhint",
				},
				opts = { skip = true },
			},
		},
	},
	config = function(_, opts)
		require("noice").setup(opts)
		
		-- Suppress inlay hint decoration provider errors (Neovim bug)
		local original_notify = vim.notify
		vim.notify = function(msg, level, opts)
			if type(msg) == "string" and msg:match("inlayhint") and msg:match("Invalid.*col") then
				return -- Silently ignore inlay hint errors
			end
			return original_notify(msg, level, opts)
		end
	end,
}
