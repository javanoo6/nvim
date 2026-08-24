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
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "Breakpoint Condition",
      },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
      },
      {
        "<leader>dc",
        function()
          local dap = require("dap")
          local session = dap.session() or select(2, next(dap.sessions()))
          if not session then
            vim.notify("No active DAP session. Use <leader>dl to run the last debug session.", vim.log.levels.INFO, { title = "DAP" })
            return
          end

          dap.set_session(session)
          dap.continue()
        end,
        desc = "Continue",
      },
      {
        "<leader>dC",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "Run to Cursor",
      },
      {
        "<leader>df",
        function()
          local dap = require("dap")
          local session = dap.session()

          if not (session and session.stopped_thread_id) then
            for _, candidate in pairs(dap.sessions()) do
              if candidate.stopped_thread_id then
                session = candidate
                break
              end
            end
          end

          session = session or dap.session() or select(2, next(dap.sessions()))
          if not session then
            vim.notify("No active DAP session. Use <leader>dl to run the last debug session.", vim.log.levels.INFO, { title = "DAP" })
            return
          end

          dap.set_session(session)
          require("dapui").open()
          dap.focus_frame()
        end,
        desc = "Focus Frame",
      },
      {
        "<leader>dg",
        function()
          require("dap").goto_()
        end,
        desc = "Go to line (no execute)",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step Into",
      },
      {
        "<leader>dj",
        function()
          require("dap").down()
        end,
        desc = "Down",
      },
      {
        "<leader>dk",
        function()
          require("dap").up()
        end,
        desc = "Up",
      },
      {
        "<leader>dl",
        function()
          require("dap").run_last()
        end,
        desc = "Run Last",
      },
      {
        "<leader>do",
        function()
          require("dap").step_out()
        end,
        desc = "Step Out",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_over()
        end,
        desc = "Step Over",
      },
      {
        "<leader>dp",
        function()
          require("dap").pause()
        end,
        desc = "Pause",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      {
        "<leader>ds",
        function()
          require("dap").session()
        end,
        desc = "Session",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate",
      },
      {
        "<leader>dw",
        function()
          require("dap.ui.widgets").hover()
        end,
        desc = "Widgets",
      },
      -- Go specific
      {
        "<leader>dgt",
        function()
          require("dap-go").debug_test()
        end,
        desc = "Debug Go Test",
      },
      {
        "<leader>dgl",
        function()
          require("dap-go").debug_last_test()
        end,
        desc = "Debug Last Go Test",
      },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      local dapui_filetypes = {
        ["dap-repl"] = true,
        dapui_breakpoints = true,
        dapui_console = true,
        dapui_scopes = true,
        dapui_stacks = true,
        dapui_watches = true,
      }

      local function is_dapui_window(win)
        local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
        if not ok then
          return false
        end

        return dapui_filetypes[vim.bo[buf].filetype] == true
      end

      local function is_source_window(win)
        local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
        if not ok or is_dapui_window(win) then
          return false
        end

        local source_ok, is_dap_source = pcall(vim.api.nvim_buf_get_var, buf, "dap_source_buf")
        return (source_ok and is_dap_source) or vim.bo[buf].buftype == ""
      end

      dap.defaults.fallback.switchbuf = function(bufnr, line, column)
        if column == 0 then
          column = 1
        end

        local target_win = nil
        local current_win = vim.api.nvim_get_current_win()
        if is_source_window(current_win) then
          target_win = current_win
        end

        if not target_win then
          local previous_win = vim.fn.win_getid(vim.fn.winnr("#"))
          if previous_win ~= 0 and is_source_window(previous_win) then
            target_win = previous_win
          end
        end

        if not target_win then
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if is_source_window(win) then
              target_win = win
              break
            end
          end
        end

        if not target_win then
          if is_dapui_window(current_win) then
            vim.cmd("vsplit")
            target_win = vim.api.nvim_get_current_win()
          else
            target_win = current_win
          end
        end

        vim.api.nvim_set_current_win(target_win)
        vim.api.nvim_win_set_buf(target_win, bufnr)
        pcall(vim.api.nvim_win_set_cursor, target_win, { line, math.max(column - 1, 0) })
      end

      local sensitive_dap_terms = {
        "secret",
        "api_key",
        "apikey",
        "token",
        "password",
        "passwd",
        "credential",
        "authorization",
      }

      local function is_sensitive_dap_value(variable)
        local name = string.lower(tostring(variable.name or ""))
        local value = string.lower(tostring(variable.value or ""))

        for _, term in ipairs(sensitive_dap_terms) do
          if name:find(term, 1, true) or value:find(term, 1, true) then
            return true
          end
        end

        return false
      end

      -- Setup virtual text
      require("nvim-dap-virtual-text").setup({
        display_callback = function(variable)
          if is_sensitive_dap_value(variable) then
            return "***"
          end
          local value = tostring(variable.value or "")
          if #value > 15 then
            return string.sub(value, 1, 15) .. "... "
          end
          return value
        end,
      })

      -- Open/Close dapui automatically
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.after.event_stopped["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        if not vim.g.dapui_keep_open_on_exit then
          dapui.close()
        end
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        if not vim.g.dapui_keep_open_on_exit then
          dapui.close()
        end
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
    config = function()
      require("dapui").setup()
      vim.g.dapui_keep_open_on_exit = vim.g.dapui_keep_open_on_exit or false
    end,
    keys = {
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "Toggle DAP UI",
      },
      {
        "<leader>dU",
        function()
          vim.g.dapui_keep_open_on_exit = not vim.g.dapui_keep_open_on_exit
          local state = vim.g.dapui_keep_open_on_exit and "enabled" or "disabled"
          vim.notify("DAP UI keep-open-on-exit " .. state, vim.log.levels.INFO, { title = "DAP" })
        end,
        desc = "Toggle DAP UI keep-open",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval()
        end,
        desc = "Eval",
        mode = { "n", "v" },
      },
    },
  },
}
