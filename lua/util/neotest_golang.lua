local M = {}

function M.create()
  local adapter = require("neotest-golang")({ runner = "gotestsum" })
  -- Upstream falls back to a synchronous recursive scan when no marker exists.
  -- Neotest probes every adapter on buffer entry, including unrelated files.
  adapter.root = function(path)
    return vim.fs.root(path, { "go.work", "go.mod" })
  end
  adapter.is_test_file = function(path)
    if not vim.endswith(path, "_test.go") or vim.fn.executable("go") ~= 1 then
      return false
    end
    -- Bind GOPATH/GOROOT checks to the file's activated test workspace.
    return not require("neotest-golang.lib.goenv").should_skip(path, require("util.neotest_scope").discovery_cwd(path))
  end
  return adapter
end

return M
