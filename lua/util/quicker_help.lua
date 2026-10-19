local M = {}

function M.setup()
  require("util.focus_help").register("quicker", {
    title = "Quickfix / Quicker keys",
    filetypes = { "qf" },
    matches = function(ft)
      return ft == "qf"
    end,
    lines = function()
      local location_list = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].loclist == 1
      return {
        " Enter Jump to result",
        " Ctrl-w Enter Open result in split",
        " > Expand context  < Collapse context",
        " i Edit result text",
        " :w Apply edits to source buffers",
        location_list and " :lnext/:lprev Next/previous result" or " :cnext/:cprev Next/previous result",
        location_list and " :lolder/:lnewer List history" or " :colder/:cnewer List history",
        " j/k Move          q Close list",
        " gH Hide/show popup",
      }
    end,
  })
end

return M
