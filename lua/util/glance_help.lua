local M = {}

function M.toggle()
  require("util.focus_help").toggle("glance")
end

function M.setup()
  require("util.focus_help").register("glance", {
    title = "Glance keys",
    allow_float = true,
    zindex = 60, -- Glance's list and preview use zindex 45.
    matches = function(ft)
      return ft == "Glance" or vim.wo.winhighlight:find("Normal:GlancePreviewNormal", 1, true) ~= nil
    end,
    lines = function(ft)
      if ft ~= "Glance" then
        return {
          " Tab/Shift-Tab Next/previous location",
          " <leader>l Focus results list",
          " Q Close Glance",
          " gH Hide/show popup",
        }
      end
      return {
        " j/k Next/previous result",
        " Tab/Shift-Tab Next/previous location",
        " Enter Jump        o Preview",
        " v Vsplit          s Split",
        " t Open tab        h/l Close/open fold",
        " Ctrl-u/d Scroll preview up/down",
        " <leader>l Focus source preview",
        " Ctrl-q Send results to quickfix",
        " q/Q/Esc Close     gH Hide/show popup",
      }
    end,
  })
end

return M
