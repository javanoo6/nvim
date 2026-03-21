return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "/home/konkov/Obsidian",
      },
    },
    -- Use Telescope for search
    picker = {
      name = "telescope.nvim",
    },
    -- Follow links with gf
    follow_url_func = function(url)
      vim.fn.jobstart({ "xdg-open", url })
    end,
    ui = {
      enable = true,
      checkboxes = {
        [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
        ["x"] = { char = "", hl_group = "ObsidianDone" },
      },
    },
    mappings = {
      -- Follow link under cursor
      ["<CR>"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true, desc = "Follow link" },
      },
      -- Toggle checkbox
      ["<leader>oc"] = {
        action = function()
          return require("obsidian").util.toggle_checkbox()
        end,
        opts = { buffer = true, desc = "Toggle checkbox" },
      },
    },
  },
  keys = {
    { "<leader>on", "<cmd>ObsidianNew<cr>",          desc = "New note" },
    { "<leader>oo", "<cmd>ObsidianOpen<cr>",         desc = "Open in Obsidian" },
    { "<leader>of", "<cmd>ObsidianQuickSwitch<cr>",  desc = "Find note" },
    { "<leader>os", "<cmd>ObsidianSearch<cr>",       desc = "Search notes" },
    { "<leader>ob", "<cmd>ObsidianBacklinks<cr>",    desc = "Backlinks" },
    { "<leader>ol", "<cmd>ObsidianLinks<cr>",        desc = "Links in note" },
    { "<leader>ot", "<cmd>ObsidianTags<cr>",         desc = "Tags" },
    { "<leader>od", "<cmd>ObsidianDailies<cr>",      desc = "Daily notes" },
    { "<leader>or", "<cmd>ObsidianRename<cr>",       desc = "Rename note" },
    { "<leader>op", "<cmd>ObsidianPasteImg<cr>",     desc = "Paste image" },
  },
}
