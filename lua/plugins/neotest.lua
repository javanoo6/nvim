-- ./lua/plugins/neotest.lua

-- Testing: neotest with Java, Go, Python adapters
return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"antoinemadec/FixCursorHold.nvim",
			-- Adapters
			"rcasia/neotest-java", -- Java (Maven/Gradle)
			"nvim-neotest/neotest-go", -- Go
			"nvim-neotest/neotest-python", -- Python
		},
		keys = {
			{ "<leader>tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File" },
			{ "<leader>tT", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run All Test Files" },
			{ "<leader>tr", function() require("neotest").run.run() end, desc = "Run Nearest" },
			{ "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run Last" },
			{ "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary" },
			{ "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output" },
			{ "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel" },
			{ "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop" },
			{ "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle Watch" },
		},
		config = function()
			local neotest = require("neotest")
			neotest.setup({
				adapters = {
					require("neotest-java"),
					require("neotest-go"),
					require("neotest-python"),
				},
				status = { virtual_text = true },
				output = { open_on_run = true },
				quickfix = {
					open = function()
						vim.cmd("copen")
					end,
				},
			})
		end,
	},
}
