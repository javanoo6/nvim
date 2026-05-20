-- ./lua/plugins/projects.lua

return {
  -- Conservative project.nvim setup kept separate from the custom frequent-roots flow.
  {
    "ahmedkhalf/project.nvim",
    event = "VimEnter",
    opts = function()
      return {
        -- Keep project.nvim passive for now; custom <leader>fp uses util.frequent_roots.
        manual_mode = true,
        -- Detection methods: "lsp" (lsp root), "pattern" (git/etc markers)
        detection_methods = { "pattern", "lsp" },
        -- Share the same marker list as util.get_root()
        patterns = require("util").root_patterns,
        -- Show hidden files in project root
        show_hidden = false,
        -- Silent mode
        silent_chdir = true,
        -- Don't change directory automatically
        scope_chdir = "global",
        -- Path to store project history
        datapath = vim.fn.stdpath("data"),
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
