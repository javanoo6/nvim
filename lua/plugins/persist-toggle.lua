return {
  "javanoo6/persist-toggle.nvim",
  lazy = false,
  priority = 10000,
  config = function()
    require("util.preferences").setup()
  end,
}
