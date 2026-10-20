-- Terminal image placements are outside Neovim's float stacking. Keep them
-- away from Noice's command palette and refresh missed split-scroll events.
local M = {}
local ready = false

function M.setup()
  if ready then
    return
  end
  ready = true
  local image = require("md-render.image")
  local display = require("md-render.display_utils")
  local states = setmetatable({}, { __mode = "k" })
  local blocked = false
  local setup_images = display.setup_images
  display.setup_images = function(...)
    local state = setup_images(...)
    if state then
      states[state] = true
    end
    return state
  end
  local put_image = image.put_image
  image.put_image = function(...)
    if blocked or vim.fn.getcmdtype() ~= "" then
      return
    end
    return put_image(...)
  end

  local group = vim.api.nvim_create_augroup("markdown_image_cmdline", { clear = true })
  local scroll_pending = false
  vim.api.nvim_create_autocmd("WinScrolled", {
    group = group,
    callback = function(ev)
      -- WinScrolled's match names only the FIRST changed window. Split sync
      -- can scroll source and render together; upstream checks only match.
      for state in pairs(states) do
        local win = tostring(state.win)
        if ev.match ~= win and vim.v.event[win] and not scroll_pending then
          scroll_pending = true
          vim.schedule(function()
            scroll_pending = false
            display.announce_repaint("split-scroll")
          end)
          return
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = group,
    callback = function()
      blocked = true
      for state in pairs(states) do
        if vim.api.nvim_win_is_valid(state.win) then
          for _, id in pairs(state.image_ids) do
            image.clear_placements(id)
          end
          for _, anim in pairs(state.anims) do
            local id = anim.frame_ids[anim.current]
            if id then
              image.clear_placements(id)
            end
          end
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    callback = function()
      -- CmdlineLeave runs before leaving command mode; let Noice close first.
      vim.schedule(function()
        blocked = vim.fn.getcmdtype() ~= ""
        if not blocked then
          display.announce_repaint("cmdline")
        end
      end)
    end,
  })
end

return M
