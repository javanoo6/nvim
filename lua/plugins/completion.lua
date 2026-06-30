-- ./lua/plugins/completion.lua

-- Completion: nvim-cmp and snippet configuration
return {
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        build = "make install_jsregexp",
        dependencies = {
          {
            "rafamadriz/friendly-snippets",
            config = function()
              require("luasnip.loaders.from_vscode").lazy_load()
            end,
          },
        },
      },
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",

      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")
      local snippet = luasnip.snippet
      local text_node = luasnip.text_node
      local insert_node = luasnip.insert_node

      local function patch_cmp_buffer_index_range()
        local ok, cmp_buffer = pcall(require, "cmp_buffer.buffer")
        if not ok or cmp_buffer.__custom_index_range_bounds_patch then
          return
        end

        cmp_buffer.__custom_index_range_bounds_patch = true
        cmp_buffer.index_range = function(self, range_start, range_end, skip_already_indexed)
          if self.closed or not vim.api.nvim_buf_is_valid(self.bufnr) or not vim.api.nvim_buf_is_loaded(self.bufnr) then
            return
          end

          self:safe_buf_call(function()
            if self.closed or not vim.api.nvim_buf_is_valid(self.bufnr) or not vim.api.nvim_buf_is_loaded(self.bufnr) then
              return
            end

            local line_count = vim.api.nvim_buf_line_count(self.bufnr)
            local chunk_size = self.GET_LINES_CHUNK_SIZE
            local chunk_start = math.max(0, math.min(range_start, line_count))
            local bounded_end = math.max(chunk_start, math.min(range_end, line_count))

            while chunk_start < bounded_end do
              local chunk_end = math.min(chunk_start + chunk_size, bounded_end)
              local lines_ok, chunk_lines = pcall(vim.api.nvim_buf_get_lines, self.bufnr, chunk_start, chunk_end, false)
              if not lines_ok then
                return
              end

              for i, line in ipairs(chunk_lines) do
                if not skip_already_indexed or not self.lines_words[chunk_start + i] then
                  self:index_line(chunk_start + i, line)
                end
              end
              chunk_start = chunk_end
            end
          end)
        end
      end

      patch_cmp_buffer_index_range()

      local function buffer_source(keyword_length)
        return {
          name = "buffer",
          keyword_length = keyword_length or 4,
          option = {
            get_bufnrs = function()
              local bufs = {}
              for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(bufnr) then
                  local byte_size = vim.api.nvim_buf_get_offset(bufnr, vim.api.nvim_buf_line_count(bufnr))
                  if byte_size <= 512 * 1024 then
                    bufs[#bufs + 1] = bufnr
                  end
                end
              end
              return bufs
            end,
          },
        }
      end

      luasnip.add_snippets("java", {
        snippet("main", {
          text_node({
            "class Scratch {",
            "\tpublic static void main(String[] args) {",
            "\t\t",
          }),
          insert_node(1),
          text_node({ "", "\t}", "}" }),
        }),
      })

      luasnip.add_snippets("go", {
        snippet("main", {
          text_node({
            "func main() {",
            "\t",
          }),
          insert_node(1),
          text_node({ "", "}" }),
        }),
      })

      luasnip.add_snippets("python", {
        snippet("main", {
          text_node({
            'if __name__ == "__main__":',
            "    ",
          }),
          insert_node(1, "main()"),
        }),
      })

      local cmdline_mapping = cmp.mapping.preset.cmdline({
        ["<Down>"] = {
          c = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
        },
        ["<Up>"] = {
          c = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
        },
        ["<CR>"] = {
          c = cmp.mapping.confirm({ select = false }),
        },
      })

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "nvim_lsp_signature_help" },
          { name = "luasnip" },
          { name = "path" },
          buffer_source(),
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "...",
            show_labelDetails = true,
          }),
        },
        sorting = {
          comparators = {
            cmp.config.compare.offset,
            cmp.config.compare.exact,
            cmp.config.compare.score,
            cmp.config.compare.recently_used,
            cmp.config.compare.locality,
            cmp.config.compare.kind,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
          },
        },
        experimental = {
          ghost_text = { hl_group = "CmpGhostText" },
        },
      })

      cmp.setup.filetype({ "markdown", "text", "gitcommit" }, {
        sources = cmp.config.sources({
          { name = "path" },
          { name = "luasnip" },
        }, {
          buffer_source(4),
        }),
      })

      cmp.setup.filetype({ "sh", "bash", "zsh", "yaml", "yaml.helm-values" }, {
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "path" },
          { name = "luasnip" },
        }, {
          buffer_source(4),
        }),
      })

      cmp.setup.filetype("python", {
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "nvim_lsp_signature_help" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          buffer_source(4),
        }),
      })

      -- Command line completion uses nvim-cmp's preset cmdline mappings.
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmdline_mapping,
        sources = { { name = "buffer" } },
      })

      cmp.setup.cmdline(":", {
        mapping = cmdline_mapping,
        sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
      })
    end,
  },
}
