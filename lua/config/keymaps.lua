-- ./lua/config/keymaps.lua

local util = require("util")
local map = util.map

-- Movement (no leader)
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })

-- Windows
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- Move lines
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- Buffers
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Alternate buffer" })

-- Quickfix/Loclist
map("n", "[q", "<cmd>cprev<cr>", { desc = "Prev quickfix" })
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix" })
map("n", "[l", "<cmd>lprev<cr>", { desc = "Prev loclist" })
map("n", "]l", "<cmd>lnext<cr>", { desc = "Next loclist" })

-- Diagnostics
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>xd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>xl", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

-- Editing primitives
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Clear hlsearch" })
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save" })
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Files
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New file" })

-- Quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- Lazy
map("n", "<leader>pl", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- Splits
map("n", "<leader>-", "<C-W>s", { desc = "Split below" })
map("n", "<leader>|", "<C-W>v", { desc = "Split right" })

-- Tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Prev" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close" })

-- UI Toggles
map("n", "<leader>us", function() util.toggle("spell") end, { desc = "Spelling" })
map("n", "<leader>uw", function() util.toggle("wrap") end, { desc = "Wrap" })
map("n", "<leader>ul", function() util.toggle("relativenumber") end, { desc = "Relative numbers" })
map("n", "<leader>un", function() util.toggle("number") end, { desc = "Line numbers" })
map("n", "<leader>uf", function() util.toggle("foldenable") end, { desc = "Fold" })

-- Code
map({ "n", "v" }, "<leader>cf", function() util.format() end, { desc = "Format" })
map("n", "<leader>ci", function()
	vim.lsp.buf.code_action({
		context = { only = { "source.organizeImports" } },
		apply = true,
	})
end, { desc = "Organize imports" })
map("n", "<leader>cp", function()
	vim.lsp.buf.code_action({
		filter = function(action)
			return action.title:match("package")
		end,
		apply = true,
	})
end, { desc = "Fix package declaration" })

-- Replaicng
map("n", "<leader>rw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })


-- Treesitter re-attach
map("n", "<leader>xh", function()
	vim.cmd("TSBufDisable highlight")
	vim.cmd("TSBufEnable highlight")
	vim.notify("Treesitter rehighlighted")
end, { desc = "Rehighlight buffer" })

map("n", "<leader>xc", function()
	local cache_dirs = {
		vim.fn.expand("~/.cache/jdtls"),
		vim.fn.expand("~/.cache/nvim/jdtls"),
		vim.fn.expand("~/.cache/nvim/jdtls-workspace"),
	}
	for _, dir in ipairs(cache_dirs) do
		if vim.fn.isdirectory(dir) == 1 then
			vim.fn.delete(dir, "rf")
			vim.notify("Deleted: " .. dir)
		end
	end
	vim.notify("JDTLS cache cleared. Restart Neovim.", vim.log.levels.WARN)
end, { desc = "Clear JDTLS cache" })

-- Keep cursor centered when scrolling/jumping
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
map("n", "n", "nzzzv", { desc = "Next match and center" })
map("n", "N", "Nzzzv", { desc = "Prev match and center" })

-- Better join (keep cursor position)
map("n", "J", "mzJ`z", { desc = "Join lines keep cursor" })

-- Quick macro recording
map("n", "Q", "qq", { desc = "Record macro to q" })
map("n", "q", "@q", { desc = "Play macro q" })

-- Resize with Alt + arrows
map("n", "<M-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<M-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<M-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<M-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- Marks navigation
map("n", "]'", "`]", { desc = "Next mark" })
map("n", "['", "`[", { desc = "Prev mark" })
