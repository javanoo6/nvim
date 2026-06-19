local Path = require("neotest-java.model.path")

--- Local override for upstream neotest-java file_checker.lua.
--- Upstream captures cwd when the adapter is constructed and then asks that
--- stale root whether the current file is a test. In sessions that start
--- outside the Java project, valid src/test/java/*Test.java files can be
--- rejected before position discovery runs.
---
--- Keep this override small: a Java test file is accepted by path shape and
--- configured class-name pattern, without depending on adapter construction cwd.
---@class neotest-java.FileChecker
---@field is_test_file fun(file_path: string): boolean

---@class neotest-java.FileCheckerDependencies
---@field patterns string[]

---@param dependencies neotest-java.FileCheckerDependencies
---@return neotest-java.FileChecker
local FileChecker = function(dependencies)
  return {
    is_test_file = function(file_path)
      local path = Path(file_path)
      local normalized = vim.fs.normalize(file_path)

      if normalized:find("/src/main/", 1, true) then
        return false
      end

      if not normalized:find("/src/test/", 1, true) then
        return false
      end

      local name_without_extension = path:stem()
      for _, re in ipairs(dependencies.patterns or {}) do
        if name_without_extension:match(re) then
          return true
        end
      end

      return false
    end,
  }
end

return FileChecker
