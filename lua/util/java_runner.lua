local M = {}

function M.run_main()
  require("util.java_launch").at_cursor(true)
end

function M.stop_main()
  require("util.java_launch").stop()
end

function M.toggle_logs()
  local output = require("intellij-lsp.output")
  if output.is_open() then
    output.close()
  else
    output.open()
  end
end

return M
