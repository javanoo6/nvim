return {
  {
    "LintaoAmons/scratch.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      { "<leader>fs", "<cmd>Scratch<cr>", desc = "Scratch" },
      { "<leader>fS", "<cmd>ScratchOpen<cr>", desc = "Scratch list" },
      { "<leader>fN", "<cmd>ScratchWithName<cr>", desc = "Scratch with name" },
    },
    config = function()
      require("scratch").setup({
        filetypes = { "lua", "js", "py", "sh", "java" },
        scratch_file_dir = vim.fn.stdpath("state") .. "/scratch",
        window_cmd = "edit",
        file_picker = "telescope",
      })
    end,
  },
}
