-- Python virtual environment selection and activation
return {
  {
    "linux-cultist/venv-selector.nvim",
    ft = "python",
    cmd = {
      "VenvSelect",
      "PythonVenvSelect",
      "PythonVenvCreate",
      "PythonVenvRecreate",
      "PythonVenvInstall",
    },
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      {
        "<leader>pe",
        function()
          require("util.python_venv").show_env()
        end,
        desc = "Show project env vars",
      },
      {
        "<leader>ps",
        function()
          require("util.python_venv").select()
        end,
        desc = "Select venv",
      },
      {
        "<leader>pc",
        function()
          require("util.python_venv").prompt_create()
        end,
        desc = "Create venv",
      },
      {
        "<leader>pr",
        function()
          require("util.python_venv").prompt_recreate()
        end,
        desc = "Recreate venv",
      },
      {
        "<leader>pi",
        function()
          require("util.python_venv").install()
        end,
        desc = "Install deps",
      },
      {
        "<leader>pI",
        function()
          require("util.python_venv").prompt_install()
        end,
        desc = "Install packages",
      },
    },
    opts = function()
      local fd_binary = vim.fn.exepath("fd")
      if fd_binary == "" then
        fd_binary = vim.fn.exepath("fdfind")
      end
      if fd_binary == "" then
        fd_binary = "fd"
      end

      return {
        search = {
          managed = {
            command = "$FD '/bin/python$' ~/.local/share/nvim/python-venvs --full-path --color never -a -L",
          },
        },
        options = {
          fd_binary_name = fd_binary,
          notify_user_on_venv_activation = true,
          cached_venv_automatic_activation = true,
          activate_venv_in_terminal = true,
          set_environment_variables = true,
          search_timeout = 5,
          on_venv_activate_callback = function()
            -- DAP keeps Mason's debugpy interpreter; the debuggee uses VIRTUAL_ENV.
            require("util.python_venv").apply_project_env(0)

            -- Restart only the session's selected server with the new interpreter.
            require("util.python_lsp").restart()
          end,
        },
      }
    end,
    config = function(_, opts)
      require("util.python_venv_picker").install()
      require("venv-selector").setup(opts)
      require("util.python_venv").register_commands()
    end,
  },
}
