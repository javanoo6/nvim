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
    local root_markers = { ".git", "pom.xml", "build.gradle", "settings.gradle", "mvnw", "gradlew" }

    local function project_root(filename)
      return filename and vim.fs.root(filename, root_markers) or nil
    end

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
        project_only = function(item, value, ctx)
          if not value then
            return true
          end

          local filename = item.filename or ""
          local main = ctx.main and ctx.main.filename or nil
          local root = project_root(main)
          if not root or filename == "" then
            return true
          end

          return filename:sub(1, #root) == root
        end,
        java_usage_relevant = function(item, value)
          if not value then
            return true
          end

          local filename = item.filename or ""
          local text = vim.trim(item.text or "")
          if filename:match("/package%-info%.java$") then
            return false
          end

          if text:match("^import%s+") or text:match("^package%s+") then
            return false
          end

          return true
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
            project_only = true,
            java_usage_relevant = true,
          },
        },
        lsp_usages = {
          desc = "LSP usages and references",
          sections = {
            "lsp_references",
            "lsp_implementations",
          },
          focus = false,
          win = {
            relative = "win",
            position = "right",
            size = { width = 0.5 },
          },
          preview = { type = "main", scratch = true },
          params = {
            include_declaration = false,
            include_current = false,
          },
          filter = {
            source_only = true,
            project_only = true,
            java_usage_relevant = true,
          },
        },
      },
    }
  end,
}
