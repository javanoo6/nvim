-- ./lua/config/autocmds.lua

local util = require("util")
local augroup = util.augroup

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
	pattern = { "text", "markdown", "gitcommit" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
	end,
})

-- Set up illuminate highlight colors
local function set_illuminate_hl()
	local bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
	local hl_bg = bg and (bg + 0x101010) or nil
	vim.api.nvim_set_hl(0, "IlluminatedWordText", { bg = hl_bg, underline = false })
	vim.api.nvim_set_hl(0, "IlluminatedWordRead", { bg = hl_bg, underline = false })
	vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { bg = hl_bg, underline = false, bold = true })
end

vim.api.nvim_create_autocmd("ColorScheme", {
	group = augroup("illuminate_colors"),
	callback = function()
		vim.schedule(set_illuminate_hl)
	end,
})

vim.schedule(set_illuminate_hl)

-- Restore normal delete/change keys in oil.nvim (blackhole remaps break move via cut/paste)
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("oil_normal_delete"),
	pattern = "oil",
	callback = function(event)
		local buf = event.buf
		for _, key in ipairs({ "d", "D", "c", "C", "x", "X" }) do
			vim.keymap.del({ "n", "x" }, key, { buffer = buf })
		end
	end,
})
