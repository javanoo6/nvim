local M = {}

local BUILD_AND_WRAPPER_PATTERNS = {
  "pom.xml",
  "settings.gradle",
  "settings.gradle.kts",
  "build.gradle",
  "build.gradle.kts",
  "mvnw",
  "gradlew",
}

local function default_match_root_pattern(pattern)
  return function(dir)
    local found = vim.fs.find(pattern, {
      path = dir,
      upward = true,
      limit = 1,
    })[1]
    return found and vim.fs.dirname(found) or nil
  end
end

function M.find_root(dir, matcher)
  matcher = matcher or default_match_root_pattern

  local git_root = matcher(".git")(dir)
  if git_root then
    for _, pattern in ipairs(BUILD_AND_WRAPPER_PATTERNS) do
      if matcher(pattern)(git_root) == git_root then
        return git_root
      end
    end
  end

  for _, pattern in ipairs(BUILD_AND_WRAPPER_PATTERNS) do
    local root = matcher(pattern)(dir)
    if root then
      return root
    end
  end

  return nil
end

return M
