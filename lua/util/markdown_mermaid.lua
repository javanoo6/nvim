-- Mermaid-only size limits. Keep upstream's aspect ratio and layout bookkeeping.
local M = {}
local ready = false
local limits = {
  width = { id = "mermaid_width", default = 78, step = 5, min = 10, max = 500 },
  height = { id = "mermaid_height", default = 25, step = 5, min = 5, max = 300 },
}

local function value(axis)
  local limit = limits[axis]
  local saved = require("persist-toggle").get(limit.id)
  if type(saved) ~= "number" or saved ~= saved then
    return limit.default
  end
  return math.floor(math.max(limit.min, math.min(limit.max, saved)))
end

function M.refresh()
  local renderer = package.loaded["md-render"]
  if ready and renderer then
    for _, session in pairs(renderer.preview._sessions) do
      session.dirty = true
    end
    renderer.preview.rebuild_visible()
  end
end

function M.adjust(axis, direction)
  local limit = assert(limits[axis], "Unknown Mermaid dimension")
  local next_value = math.max(limit.min, math.min(limit.max, value(axis) + direction * limit.step))
  require("util.preferences").set(limit.id, next_value)
  vim.notify(("Mermaid limits: %d columns × %d rows (saved)"):format(value("width"), value("height")))
end

function M.setup()
  if ready then
    return
  end
  ready = true
  local preview = require("md-render").preview
  local image = require("md-render.image")
  local build = preview.build_content
  local cache_dir = vim.fn.stdpath("cache") .. "/md-render/mermaid/"
  preview.build_content = function(lines, opts)
    -- Rebuilds can run while focus is on the source or another document.
    local win = vim.api.nvim_get_current_win()
    for _, session in pairs(preview._sessions) do
      if session.opts == opts and session.win and vim.api.nvim_win_is_valid(session.win) then
        win = session.win
        break
      end
    end
    local available = math.max(1, vim.api.nvim_win_get_width(win) - vim.fn.getwininfo(win)[1].textoff - 2)
    local dimensions, size = image.image_dimensions, image.calc_display_size
    local mermaid = false
    -- The builder reads dimensions immediately before sizing a cached image.
    -- Scope these hooks to the synchronous build and always restore on errors.
    -- Ordinary images and PlantUML retain their original size limits.
    image.image_dimensions = function(path)
      mermaid = type(path) == "string" and path:sub(1, #cache_dir) == cache_dir
      return dimensions(path)
    end
    image.calc_display_size = function(w, h, cols, rows)
      local is_mermaid = mermaid
      mermaid = false
      if is_mermaid then
        cols, rows = math.min(value("width"), available), value("height")
      end
      return size(w, h, cols, rows)
    end
    local ok, content = pcall(build, lines, opts)
    image.image_dimensions, image.calc_display_size = dimensions, size
    if not ok then
      error(content, 0)
    end
    return content
  end
end

return M
