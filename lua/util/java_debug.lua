local M = {}

function M.debug_main()
  require("util.java_launch").at_cursor(false)
end

function M.attach_remote()
  vim.notify("Remote JVM attach is unavailable: migration Step 6 skipped", vim.log.levels.WARN, { title = "Java" })
end

return M
