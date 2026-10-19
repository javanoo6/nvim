local M = {}

function M.setup()
  local help = require("util.focus_help")
  help.register("neo-tree", {
    title = "Neo-tree keys",
    matches = function(ft)
      return ft == "neo-tree"
    end,
    lines = function()
      return {
        " Enter Smart open   o Open",
        " a New file         A New directory",
        " r Rename           d Delete",
        " y Copy   x Cut      p Paste",
        " c Copy to path     m Move to path",
        " Y Copy absolute path",
        " Ctrl-v/x/t Vertical/horz/tab open",
        " s Pick window      P Preview",
        " l Focus preview    C Close node",
        " z Collapse all     R Refresh",
        " / Find file        H Hidden files",
        " Backspace Parent   . Set scope root",
        " j/k Move           q/Esc Close",
        " ? Full help        gH Hide/show popup",
      }
    end,
  })
  help.register("oil", {
    title = "Oil keys",
    matches = function(ft)
      return ft == "oil"
    end,
    lines = function()
      return {
        " Enter Open file/directory",
        " Ctrl-v Vertical split",
        " Ctrl-x Horizontal split",
        " Ctrl-t Open in tab",
        " - Parent           _ Editor cwd",
        " g. Hidden files    gx External open",
        " Ctrl-r Refresh     q Close",
        " i Edit names       dd Delete line",
        " Edit text to rename/move/copy/create",
        " :w Review and apply file changes",
        " j/k Move           Esc Normal mode",
        " g? Full help       gH Hide/show popup",
      }
    end,
  })
end

return M
