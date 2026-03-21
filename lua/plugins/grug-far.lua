return {
  "MagicDuck/grug-far.nvim",
  cmd = "GrugFar",
  keys = {
    {
      "<leader>rg",
      function() require("grug-far").open() end,
      desc = "Search & Replace (grug-far)",
    },
    {
      "<leader>rw",
      function() require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } }) end,
      desc = "Replace word under cursor",
      mode = "n",
    },
    {
      "<leader>rg",
      function() require("grug-far").with_visual_selection() end,
      desc = "Search & Replace selection (grug-far)",
      mode = "v",
    },
  },
  opts = {
    headerMaxWidth = 80,
  },
  config = function(_, opts)
    require("grug-far").setup(opts)
    -- Keep grug-far out of the bufferline and add q to close
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "grug-far",
      callback = function(ev)
        vim.bo[ev.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, desc = "Close grug-far" })
      end,
    })
  end,
}
