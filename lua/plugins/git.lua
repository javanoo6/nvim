return {
  -- Inline conflict marker resolution, including accidentally committed markers.
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      default_mappings = false,
      default_commands = true,
      disable_diagnostics = false,
    },
    config = function(_, opts)
      require("git-conflict").setup(opts)

      local group = vim.api.nvim_create_augroup("git_conflict_diagnostics_compat", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "GitConflictDetected",
        callback = function()
          vim.diagnostic.enable(false, { bufnr = vim.api.nvim_get_current_buf() })
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "GitConflictResolved",
        callback = function()
          vim.diagnostic.enable(true, { bufnr = vim.api.nvim_get_current_buf() })
        end,
      })
    end,
  },

  -- Diffview: repo diffs, file history, and merge/rebase conflict resolution
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    opts = function()
      local actions = require("diffview.actions")

      return {
        view = {
          merge_tool = {
            -- Keep the editable merge result at the bottom.
            layout = "diff3_mixed",
            disable_diagnostics = true,
            winbar_info = true,
          },
        },
        hooks = {
          diff_buf_read = function()
            vim.opt_local.wrap = false
          end,
        },
        keymaps = {
          view = {
            { "n", "<leader>co", false },
            { "n", "<leader>ct", false },
            { "n", "<leader>cb", false },
            { "n", "<leader>ca", false },
            { "n", "<leader>cO", false },
            { "n", "<leader>cT", false },
            { "n", "<leader>cB", false },
            { "n", "<leader>cA", false },
            { "n", "<leader>Co", actions.conflict_choose("ours"), { desc = "Conflict: choose ours" } },
            { "n", "<leader>Ct", actions.conflict_choose("theirs"), { desc = "Conflict: choose theirs" } },
            { "n", "<leader>Cb", actions.conflict_choose("all"), { desc = "Conflict: choose both" } },
            { "n", "<leader>CB", actions.conflict_choose("base"), { desc = "Conflict: choose base" } },
            { "n", "<leader>Ca", actions.conflict_choose("all"), { desc = "Conflict: choose all" } },
            { "n", "<leader>C0", actions.conflict_choose("none"), { desc = "Conflict: choose none" } },
            { "n", "<leader>CO", actions.conflict_choose_all("ours"), { desc = "Conflict: choose ours (file)" } },
            { "n", "<leader>CT", actions.conflict_choose_all("theirs"), { desc = "Conflict: choose theirs (file)" } },
            { "n", "<leader>CA", actions.conflict_choose_all("all"), { desc = "Conflict: choose all (file)" } },
          },
          file_panel = {
            { "n", "<leader>cO", false },
            { "n", "<leader>cT", false },
            { "n", "<leader>cB", false },
            { "n", "<leader>cA", false },
            { "n", "<leader>CO", actions.conflict_choose_all("ours"), { desc = "Conflict: choose ours (file)" } },
            { "n", "<leader>CT", actions.conflict_choose_all("theirs"), { desc = "Conflict: choose theirs (file)" } },
            { "n", "<leader>CB", actions.conflict_choose_all("base"), { desc = "Conflict: choose base (file)" } },
            { "n", "<leader>CA", actions.conflict_choose_all("all"), { desc = "Conflict: choose all (file)" } },
            { "n", "<leader>C0", actions.conflict_choose_all("none"), { desc = "Conflict: choose none (file)" } },
          },
        },
      }
    end,
  },

  -- Gitsigns (on_attach keymaps are buffer-local, must stay here)
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local wk = require("which-key")

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map("n", "]h", function()
          if vim.wo.diff then
            return "]h"
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return "<Ignore>"
        end, { expr = true, desc = "Next hunk" })

        map("n", "[h", function()
          if vim.wo.diff then
            return "[h"
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return "<Ignore>"
        end, { expr = true, desc = "Prev hunk" })

        wk.add({
          { "[h", desc = "Prev hunk", buffer = bufnr },
          { "]h", desc = "Next hunk", buffer = bufnr },
          { "<leader>Gh", group = "hunks", buffer = bufnr, mode = { "n", "v" } },
        })

        -- Hunk actions (<leader>Gh* prefix)
        map("n", "<leader>Ghs", gs.stage_hunk, { desc = "Stage hunk" })
        map("n", "<leader>Ghr", gs.reset_hunk, { desc = "Reset hunk" })
        map("v", "<leader>Ghs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "Stage hunk" })
        map("v", "<leader>Ghr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "Reset hunk" })
        map("n", "<leader>GhS", gs.stage_buffer, { desc = "Stage buffer" })
        map("n", "<leader>GhR", gs.reset_buffer, { desc = "Reset buffer" })
        map("n", "<leader>Ghu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
        map("n", "<leader>Ghp", gs.preview_hunk, { desc = "Preview hunk" })
        map("n", "<leader>Ghb", function()
          gs.blame_line({ full = true })
        end, { desc = "Blame line" })
        map("n", "<leader>GhB", gs.toggle_current_line_blame, { desc = "Toggle blame" })
        map("n", "<leader>Ghd", gs.diffthis, { desc = "Diff this" })

        -- Toggles
        map("n", "<leader>Ghw", gs.toggle_word_diff, { desc = "Toggle word diff" })
        map("n", "<leader>Ghl", gs.toggle_linehl, { desc = "Toggle line highlight" })
        map("n", "<leader>Ghv", gs.toggle_deleted, { desc = "Toggle deleted lines" })

        -- Text object
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
      end,
    },
  },
}
