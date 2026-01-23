return {
  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    version = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        enabled = vim.fn.executable("make") == 1,
        config = function()
          require("telescope").load_extension("fzf")
        end,
      },
    },
    keys = {
      { "<leader><space>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help" },
      { "<leader>:", "<cmd>Telescope command_history<cr>", desc = "Command history" },
      { "<leader>ss", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
      { "<leader>sS", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace symbols" },
    },
    opts = function()
      local actions = require("telescope.actions")
      return {
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-p>"] = actions.cycle_history_prev,
              ["<esc>"] = actions.close,
            },
          },
        },
      }
    end,
    config = function(_, opts)
      require("telescope").setup(opts)

      -- Set picker for util module
      require("util").picker = require("telescope.builtin")
    end,
  },

  -- File explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = require("util").get_root() })
        end,
        desc = "Explorer (root)",
      },
      {
        "<leader>E",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
        end,
        desc = "Explorer (cwd)",
      },
    },
    opts = {
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "open_current",
      },
    },
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    event = "LazyFile",
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns
        local map = require("util").map

        map("n", "]h", gs.next_hunk, { buffer = buffer, desc = "Next hunk" })
        map("n", "[h", gs.prev_hunk, { buffer = buffer, desc = "Prev hunk" })
        map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", { buffer = buffer, desc = "Stage hunk" })
        map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", { buffer = buffer, desc = "Reset hunk" })
        map("n", "<leader>ghS", gs.stage_buffer, { buffer = buffer, desc = "Stage buffer" })
        map("n", "<leader>ghu", gs.undo_stage_hunk, { buffer = buffer, desc = "Undo stage hunk" })
        map("n", "<leader>ghR", gs.reset_buffer, { buffer = buffer, desc = "Reset buffer" })
        map("n", "<leader>ghp", gs.preview_hunk, { buffer = buffer, desc = "Preview hunk" })
        map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, { buffer = buffer, desc = "Blame line" })
        map("n", "<leader>ghd", gs.diffthis, { buffer = buffer, desc = "Diff this" })
      end,
    },
  },

  -- Better escape
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    opts = {},
  },
}
