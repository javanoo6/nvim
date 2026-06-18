-- ./lua/plugins/neotest.lua

-- Testing: stock neotest setup with Java, Go, and Python adapters
local scope = require("util.neotest_scope")

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
      "rcasia/neotest-java", -- Java (Maven/Gradle)
      "fredrikaverpil/neotest-golang", -- Go
      "nvim-neotest/neotest-python", -- Python
    },
    keys = {
      {
        "<leader>tt",
        scope.with_scope(scope.run_current_file),
        desc = "Run File/Package",
      },
      {
        "<leader>tT",
        scope.with_scope(function()
          require("neotest").run.run(scope.focus_root_or_cwd())
        end),
        desc = "Run All Test Files",
      },
      {
        "<leader>tr",
        scope.with_scope(function()
          require("neotest").run.run()
        end),
        desc = "Run Nearest",
      },
      {
        "<leader>td",
        scope.with_scope(function()
          require("neotest").run.run({ strategy = "dap" })
        end),
        desc = "Debug Nearest",
      },
      {
        "<leader>tp",
        scope.with_scope(function(ctx)
          require("neotest").run.run(scope.current_package_target(ctx))
        end),
        desc = "Run Package",
      },
      {
        "<leader>tP",
        scope.with_scope(function(ctx)
          require("neotest").run.run({ scope.current_package_target(ctx), strategy = "dap" })
        end),
        desc = "Debug Package",
      },
      {
        "<leader>tl",
        scope.with_scope(function()
          require("neotest").run.run_last()
        end),
        desc = "Run Last",
      },
      {
        "<leader>tF",
        function()
          require("util.neotest_failed").run_failed()
        end,
        desc = "Run Failed",
      },
      {
        "<leader>tq",
        function()
          require("util.neotest_sequential").run_current_file_tests()
        end,
        desc = "Run File Tests Sequentially",
      },
      {
        "<leader>tL",
        scope.with_scope(function()
          require("neotest").run.run_last({ strategy = "dap" })
        end),
        desc = "Debug Last",
      },
      {
        "<leader>tf",
        scope.with_scope(function(ctx)
          require("neotest").run.run({ ctx.path ~= "" and ctx.path or vim.fn.expand("%"), strategy = "dap" })
        end),
        desc = "Debug File",
      },
      {
        "<leader>tD",
        scope.with_scope(function()
          require("neotest").run.run({ scope.focus_root_or_cwd(), strategy = "dap" })
        end),
        desc = "Debug All Test Files",
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
          scope.activate_scope()
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
        discovery = {
          filter_dir = scope.scoped_discovery_filter,
        },
        adapters = {
          require("neotest-java")({
            incremental_build = true,
          }),
          require("neotest-golang")({
            runner = "gotestsum",
          }),
          require("neotest-python")({
            dap = { justMyCode = false },
            python = function()
              local ok, venv_selector = pcall(require, "venv-selector")
              local python = ok and venv_selector.python() or nil
              if python and python ~= "" then
                return python
              end
              return "python3"
            end,
          }),
        },
        status = { virtual_text = true },
        output_panel = {
          open = "botright split | resize 15",
        },
        quickfix = {
          open = function()
            vim.cmd("botright copen 10")
          end,
        },
      })
    end,
  },
}
