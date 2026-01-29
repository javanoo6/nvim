-- ./lua/plugins/dap.lua

-- Debugging: nvim-dap and adapters for Java, Go, Python
return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
			"nvim-neotest/nvim-nio",
			-- Java debug adapter (via nvim-java)
			-- Go debug adapter
			"leoluz/nvim-dap-go",
			-- Python debug adapter
			"mfussenegger/nvim-dap-python",
		},
		keys = {
			{ "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Breakpoint Condition" },
			{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
			{ "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
			{ "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
			{ "<leader>dg", function() require("dap").goto_() end, desc = "Go to line (no execute)" },
			{ "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
			{ "<leader>dj", function() require("dap").down() end, desc = "Down" },
			{ "<leader>dk", function() require("dap").up() end, desc = "Up" },
			{ "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
			{ "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
			{ "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
			{ "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
			{ "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
			{ "<leader>ds", function() require("dap").session() end, desc = "Session" },
			{ "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
			{ "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- Setup dap-ui
			dapui.setup()

			-- Setup virtual text
			require("nvim-dap-virtual-text").setup({
				display_callback = function(variable)
					local name = string.lower(variable.name)
					local value = string.lower(variable.value)
					if name:match("secret") or name:match("api_key") or value:match("secret") or value:match("api_key") then
						return "***"
					end
					if #variable.value > 15 then
						return string.sub(variable.value, 1, 15) .. "... "
					end
					return variable.value
				end,
			})

			-- Open/Close dapui automatically
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- Setup Go adapter
			require("dap-go").setup()

			-- Setup Python adapter
			require("dap-python").setup("python3")

			-- Java debug adapter is handled by nvim-java
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "nvim-neotest/nvim-nio" },
		keys = {
			{ "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
			{ "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "v" } },
		},
	},
}
