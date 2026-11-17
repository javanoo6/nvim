local M = {}

function M.setup(normalizer)
  -- getcharstr() bypasses mappings/langmap while which-key owns input.
  local state = require("which-key.state")
  if state._input_normalizer then
    return
  end
  local getchar = state.getchar
  state.getchar = function()
    local ok, key = getchar()
    return ok, ok and normalizer.normalize(key) or key
  end
  state._input_normalizer = true
end

return M
