local M = {}

function M.close()
  require("util.focus_help").close()
end

function M.toggle()
  require("util.focus_help").toggle("dap")
end

function M.setup()
  require("util.focus_help").register("dap", {
    title = "DAP keys",
    matches = function(ft)
      return ft:match("^dapui_") ~= nil or ft == "dap-repl"
    end,
    lines = function(ft)
      return {
        " e  Evaluate      w  Add watch",
        " c  Continue      p  Pause",
        " n  Step over     s  Step into",
        " o  Step out      t  Terminate",
        " Enter  Expand / select frame",
        " dd Remove watch  E  Edit value/watch",
        " r  Send to REPL  W  Watch variable",
        " O  Open source   T  Toggle thread",
        " Tab Locals / Console   q Close UI",
        " j/k Move         ?  Hide/show help",
        (ft == "dapui_scopes" or ft == "dapui_stacks") and " i  Step into" or " i  Type input    Esc Normal mode",
      }
    end,
  })
end

return M
