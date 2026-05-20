-- ./lua/plugins/projects.lua

return {
  -- project.nvim is now configured close to its stock behavior.
  {
    "ahmedkhalf/project.nvim",
    event = "VimEnter",
    opts = function()
      return {
        -- Keep this close to project.nvim defaults / conservative usage:
        -- manual_mode = false,
        -- detection_methods = { "lsp", "pattern" },
        -- patterns = require("util").root_patterns,
        -- show_hidden = false,
        -- silent_chdir = true,
        -- scope_chdir = "global",
        -- datapath = vim.fn.stdpath("data"),
      }
    end,
    config = function(_, opts)
      require("project_nvim").setup(opts)
      -- Load the Telescope extension
      require("telescope").load_extension("projects")
    end,
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
  },
}
