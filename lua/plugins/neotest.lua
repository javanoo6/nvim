-- ./lua/plugins/neotest.lua

-- Testing: stock neotest setup with Java, Go, and Python adapters
local function clear_and_run(run_fn)
	return function(...)
		require("neotest").summary.open()
		require("neotest").output_panel.clear()
		require("neotest").output_panel.open()
		return run_fn(...)
	end
end

return {
	{
		"rcasia/neotest-java",
		ft = "java",
		cmd = { "NeotestJava" },
		dependencies = {
			"nvim-java/nvim-java",
			"mfussenegger/nvim-dap",
		},
	},
	{
		"fredrikaverpil/neotest-golang",
		ft = "go",
		build = function()
			vim.system({ "go", "install", "gotest.tools/gotestsum@latest" }):wait()
		end,
	},
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			"rcasia/neotest-java",           -- Java (Maven/Gradle)
			"fredrikaverpil/neotest-golang", -- Go
			"nvim-neotest/neotest-python", -- Python
		},
		keys = {
			{
				"<leader>tt",
				clear_and_run(function()
					require("neotest").run.run(vim.fn.expand("%"))
				end),
				desc = "Run File",
			},
			{
				"<leader>tT",
				clear_and_run(function()
					require("neotest").run.run(vim.uv.cwd())
				end),
				desc = "Run All Test Files",
			},
			{
				"<leader>tr",
				clear_and_run(function()
					require("neotest").run.run()
				end),
				desc = "Run Nearest",
			},
			{
				"<leader>tl",
				clear_and_run(function()
					require("neotest").run.run_last()
				end),
				desc = "Run Last",
			},
			{
				"<leader>ta",
				function()
					require("neotest").run.attach({ interactive = true })
				end,
				desc = "Attach to Running Test",
			},
			{
				"<leader>ts",
				function()
					require("neotest").summary.toggle()
				end,
				desc = "Toggle Summary",
			},
			{
				"<leader>to",
				function()
					require("neotest").output.open({ enter = true, auto_close = true })
				end,
				desc = "Show Output",
			},
			{
				"<leader>tO",
				function()
					require("neotest").output_panel.toggle()
				end,
				desc = "Toggle Output Panel",
			},
			{
				"<leader>tc",
				function()
					require("neotest").output_panel.clear()
				end,
				desc = "Clear Output Panel",
			},
			{
				"<leader>tS",
				function()
					require("neotest").run.stop({ interactive = true })
				end,
				desc = "Stop (Interactive)",
			},
			{
				"<leader>tw",
				function()
					require("neotest").watch.toggle(vim.fn.expand("%"))
				end,
				desc = "Toggle Watch",
			},
		},
		config = function()
			require("neotest").setup({
				adapters = {
					require("neotest-java")({
						incremental_build = true,
					}),
					require("neotest-golang")({
						runner = "gotestsum",
					}),
					require("neotest-python")({
						dap = { justMyCode = false },
					}),
				},
				status = { virtual_text = true },
				output_panel = {
					open = "botright split | resize 15",
				},
				quickfix = {
					open = function()
						vim.cmd("copen")
					end,
				},
			})
		end,
	},
}
