-- ./lua/plugins/trouble.lua

-- Trouble.nvim - better diagnostics UI
return {
  "folke/trouble.nvim",
  cmd = { "Trouble" },
  dependencies = "nvim-tree/nvim-web-devicons",
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics_root toggle<cr>", desc = "Diagnostics (root)" },
    { "<leader>xc", "<cmd>Trouble diagnostics_cwd toggle<cr>", desc = "Diagnostics (cwd)" },
    { "<leader>xb", "<cmd>Trouble diagnostics_buffer toggle<cr>", desc = "Diagnostics (buffer)" },
    { "<leader>cs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols" },
    { "<leader>cl", "<cmd>Trouble lsp_calls toggle<cr>", desc = "Call hierarchy" },
    { "<leader>cu", "<cmd>Trouble lsp_usages toggle<cr>", desc = "Usages / references" },
    { "<leader>XL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List" },
    { "<leader>XQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List" },
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
    local util = require("util")

    local function normalize(path)
      if not path or path == "" then
        return nil
      end
      return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
    end

    local function path_has_prefix(path, prefix)
      path = normalize(path)
      prefix = normalize(prefix)
      if not path or not prefix then
        return false
      end
      if path == prefix then
        return true
      end
      local with_sep = prefix:sub(-1) == "/" and prefix or (prefix .. "/")
      return path:sub(1, #with_sep) == with_sep
    end

    local function project_root(filename)
      return filename and util.get_root_from_path(filename) or nil
    end

    local function filter_items_in_path(scope_fn)
      return function(items)
        local scope_root = normalize(scope_fn())
        if not scope_root then
          return items
        end

        return vim.tbl_filter(function(item)
          local filename = item.filename or ""
          if filename == "" then
            return true
          end
          return path_has_prefix(filename, scope_root)
        end, items)
      end
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
        diagnostics_root = {
          desc = "Diagnostics for the current project root",
          mode = "diagnostics",
          filter = filter_items_in_path(function()
            return util.get_root()
          end),
        },
        diagnostics_cwd = {
          desc = "Diagnostics for the current working directory",
          mode = "diagnostics",
          filter = filter_items_in_path(function()
            return vim.uv.cwd()
          end),
        },
        diagnostics_buffer = {
          desc = "Diagnostics for the current buffer",
          mode = "diagnostics",
          filter = { buf = 0 },
        },
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
