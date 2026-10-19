local M = {}

local function view()
  local lib = package.loaded["diffview.lib"]
  return lib and lib.get_current_view()
end

function M.toggle()
  require("util.focus_help").toggle("diffview")
end

function M.setup()
  require("util.focus_help").register("diffview", {
    title = "Diffview keys",
    matches = function(ft)
      if ft == "DiffviewFiles" or ft == "DiffviewFileHistory" then
        return true
      end
      local current = view()
      return current and current.cur_layout and current.cur_layout:is_focused()
    end,
    lines = function(ft)
      local lines
      if ft == "DiffviewFiles" then
        lines = {
          " Enter/o Open diff  j/k Select file",
          " s/- Stage/unstage  S Stage all",
          " U Unstage all      X Restore file",
          " i List/tree        f Flatten dirs",
          " R Refresh          L Commit log",
          " za Toggle fold     zR/zM All folds",
        }
      elseif ft == "DiffviewFileHistory" then
        lines = {
          " Enter/o Open diff  j/k Select entry",
          " y Copy hash        L Commit details",
          " g! History options",
          " X Restore file to selected revision",
          " za Toggle fold     zR/zM All folds",
        }
      else
        lines = {
          " ]c/[c Next/previous diff hunk",
          " <leader>e Focus file panel",
          " <leader>b Toggle file panel",
          " g Ctrl-x Cycle layout",
        }
      end
      local current = view()
      if current and current.cur_entry and current.cur_entry.kind == "conflicting" then
        vim.list_extend(lines, {
          " ]x/[x Next/previous conflict",
          " <leader>Co/Ct Ours/theirs",
          " <leader>Cb/C0 Both/none (diff pane)",
          " <leader>CO/CT Ours/theirs whole file",
          " <leader>CA Both whole file",
        })
      end
      vim.list_extend(lines, {
        " Tab/Shift-Tab Next/previous file",
        " gf Open source in previous tab",
        " <leader>Gq Close Diffview",
        " g? Full help       gH Hide/show popup",
      })
      return lines
    end,
  })
end

return M
