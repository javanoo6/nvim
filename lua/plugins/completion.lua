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
          { name = "buffer" },
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
