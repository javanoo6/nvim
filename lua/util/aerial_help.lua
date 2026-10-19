local M = {}

function M.setup()
  require("util.focus_help").register("aerial", {
    title = "Aerial keys",
    filetypes = { "aerial" },
    matches = function(ft)
      return ft == "aerial"
    end,
    lines = function()
      return {
        " Enter Jump to symbol (closes outline)",
        " Ctrl-v Vsplit     Ctrl-s Split",
        " p Scroll source to selected symbol",
        " Ctrl-j/k Move down/up and scroll",
        " }/{ Next/previous symbol",
        " ]]/[[ Next/previous parent symbol",
        " o/za Toggle fold  h/l Close/open fold",
        " zR/zM Open/close all folds",
        " j/k Move          q Close outline",
        " ? Full help       gH Hide/show popup",
      }
    end,
  })
end

return M
