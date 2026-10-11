local M = {}

function M.with_project_cwd(adapter)
  local build_spec = adapter.build_spec
  adapter.build_spec = function(args)
    local position = args.tree:data()
    -- Resolve before the builder yields; another test scope may activate meanwhile.
    local cwd = args.cwd or adapter.root(position.path) or (position.type == "dir" and position.path or vim.fs.dirname(position.path))
    local spec = build_spec(args)
    spec.cwd = cwd
    if type(spec.strategy) == "table" then
      spec.strategy.cwd = cwd
    end
    return spec
  end
  return adapter
end

return M
