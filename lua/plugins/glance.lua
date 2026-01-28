-- ./lua/plugins/glance.lua

-- Glance - beautiful LSP references/definitions preview
-- ./lua/plugins/glance.lua

return {
  {
    "dnlhc/glance.nvim",
    cmd = { "Glance" },
    event = "LspAttach",
    config = function()
      local glance = require("glance")
      local actions = glance.actions

      glance.setup({
        height = 18,
        zindex = 45,
        preserve_win_context = true,

        detached = function(winid)
          return vim.api.nvim_win_get_width(winid) < 100
        end,

        preview_win_opts = {
          cursorline = true,
          number = true,
          wrap = true,
        },

        border = {
          enable = true, -- your preference
          top_char = "―",
          bottom_char = "―",
        },

        list = {
          position = "right",
          width = 0.33,
        },

        theme = {
          enable = true,
          mode = "auto",
        },

        mappings = {
          list = {
            ["j"] = actions.next,
            ["k"] = actions.previous,
            ["<Down>"] = actions.next,
            ["<Up>"] = actions.previous,
            ["<Tab>"] = actions.next_location,
            ["<S-Tab>"] = actions.previous_location,
            ["<C-u>"] = actions.preview_scroll_win(5),
            ["<C-d>"] = actions.preview_scroll_win(-5),
            ["v"] = actions.jump_vsplit,
            ["s"] = actions.jump_split,
            ["t"] = actions.jump_tab,
            ["<CR>"] = actions.jump,
            ['o'] = actions.preview,
            ["l"] = actions.open_fold,
            ["h"] = actions.close_fold,
            ["<leader>l"] = actions.enter_win("preview"),
            ["q"] = actions.close,
            ["Q"] = actions.close,
            ["<Esc>"] = actions.close,
            ["<C-q>"] = actions.quickfix,
          },
          preview = {
            ["Q"] = actions.close,
            ["<Tab>"] = actions.next_location,
            ["<S-Tab>"] = actions.previous_location,
            ["<leader>l"] = actions.enter_win("list"),
          },
        },

        hooks = {
          before_open = function(results, open, jump, method)
            local uri = vim.uri_from_bufnr(0)
            if #results == 1 then
              local target_uri = results[1].uri or results[1].targetUri
              if target_uri == uri then
                jump(results[1])
              else
                open(results)
              end
            else
              open(results)
            end
          end,
        },

        folds = {
          fold_closed = "",
          fold_open = "",
          folded = true,
        },

        indent_lines = {
          enable = true,
          icon = "│",
        },

        winbar = {
          enable = true,
        },

        use_trouble_qf = true, -- your preference
      })
    end,
  },
}
