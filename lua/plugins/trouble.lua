-- ./lua/plugins/trouble.lua

-- Trouble.nvim - better diagnostics UI
return {
  "folke/trouble.nvim",
  cmd = { "Trouble" },
  dependencies = "nvim-tree/nvim-web-devicons",
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
    { "<leader>cs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols" },
    { "<leader>cl", "<cmd>Trouble lsp_calls toggle<cr>", desc = "Call hierarchy" },
    { "<leader>cu", "<cmd>Trouble lsp_usages toggle<cr>", desc = "Usages / references" },
    { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List" },
    { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List" },
    {
      "]q",
      function()
        require("trouble").next({ skip_groups = true, jump = true })
      end,
      desc = "Next trouble",
    },
    {
      "[q",
      function()
        require("trouble").prev({ skip_groups = true, jump = true })
      end,
      desc = "Prev trouble",
    },
  },
  opts = function()
    local function is_source_backed_location(item)
      local filename = item.filename or ""
      if filename == "" then
        return true
      end

      return not filename:match("^jdt://")
        and not filename:match("^jar:file://")
        and not filename:match("^zipfile://")
        and not filename:match("%.class$")
    end

    return {
      filters = {
        source_only = function(item, value)
          return not value or is_source_backed_location(item)
        end,
      },
      modes = {
        lsp_calls = {
          desc = "LSP incoming and outgoing calls",
          sections = {
            "lsp_incoming_calls",
            "lsp_outgoing_calls",
          },
          focus = false,
          win = { position = "right" },
          preview = { type = "main", scratch = true },
          filter = {
            source_only = true,
          },
        },
        lsp_usages = {
          mode = "lsp_references",
          desc = "LSP usages and references",
          focus = false,
          win = { position = "right" },
          preview = { type = "main", scratch = true },
          params = {
            include_declaration = false,
          },
          filter = {
            source_only = true,
          },
        },
      },
    }
  end,
}
