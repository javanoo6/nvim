return {
  "javanoo6/persist-toggle.nvim",
  lazy = false,
  priority = 1100,
  config = function()
    require("util.toggle_preferences").setup()
  end,
}
