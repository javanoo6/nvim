return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
        opts = {
          layouts = {
            {
              elements = {
                { id = "scopes", size = 0.50 },
                { id = "stacks", size = 0.30 },
                { id = "watches", size = 0.10 },
                { id = "breakpoints", size = 0.10 },
              },
              size = 40,
              position = "left",
            },
            {
              elements = { "repl", "console" },
              size = 10,
              position = "bottom",
            },
          },
        },
        config = function(_, opts)
          local dap = require("dap")
          local dapui = require("dapui")
          dapui.setup(opts)

          dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
          end
        end,
      },
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = { commented = true },
      },
    },
    keys = {
      { "<leader>bb", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
      { "<leader>dj", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dk", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
    },
    config = function()
      local dap = require("dap")

      -- Java DAP
      dap.configurations.java = {
        {
          name = "Debug (Attach) - Remote",
          type = "java",
          request = "attach",
          hostName = "127.0.0.1",
          port = 5005,
        },
        {
          name = "Debug Launch (2GB)",
          type = "java",
          request = "launch",
          vmArgs = "-Xmx2g",
        },
      }

      -- Signs
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn" })
    end,
  },
}
