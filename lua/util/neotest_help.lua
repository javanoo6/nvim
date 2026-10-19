local M = {}

function M.setup()
  require("util.focus_help").register("neotest", {
    title = "Neotest keys",
    filetypes = { "neotest-summary" },
    matches = function(ft)
      return ft == "neotest-summary"
    end,
    lines = function()
      return {
        " Enter Expand      e Expand all",
        " r Run test        d Debug test",
        " u Stop            i Jump to source",
        " o Output          O Short output",
        " a Attach          w Watch test",
        " m Mark            M Clear marks",
        " R Run marked      D Debug marked",
        " J Next failure    K Previous failure",
        " P Parent          </> Prev/next sibling",
        " t Set target      T Clear target",
        " ? Full help       gH Hide/show popup",
      }
    end,
  })
end

return M
