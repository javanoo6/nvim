-- ./lua/plugins/editor.lua

-- Editor: Navigation, file explorer, git integration
return {
  -- LSP-aware file operations (rename file → update imports)
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim",
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },

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
      { "<leader>fR", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
      { "<leader>Hy", "<cmd>YankyRingHistory<cr>", desc = "Yank history" },
      { "<leader>Hc", "<cmd>Telescope command_history<cr>", desc = "Command history" },
      { "<leader>Hs", "<cmd>Telescope search_history<cr>", desc = "Search history" },
      { "<leader>fr", "<cmd>Telescope resume<cr>", desc = "Resume last search" },
      {
        "<leader>fe",
        function()
          vim.ui.input({ prompt = "Extension: " }, function(ext)
            if ext and ext ~= "" then
              require("telescope.builtin").live_grep({
                glob_pattern = "*." .. ext,
                prompt_title = "Grep in *." .. ext,
              })
            end
          end)
        end,
        desc = "Grep by extension",
      },
      { "<leader>:", "<cmd>Telescope command_history<cr>", desc = "Command history" },
      { "<leader>ss", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
      { "<leader>sS", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace symbols" },
    },
    opts = function()
      local actions = require("telescope.actions")
      local previewable_extensions = {
        java = true,
        go = true,
        py = true,
        lua = true,
        ts = true,
        js = true,
        tsx = true,
        jsx = true,
        rs = true,
        c = true,
        cpp = true,
        h = true,
        hpp = true,
        sh = true,
        bash = true,
        zsh = true,
        yaml = true,
        yml = true,
        json = true,
        toml = true,
        md = true,
        sql = true,
        html = true,
        css = true,
        xml = true,
        kt = true,
        swift = true,
        rb = true,
        php = true,
        cs = true,
      }
      return {
        defaults = {
          scroll_strategy = "limit",
          prompt_prefix = " ",
          selection_caret = "  ",
          -- Ignore binary and generated files
          file_ignore_patterns = {
            "%.git/",
            "%.DS_Store$",
            "node_modules/",
            "%.jpg$",
            "%.jpeg$",
            "%.png$",
            "%.gif$",
            "%.webp$",
            "%.ico$",
            "%.svg$",
            "%.mp4$",
            "%.webm$",
            "%.avi$",
            "%.mov$",
            "%.pdf$",
            "%.zip$",
            "%.tar$",
            "%.gz$",
            "%.exe$",
            "%.dll$",
            "%.so$",
            "%.dylib$",
            "%.bin$",
            "%.class$",
            "%.jar$",
            "%.war$",
            "%.ear$",
            "%.o$",
            "%.obj$",
            "%.a$",
            "%.lib$",
            "%.pyc$",
            "__pycache__/",
            "%.min.js$",
            "%.min.css$",
            "dist/",
            "build/",
            "target/",
            "%.lock$",
          },
          preview = {
            filetype_hook = function(filepath, bufnr, opts)
              local ext = filepath:match("%.([^%.]+)$")
              if ext and previewable_extensions[ext] then
                return true
              end
              return false
            end,
          },
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-p>"] = actions.cycle_history_prev,
              ["<esc>"] = actions.close,
              ["<C-d>"] = actions.preview_scrolling_down,
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<Home>"] = actions.move_to_top,
              ["<End>"] = actions.move_to_bottom,
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
            },
          },
        },
      }
    end,
    config = function(_, opts)
      require("telescope").setup(opts)
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
      -- Window picker for choosing which window to open files in
      {
        "s1n7ax/nvim-window-picker",
        version = "2.*",
        config = function()
          require("window-picker").setup({
            filter_rules = {
              include_current_win = false,
              autoselect_one = true,
              -- Filter out floating windows and neo-tree
              bo = {
                filetype = { "neo-tree", "neo-tree-popup", "notify" },
                buftype = { "terminal", "quickfix" },
              },
            },
          })
        end,
      },
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
          require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
        end,
        desc = "Explorer (cwd)",
      },
    },
    opts = {
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "open_current",
        commands = {
          -- Expand node and all single-child descendants
          expand_single_children = function(state)
            local node = state.tree:get_node()
            if node.type ~= "directory" then
              return
            end

            local fs = require("neo-tree.sources.filesystem")
            local renderer = require("neo-tree.ui.renderer")

            local function expand_node(n)
              if n.type ~= "directory" then
                return
              end
              if not n:is_expanded() then
                n:expand()
              end
              fs.navigate(state, state.path, n:get_id(), function()
                local children = state.tree:get_nodes(n:get_id())
                -- Single child that's a directory -> keep expanding
                if #children == 1 and children[1].type == "directory" then
                  expand_node(children[1])
                end
                renderer.redraw(state)
              end)
            end

            expand_node(node)
          end,
          -- Open with window picker
          open_with_window_picker = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            local open = require("neo-tree.utils").open_file

            -- Use window picker to select window
            local ok, window_picker = pcall(require, "window-picker")
            if not ok then
              -- Fallback to default open if window-picker not available
              open(state, path)
              return
            end

            local picked_window_id = window_picker.pick_window({
              include_current_win = false,
            }) or vim.api.nvim_get_current_win()

            -- Set the picked window as current and open file there
            vim.api.nvim_set_current_win(picked_window_id)
            open(state, path)
          end,
          copy_absolute_path = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            vim.fn.setreg("+", path)
            vim.notify("Copied path: " .. path)
          end,
        },
        window = {
          mappings = {
            -- Override default open behavior
            ["<cr>"] = "expand_single_children",
            ["o"] = "open",
            ["s"] = "open_with_window_picker", -- Open with window picker
            ["Y"] = "copy_absolute_path",
            ["<C-v>"] = "open_vsplit",
            ["<C-x>"] = "open_split",
            ["<C-t>"] = "open_tabnew",
          },
        },
      },
      open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
      event_handlers = {
        {
          event = "file_opened",
          handler = function(file_path)
            -- Optional: auto close neo-tree when file opened
            -- require("neo-tree.command").execute({ action = "close" })
          end,
        },
      },
    },
  },

  -- Oil: buffer-based file manager (rename/move/copy by editing text)
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open Oil (parent dir)" },
      {
        "<leader>o",
        function()
          require("oil").open(vim.uv.cwd())
        end,
        desc = "Open Oil (cwd)",
      },
    },
    opts = {
      default_file_explorer = false, -- neo-tree stays as netrw replacement
      columns = { "icon" },
      use_default_keymaps = false,
      keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-v>"] = "actions.select_vsplit",
        ["<C-x>"] = "actions.select_split",
        ["<C-t>"] = "actions.select_tab",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["g."] = "actions.toggle_hidden",
        ["gx"] = "actions.open_external",
        ["<C-r>"] = "actions.refresh",
        ["q"] = "actions.close",
      },
    },
  },

  -- Better escape
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    opts = {},
  },

  -- Lazygit
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>Gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    },
    config = function()
      -- Disable <esc> exiting terminal mode in lazygit
      -- so <esc> works properly in lazygit UI
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "*lazygit*",
        callback = function()
          vim.keymap.set("t", "<esc>", "<esc>", { buffer = true, remap = false })
          -- Use <C-q> to exit terminal mode instead
          vim.keymap.set("t", "<C-q>", "<C-\\><C-n>", { buffer = true, desc = "Exit terminal mode" })
        end,
      })
    end,
  },

  -- Harpoon
  {
    "ThePrimeagen/harpoon",
    branch = "master",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<leader>ha",
        function()
          require("harpoon.mark").add_file()
        end,
        desc = "Add file",
      },
      {
        "<leader>hh",
        function()
          require("harpoon.ui").toggle_quick_menu()
        end,
        desc = "Harpoon menu",
      },
      {
        "<leader>h1",
        function()
          require("harpoon.ui").nav_file(1)
        end,
        desc = "File 1",
      },
      {
        "<leader>h2",
        function()
          require("harpoon.ui").nav_file(2)
        end,
        desc = "File 2",
      },
      {
        "<leader>h3",
        function()
          require("harpoon.ui").nav_file(3)
        end,
        desc = "File 3",
      },
      {
        "<leader>h4",
        function()
          require("harpoon.ui").nav_file(4)
        end,
        desc = "File 4",
      },
    },
    opts = { menu = { width = 120 } },
  },
}
