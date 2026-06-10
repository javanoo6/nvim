-- ./lua/plugins/ui.lua

-- UI: Visual elements - statusline, bufferline, notifications
return {
  -- Icons
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- Which-key
  {
    "folke/which-key.nvim",
    opts = {
      preset = "modern",
      delay = 0,
      plugins = { spelling = true },
      win = {
        border = "rounded",
        padding = { 1, 2 },
        no_overlap = true,
      },
      layout = {
        width = { min = 30, max = 50 },
        height = { min = 4, max = 25 },
        spacing = 1,
        align = "right",
      },
      sort = { "local", "order", "group", "alphanum" },
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.add({
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code", mode = { "n", "v" } },
        { "<leader>C", group = "conflict", mode = { "n", "v" } },
        { "<leader>d", group = "debug", mode = { "n", "v" } },
        { "<leader>dg", group = "debug go" },
        { "<leader>f", group = "file/find" },
        { "<leader>g", group = "go" },
        { "<leader>gi", group = "go insert" },
        { "<leader>gs", group = "go struct tags" },
        { "<leader>G", group = "git", mode = { "n", "v" } },
        { "<leader>Gh", group = "hunks", mode = { "n", "v" } },
        { "<leader>h", group = "harpoon/dirs" },
        { "<leader>H", group = "history" },
        { "<leader>l", group = "lsp" },
        { "<leader>L", group = "leetcode" },
        { "<leader>j", group = "java" },
        { "<leader>o", group = "oil" },
        { "<leader>O", group = "obsidian" },
        { "<leader>p", group = "python" },
        { "<leader>P", group = "plugins" },
        { "<leader>q", group = "quit/session" },
        { "<leader>r", group = "replace", mode = { "n", "v" } },
        { "<leader>s", group = "search" },
        { "<leader>S", group = "sessions" },
        { "<leader>t", group = "test" },
        { "<leader>u", group = "ui" },
        { "<leader>w", group = "windows" },
        { "<leader>x", group = "diagnostics" },
        { "<leader>X", group = "lists/maintenance" },
        { "<leader><tab>", group = "tabs" },
        { "[", group = "prev" },
        { "]", group = "next" },
        { "g", group = "goto/misc" },
        { "gc", group = "line comment", mode = { "n", "v" } },
        { "gcc", desc = "Comment line", mode = "n" },
        { "gb", group = "block comment", mode = { "n", "v" } },
        { "gbc", desc = "Comment block line", mode = "n" },
        { "gs", group = "surround", mode = { "n", "v" } },
        { "z", group = "fold" },
      })
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      local function jdtls_status()
        local bufnr = vim.api.nvim_get_current_buf()
        local client = vim.lsp.get_clients({ bufnr = bufnr, name = "jdtls" })[1]
        if not client or client:is_stopped() then
          return "unavailable"
        end

        if vim.lsp.status() ~= "" then
          return "busy"
        end

        return "ready"
      end

      return {
        options = {
          theme = "auto",
          globalstatus = true,
          component_separators = { left = "|", right = "|" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = {
            {
              "diagnostics",
              symbols = {
                error = "E:",
                warn = "W:",
                info = "I:",
                hint = "H:",
              },
            },
            {
              "filetype",
              icon_only = true,
              separator = "",
              padding = { left = 1, right = 0 },
            },
            { "filename", path = 1, symbols = { modified = "  ", readonly = "", unnamed = "" } },
          },
          lualine_x = {
            {
              function()
                local state = jdtls_status()
                if state == "busy" then
                  return "JDTLS*"
                end
                if state == "unavailable" then
                  return "JDTLS!"
                end
                return "JDTLS"
              end,
              color = function()
                local state = jdtls_status()
                if state == "ready" then
                  return { fg = "#98c379" }
                end
                if state == "busy" then
                  return { fg = "#e5c07b" }
                end
                return { fg = "#e06c75" }
              end,
              cond = function()
                return vim.bo.filetype == "java"
              end,
              padding = { left = 1, right = 0 },
            },
            {
              function()
                return require("util").get_root_basename()
              end,
              icon = " ",
              color = { fg = "#6272a4" },
            },
            {
              function()
                local ok, venv_selector = pcall(require, "venv-selector")
                if not ok then
                  return nil
                end

                local venv = venv_selector.venv()
                if not venv or venv == "" then
                  return "no venv"
                end

                return vim.fs.basename(venv)
              end,
              icon = "󰌠",
              cond = function()
                return vim.bo.filetype == "python"
              end,
              color = { fg = "#e5c07b" },
            },
            {
              "diff",
              symbols = {
                added = "+",
                modified = "~",
                removed = "-",
              },
            },
          },
          lualine_y = {
            { "progress", separator = " ", padding = { left = 1, right = 0 } },
            { "location", padding = { left = 0, right = 1 } },
          },
          lualine_z = {
            function()
              return " " .. os.date("%R")
            end,
          },
        },
        extensions = { "lazy", "neo-tree" },
      }
    end,
  },

  -- Buffer line
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
      { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete other buffers" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete buffers to the right" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete buffers to the left" },
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    },
    opts = {
      highlights = {
        buffer_selected = {
          italic = true,
          bold = false,
          fg = { highlight = "Function", attribute = "fg" },
        },
        separator = {
          fg = { highlight = "Normal", attribute = "bg" },
        },
        separator_selected = {
          fg = { highlight = "Normal", attribute = "bg" },
        },
        separator_visible = {
          fg = { highlight = "Normal", attribute = "bg" },
        },
      },
      options = {
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        separator_style = "slant",
        indicator = { style = "none" },
        color_icons = true,
        offsets = {
          {
            filetype = "neo-tree",
            text = "Neo-tree",
            highlight = "Directory",
            text_align = "left",
          },
        },
      },
    },
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "LazyFile",
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = { enabled = false },
      exclude = {
        filetypes = {
          "help",
          "lazy",
          "mason",
          "notify",
        },
      },
    },
    config = function(_, opts)
      local hooks = require("ibl.hooks")

      hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
      hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_tab_indent_level)

      require("ibl").setup(opts)
    end,
    main = "ibl",
  },

  -- Notifications
  {
    "rcarriga/nvim-notify",
    keys = {
      {
        "<leader>uN",
        function()
          require("notify").dismiss({ silent = true, pending = true })
        end,
        desc = "Dismiss all notifications",
      },
    },
    opts = {
      timeout = 3000,
      background_colour = "#1a1b26", -- tokyonight bg color
      max_height = function()
        return math.floor(vim.o.lines * 0.75)
      end,
      max_width = function()
        return math.floor(vim.o.columns * 0.75)
      end,
    },
  },

  -- Better UI
  {
    "stevearc/dressing.nvim",
    lazy = true,
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.select(...)
      end
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.input = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.input(...)
      end
    end,
  },

  -- Highlight word under cursor and all its occurrences
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      delay = 100,
      -- Treesitter locals currently crashes with the pinned nvim-treesitter build.
      -- Keep LSP-based references and fall back to regex matching instead.
      providers = { "lsp", "regex" },
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = { "lsp" },
      },
    },
    config = function(_, opts)
      require("illuminate").configure(opts)
    end,
  },
}
