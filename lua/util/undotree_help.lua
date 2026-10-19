local M = {}

function M.setup()
  require("util.focus_help").register("undotree", {
    title = "Undotree keys",
    filetypes = { "undotree" },
    matches = function(ft)
      return ft == "undotree"
    end,
    lines = function()
      return {
        " Enter Restore selected undo state",
        " u Undo            Ctrl-r Redo",
        " J Previous state  K Next state",
        " </> Previous/next saved state",
        " D Toggle diff     T Timestamp style",
        " = Mark diff state M Clear diff mark",
        " C Clear history (confirmation)",
        " Tab Return to editor",
        " j/k Move          q Close",
        " ? Built-in help   gH Hide/show popup",
      }
    end,
  })
end

return M
