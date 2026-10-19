return {
  "delphinus/md-render.nvim",
  version = "*",
  cmd = "MdRender",
  keys = {
    { "<leader>mt", "<cmd>MdRender toggle<cr>", desc = "Toggle Markdown source/render" },
    { "<leader>ms", "<cmd>vert MdRender split<cr>", desc = "Markdown source/render split" },
    { "<leader>mp", "<cmd>MdRender float<cr>", desc = "Markdown floating preview" },
    { "<leader>md", "<cmd>MdRender demo<cr>", desc = "Markdown render demo" },
  },
  config = function()
    -- Ubuntu may block Puppeteer's downloaded Chrome sandbox. System Chrome
    -- already has a working sandbox; preserve an explicit user override.
    if vim.fn.has("linux") == 1 and not vim.env.PUPPETEER_EXECUTABLE_PATH then
      local chrome = vim.fn.exepath("google-chrome")
      if chrome ~= "" then
        vim.env.PUPPETEER_EXECUTABLE_PATH = chrome
      end
    end
    -- Keep normal terminal text sizing; scaled headings are experimental.
    require("md-render.text_size").setup({ enabled = false })
  end,
}
