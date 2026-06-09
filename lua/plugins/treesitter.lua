-- ./lua/plugins/treesitter.lua

-- Treesitter: Syntax highlighting and code understanding
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local treesitter = require("nvim-treesitter")
      local languages = {
        "bash",
        "c",
        "go",
        "gomod",
        "gowork",
        "gotmpl",
        "helm",
        "html",
        "java",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "vim",
        "vimdoc",
        "yaml",
        "xml",
        "groovy",
        "kotlin",
      }
      local disable_indent = {
        markdown = true,
        yaml = true,
      }

      treesitter.setup()
      local installed = {}
      for _, lang in ipairs(treesitter.get_installed("parsers")) do
        installed[lang] = true
      end

      local missing = vim.tbl_filter(function(lang)
        return not installed[lang]
      end, languages)
      if #missing > 0 then
        treesitter.install(missing)
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("custom_treesitter", { clear = true }),
        pattern = languages,
        callback = function()
          vim.treesitter.start()
          if not disable_indent[vim.bo.filetype] then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      require("nvim-treesitter-textobjects").setup({
        textobjects = {
          select = {
            lookahead = true,
            -- Keymaps are defined in lua/config/keymaps.lua for Which-key visibility
          },
          move = {
            set_jumps = true,
            -- Keymaps are defined in lua/config/keymaps.lua for Which-key visibility
          },
        },
      })
    end,
  },

  -- Rainbow delimiters
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "LazyFile",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      local rainbow_delimiters = require("rainbow-delimiters")
      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = rainbow_delimiters.strategy["global"],
        },
        query = {
          [""] = "rainbow-delimiters",
        },
        priority = {
          [""] = 110,
        },
        highlight = {
          "RainbowDelimiterRed",
          "RainbowDelimiterYellow",
          "RainbowDelimiterBlue",
          "RainbowDelimiterOrange",
          "RainbowDelimiterGreen",
          "RainbowDelimiterViolet",
          "RainbowDelimiterCyan",
        },
      }
    end,
  },
}
