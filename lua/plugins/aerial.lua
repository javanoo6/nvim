-- ./lua/plugins/aerial.lua

-- Aerial - code outline sidebar for symbols in the current buffer
return {
  "stevearc/aerial.nvim",
  cmd = { "AerialToggle", "AerialOpen", "AerialClose", "AerialNavToggle" },
  keys = {
    { "<leader>co", "<cmd>AerialToggle left<cr>", desc = "Code outline" },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  opts = function()
    return {
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = {
        default_direction = "left",
        min_width = 30,
        width = 36,
      },
      attach_mode = "window",
      close_on_select = true,
      show_guides = true,
      icons = require("util").icons.kinds,
      filter_kind = false,
    }
  end,
}
