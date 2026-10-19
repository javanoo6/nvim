local M = {}

function M.setup()
  require("util.focus_help").register("trouble", {
    title = "Trouble keys",
    filetypes = { "trouble" },
    matches = function(ft)
      return ft == "trouble"
    end,
    lines = function()
      return {
        " Enter Jump        o Jump and close",
        " Ctrl-s Split      Ctrl-v Vsplit",
        " p Preview         P Toggle preview",
        " r Refresh         R Auto-refresh",
        " zo/zc Open/close group",
        " za Toggle group   zR/zM All groups",
        " }/{ Next/previous item",
        " dd Remove item    i Inspect item",
        " j/k Move          q Close",
        " ? Full help       gH Hide/show popup",
      }
    end,
  })
end

return M
