-- Run: nvim --headless -u NONE -i NONE -l tests/markdown_images.lua
-- Capture real Kitty placement sequences without needing a graphical terminal.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/md-render.nvim")
local image = require("md-render.image")
local display = require("md-render.display_utils")
local output = {}
vim.api.nvim_ui_send = function(data)
  output[#output + 1] = data
end
image._set_kitty_supported(true)
require("util.markdown_images").setup()
require("util.markdown_images").setup()
local checks = 0
local function check(condition, message)
  assert(condition, message)
  checks = checks + 1
end
local function captured()
  local text = table.concat(output)
  output = {}
  return text
end

local function run()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn["repeat"]({ "                    " }, 30))
  local win = vim.api.nvim_open_win(buf, true, { relative = "editor", row = 1, col = 1, width = 20, height = 10 })
  -- Off-screen placement avoids downloads while creating a real image state.
  local state = display.setup_images(win, { image_placements = { { line = 999, rows = 2 } } }, 0)
  state.image_ids.example = 101
  state.anims.example = { frame_ids = { 102, 103 }, current = 2 }
  captured()
  image.put_image(101, win, 0, 0, 5, 2)
  check(captured():find("a=p", 1, true), "Normal placement should work")
  vim.api.nvim_exec_autocmds("CmdlineEnter", { pattern = ":" })
  local cleared = captured()
  check(cleared:find("a=d,d=a,i=101", 1, true), "Static placement must be cleared")
  check(cleared:find("a=d,d=a,i=103", 1, true), "Active animation placement must be cleared")
  check(not cleared:find("d=A", 1, true), "Transmitted image data must be retained")
  image.put_image(101, win, 0, 0, 5, 2)
  check(captured() == "", "Delayed placement must be blocked during command entry")
  local restored = 0
  vim.api.nvim_create_autocmd("User", {
    pattern = display.REPAINT_EVENT,
    callback = function(ev)
      if ev.data.source == "cmdline" then
        restored = restored + 1
      end
    end,
  })
  vim.api.nvim_exec_autocmds("CmdlineLeave", { pattern = ":" })
  check(
    vim.wait(1000, function()
      return restored > 0
    end),
    "Exit must request a repaint"
  )
  check(restored == 1, "Setup must be idempotent")
  captured()
  image.put_image(101, win, 0, 0, 5, 2)
  check(captured():find("a=p", 1, true), "Placement must resume after command exit")
  state.anims = {}
  display.cleanup_images(state)
  vim.api.nvim_win_close(win, true)
end
local ok, err = pcall(run)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
print("PASS: " .. checks .. " Markdown image command-line checks")
vim.cmd("qa!")
