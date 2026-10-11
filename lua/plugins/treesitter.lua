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
        "css",
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
        "python",
        "query",
        "ruby",
        "sql",
        "toml",
        "tsx",
        "typescript",
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
      local supported_languages = {}
      for _, language in ipairs(languages) do
        supported_languages[language] = true
      end
      local warned_start_failures = {}

      local function start_treesitter(bufnr)
        local filetype = vim.bo[bufnr].filetype
        local language = vim.treesitter.language.get_lang(filetype)
        if not language or not supported_languages[language] then
          return
        end
        -- Missing parsers during installation and unsupported buffers are quiet.
        local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, language, { error = false })
        if not parser_ok or not parser then
          return
        end

        local ok, err = pcall(vim.treesitter.start, bufnr, language)
        if ok then
          return language
        end

        if not warned_start_failures[filetype] then
          warned_start_failures[filetype] = true
          vim.notify(string.format("Treesitter disabled for %s: %s", filetype, err), vim.log.levels.WARN, { title = "Treesitter" })
        end
      end

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
        callback = function(event)
          local language = start_treesitter(event.buf)
          if not language then
            return
          end

          if not disable_indent[language] then
            vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
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
        select = {
          lookahead = true,
          -- Keymaps are defined in lua/config/keymaps.lua for Which-key visibility
        },
        move = {
          set_jumps = true,
          -- Keymaps are defined in lua/config/keymaps.lua for Which-key visibility
        },
      })
    end,
  },

  -- Rainbow delimiters
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "FileType",
    dependencies = "nvim-treesitter/nvim-treesitter",
  },
}
