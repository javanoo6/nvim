-- ./lua/config/autocmds.lua

local util = require("util")
local augroup = util.augroup
require("util.ui_debug").register_commands()
require("util.explorer_help").setup()
require("util.neotest_help").setup()
require("util.diffview_help").setup()
require("util.trouble_help").setup()
require("util.glance_help").setup()

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Resize splits on window resize
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- Close certain filetypes with q
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "help",
    "lspinfo",
    "checkhealth",
    "qf",
    "notify",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Go to last location when opening buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc then
      return
    end
    vim.b[buf].last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Check if file needs reload
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Wrap and spell for text files
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "text", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = require("util.preferences").option_value("wrap")
    vim.opt_local.spell = require("util.preferences").option_value("spell")
  end,
})

local function refresh_reference_style()
  vim.defer_fn(function()
    require("util").apply_reference_style()
  end, 20)
end

local function refresh_diagnostic_style()
  vim.defer_fn(function()
    require("util").apply_diagnostic_style()
  end, 20)
end

local function refresh_notify_style()
  vim.defer_fn(function()
    require("util").apply_notify_style()
  end, 20)
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = augroup("illuminate_colors"),
  callback = function()
    refresh_reference_style()
    refresh_diagnostic_style()
    refresh_notify_style()
  end,
})

vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter" }, {
  group = augroup("symbol_reference_startup"),
  callback = function()
    refresh_reference_style()
    refresh_diagnostic_style()
    refresh_notify_style()
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = augroup("symbol_reference_verylazy"),
  pattern = "VeryLazy",
  callback = function()
    refresh_reference_style()
    refresh_diagnostic_style()
    refresh_notify_style()
  end,
})

vim.schedule(function()
  refresh_reference_style()
  refresh_diagnostic_style()
  refresh_notify_style()
end)

require("util.helm_filetype").setup()

-- In oil buffers, restore normal delete/change behavior so dd+p moves entries
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("oil_native_edit_keys"),
  pattern = "oil",
  callback = function(event)
    local opts = { buffer = event.buf, remap = false, silent = true }
    vim.keymap.set({ "n", "x" }, "d", "d", opts)
    vim.keymap.set({ "n", "x" }, "D", "D", opts)
    vim.keymap.set({ "n", "x" }, "c", "c", opts)
    vim.keymap.set({ "n", "x" }, "C", "C", opts)
    vim.keymap.set({ "n", "x" }, "x", "x", opts)
    vim.keymap.set({ "n", "x" }, "X", "X", opts)
  end,
})

local function set_git_mergetool_keymaps(opts)
  opts = opts or {}
  opts.silent = true
  vim.keymap.set(
    "n",
    "<leader>GQ",
    "<cmd>wqa<cr>",
    vim.tbl_extend("force", opts, {
      desc = "Finish git mergetool",
    })
  )
  vim.keymap.set(
    "n",
    "<leader>GA",
    "<cmd>cq<cr>",
    vim.tbl_extend("force", opts, {
      desc = "Abort git mergetool",
    })
  )
end

local function launched_with_diffview_open()
  for _, arg in ipairs(vim.v.argv) do
    if arg == "DiffviewOpen" or arg:match("^DiffviewOpen%s") then
      return true
    end
  end
  return false
end

-- LazyGit's configured mergetool starts a nested Neovim as:
-- nvim "$MERGED" -c "DiffviewOpen"
-- Install finish/abort keys globally for that short-lived process, because the
-- first focused buffer may not be a classic vimdiff buffer.
local mergetool_group = augroup("git_mergetool_keys")
vim.api.nvim_create_autocmd("VimEnter", {
  group = mergetool_group,
  callback = function()
    if vim.g.git_mergetool_keys or not launched_with_diffview_open() then
      return
    end

    vim.g.git_mergetool_keys = true
    set_git_mergetool_keymaps()
  end,
})

-- Git mergetool can also run Neovim in diff mode; expose finish/abort there.
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = mergetool_group,
  callback = function(event)
    if not vim.wo.diff or vim.b[event.buf].git_mergetool_keys then
      return
    end

    vim.b[event.buf].git_mergetool_keys = true
    set_git_mergetool_keymaps({
      buffer = event.buf,
    })
  end,
})
