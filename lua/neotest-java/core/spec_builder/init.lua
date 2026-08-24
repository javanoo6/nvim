local plugin_path = vim.fn.stdpath("data") .. "/lazy/neotest-java/lua/neotest-java/core/spec_builder/init.lua"
local upstream = assert(loadfile(plugin_path))()

local function normalize_java_attach_spec(spec)
  if type(spec) ~= "table" then
    return
  end

  local strategy = spec.strategy
  if type(strategy) ~= "table" or strategy.type ~= "java" or strategy.request ~= "attach" then
    return
  end

  strategy.hostName = strategy.hostName or strategy.host or "localhost"
  strategy.projectName = nil
end

return function(deps)
  local builder = upstream(deps)

  return {
    build_spec = function(args, config)
      local spec = builder.build_spec(args, config)

      if vim.islist(spec) then
        for _, item in ipairs(spec) do
          normalize_java_attach_spec(item)
        end
      else
        normalize_java_attach_spec(spec)
      end

      return spec
    end,
  }
end
