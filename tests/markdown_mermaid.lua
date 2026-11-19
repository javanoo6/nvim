-- Real renderer, mapping dispatch, and disposable preference state.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)
for _, name in ipairs({ "md-render.nvim", "persist-toggle.nvim", "which-key.nvim" }) do
  vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/" .. name)
end
vim.o.columns = 240
vim.g.mapleader = " "
vim.notify = function() end
local state_path = vim.fn.tempname()
local ordinary_path = state_path .. ".png"
vim.fn.writefile({ "fixture" }, ordinary_path)
local prefs = require("util.preferences")
prefs.setup({ path = state_path, notify = false })
require("util.input").setup()
local image = require("md-render.image")
local preview = require("md-render").preview
image._set_kitty_supported(true)
image._test_cell_size = { cell_w = 10, cell_h = 20 }
local width, height = 2400, 1000
local cache = vim.fn.stdpath("cache") .. "/md-render/mermaid/fixture.png"
image.get_mermaid_cached = function()
  return cache
end
image.has_mmdc = function()
  return true
end
image.image_dimensions = function()
  return width, height
end
-- No terminal graphics or external processes in this regression.
image.transmit_image_async = function(_, callback)
  callback(nil)
end
local mermaid = require("util.markdown_mermaid")
mermaid.setup()
mermaid.setup()
vim.cmd("runtime plugin/md-render.lua")
for _, key in ipairs(require("plugins.markdown").keys) do
  vim.keymap.set("n", key[1], key[2], { desc = key.desc })
end
vim.keymap.set("n", " ", "<Nop>")
local wk = require("plugins.ui")[2]
wk.config(nil, wk.opts)
vim.api.nvim_open_win(vim.api.nvim_create_buf(true, false), true, { relative = "editor", row = 0, col = 0, width = 220, height = 20 })
local checks = 0
local function check(condition, message)
  assert(condition, message)
  checks = checks + 1
end
local function press(keys)
  vim.wait(100, function()
    return false
  end)
  vim.api.nvim_feedkeys(vim.keycode(keys), "xt", false)
  vim.wait(50, function()
    return false
  end)
end
local lines = { "```mermaid", "graph LR; A-->B", "```", "after diagram" }
local function placement()
  return preview.build_content(lines, { max_width = 80 }).image_placements[1]
end
local ok, err = xpcall(function()
  local ordinary = { "![ordinary](" .. ordinary_path .. ")" }
  local before = preview.build_content(ordinary, { max_width = 80 }).image_placements[1]
  check(before ~= nil, "Ordinary image fixture renders")
  check(placement().cols == 78, "Default width")
  press(" mmw+")
  check(prefs.get("mermaid_width") == 83 and placement().cols == 83, "English width increases image")
  press(" ььц-")
  check(prefs.get("mermaid_width") == 78 and placement().cols == 78, "Russian width decreases image")
  width, height = 1200, 2400
  check(placement().rows == 25, "Default height")
  press(" mmh+")
  check(prefs.get("mermaid_height") == 30 and placement().rows == 30, "English height increases image")
  press(" ььр-")
  check(prefs.get("mermaid_height") == 25 and placement().rows == 25, "Russian height decreases image")
  press(" ььц+")
  press(" mmw-")
  press(" ььр+")
  press(" mmh-")
  check(prefs.get("mermaid_width") == 78 and prefs.get("mermaid_height") == 25, "All eight layout/action combinations")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = "markdown"
  preview.toggle()
  local session = preview._sessions[vim.api.nvim_get_current_buf()]
  mermaid.adjust("height", 1)
  check(session.content.image_placements[1].rows == 30, "Open preview rebuilds immediately")
  preview.toggle()
  mermaid.adjust("height", 1)
  check(session.dirty, "Hidden preview invalidated")
  preview.toggle()
  check(session.content.image_placements[1].rows == 35, "Reopened preview uses saved size")
  local saved = vim.json.decode(table.concat(vim.fn.readfile(state_path), "\n"))
  check(saved.values.mermaid_height == 35, "Numeric height written through persist-toggle")
  prefs.set("mermaid_width", 500)
  prefs.set("mermaid_height", 300)
  width, height = 2400, 1000
  local after = preview.build_content(ordinary, { max_width = 80 }).image_placements[1]
  check(after.cols == before.cols and after.rows == before.rows, "Ordinary images keep upstream limits")
  width, height = 24000, 1000
  check(placement().cols <= vim.api.nvim_win_get_width(0) - 2, "Width fits actual window")
  local dimensions, size = image.image_dimensions, image.calc_display_size
  check(not pcall(preview.build_content, nil), "Builder error propagates")
  check(image.image_dimensions == dimensions and image.calc_display_size == size, "Error restores hooks")
end, debug.traceback)
vim.fn.delete(state_path)
vim.fn.delete(ordinary_path)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit 1")
end
print("PASS: " .. checks .. " Mermaid sizing checks")
vim.cmd("qa!")
