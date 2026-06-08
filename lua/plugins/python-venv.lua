-- Python virtual environment selection and activation
return {
  {
    "linux-cultist/venv-selector.nvim",
    ft = "python",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      { "<leader>cV", "<cmd>VenvSelect<cr>", desc = "Select Python venv" },
    },
    opts = {
      search = {
        managed = {
          command = "fd '/bin/python$' ~/.local/share/nvim/python-venvs --full-path --color never -a -L",
        },
      },
      options = {
        notify_user_on_venv_activation = true,
        cached_venv_automatic_activation = true,
        activate_venv_in_terminal = true,
        set_environment_variables = true,
        search_timeout = 5,
        on_venv_activate_callback = function()
          local python = require("venv-selector").python()
          if python and python ~= "" then
            require("dap-python").setup(python)
          end

          -- Pyright/basedpyright read interpreter state on startup, so stop
          -- active Python LSP clients and re-enable them after venv switches.
          local servers = {}
          for _, client in ipairs(vim.lsp.get_clients()) do
            if client.name == "pyright" or client.name == "basedpyright" then
              client:stop(true)
              servers[client.name] = true
            end
          end

          if next(servers) ~= nil then
            vim.defer_fn(function()
              for server_name in pairs(servers) do
                vim.lsp.enable(server_name)
              end
            end, 100)
          end
        end,
      },
    },
  },
}
