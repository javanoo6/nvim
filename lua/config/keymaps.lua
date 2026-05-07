-- ./lua/config/keymaps.lua
--
-- NOTE: Yanky (Yank History) Keymaps:
--   p / P        - Paste after/before (yanky-aware)
--   <C-p>        - Cycle yank history forward (after paste)
--   <C-n>        - Cycle yank history backward (after paste)
--   <leader>r    - Open yank history picker
--
-- NOTE: Command Line (Cmdline) Completion Keymaps (nvim-cmp):
--   <Tab> / <S-Tab>  - Navigate next/previous completion item
--   <C-y>            - Confirm selection (stay in cmdline, DON'T execute)
--   <C-e>            - Cancel completion
--   <CR>             - Confirm and execute immediately
--   Use <C-y> instead of <CR> when you want to chain completions without executing
--
-- NOTE: LazyGit Keymaps:
--   <leader>Gg     - Open LazyGit
--   <esc> (in LG)  - Back/Cancel in lazygit UI
--   <C-q> (in LG)  - Exit terminal mode (back to nvim)
--
-- NOTE: Diffview Keymaps:
--   <leader>GD     - Repo diff (DiffviewOpen)
--   <leader>GF     - File history
--   <leader>GH     - Repo history
--   <leader>GL     - Line/range history
--   <leader>Gm     - Diff vs main/master
--   <leader>GM     - Diff vs origin/main
--   <leader>Gq     - Close Diffview
--
-- NOTE: Gitsigns Keymaps (buffer-local, defined in plugins/git.lua):
--   ]h / [h          - Next/prev hunk
--   <leader>Ghs/Ghr  - Stage/reset hunk
--   <leader>GhS/GhR  - Stage/reset buffer
--   <leader>Ghu      - Undo stage hunk
--   <leader>Ghp      - Preview hunk
--   <leader>Ghb/GhB  - Blame line / toggle blame
--   <leader>Ghd      - Diff this
--   <leader>Ghw/Ghl/Ghv - Toggles: word diff / line hl / deleted

local util = require("util")
local map = util.map

-- Movement (no leader)
map({ "n", "x" }, "j", "v:count == 0 ? 'gk' : 'k'", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map({ "n", "x", "o" }, "$", "^", { desc = "First non-blank char" })
map({ "n", "x", "o" }, "^", "$", { desc = "End of line" })

-- Windows
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- Terminal mode
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Terminal window navigation (without leaving terminal mode)
map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Go to left window" })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Go to lower window" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Go to upper window" })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Go to right window" })

-- Move lines
map("n", "<A-j>", "<cmd>m .-2<cr>==", { desc = "Move up" })
map("n", "<A-k>", "<cmd>m .+1<cr>==", { desc = "Move down" })
map("i", "<A-j>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
map("i", "<A-k>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
map("v", "<A-j>", ":m '<-2<cr>gv=gv", { desc = "Move up" })
map("v", "<A-k>", ":m '>+1<cr>gv=gv", { desc = "Move down" })

-- IntelliJ-style: Move selected code with Shift+Ctrl+Up/Down
map("v", "<C-S-Up>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })
map("v", "<C-S-Down>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })

-- Buffers
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Alternate buffer" })
map("n", "<leader>b-", "<cmd>new<cr>", { desc = "New buffer below" })
map("n", "<leader>b|", "<cmd>vnew<cr>", { desc = "New buffer right" })

-- Loclist navigation (quickfix is handled by trouble.nvim)
map("n", "[l", "<cmd>lprev<cr>", { desc = "Prev loclist" })
map("n", "]l", "<cmd>lnext<cr>", { desc = "Next loclist" })

-- Diagnostics
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1 })
end, { desc = "Prev diagnostic" })
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1 })
end, { desc = "Next diagnostic" })
map("n", "<leader>xd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>xl", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

-- Editing primitives
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Clear hlsearch" })
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save" })
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Delete/change to black hole register (yank is the only way to fill the clipboard)
map({ "n", "x" }, "d", '"_d', { desc = "Delete (black hole)" })
map({ "n", "x" }, "D", '"_D', { desc = "Delete to EOL (black hole)" })
map({ "n", "x" }, "c", '"_c', { desc = "Change (black hole)" })
map({ "n", "x" }, "C", '"_C', { desc = "Change to EOL (black hole)" })
map({ "n", "x" }, "x", '"_x', { desc = "Delete char (black hole)" })
map({ "n", "x" }, "X", '"_X', { desc = "Delete char before (black hole)" })

-- Files
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New file" })

-- Projects
map("n", "<leader>fp", "<cmd>Telescope projects<cr>", { desc = "Projects" })

-- Quit
map("n", "<leader>qq", "<cmd>AutoSession save<cr><cmd>qa<cr>", { desc = "Quit all" })

-- Lazy
map("n", "<leader>pl", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- Splits
map("n", "<leader>-", "<C-W>s", { desc = "Split below" })
map("n", "<leader>|", "<C-W>v", { desc = "Split right" })
map("n", "<leader>wj", "<C-W>s<C-W>J", { desc = "Move buffer to bottom split" })
map("n", "<leader>wl", "<C-W>v<C-W>L", { desc = "Move buffer to right split" })

-- Tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Prev" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close" })

-- UI Toggles
map("n", "<leader>us", function()
	util.toggle("spell")
end, { desc = "Spelling" })
map("n", "<leader>uw", function()
	util.toggle("wrap")
end, { desc = "Wrap" })
map("n", "<leader>ul", function()
	util.toggle("relativenumber")
end, { desc = "Relative numbers" })
map("n", "<leader>un", function()
	util.toggle("number")
end, { desc = "Line numbers" })
map("n", "<leader>uf", function()
	util.toggle("foldenable")
end, { desc = "Fold" })
map("n", "<leader>ud", function()
	require("tiny-inline-diagnostic").toggle()
end, { desc = "Toggle inline diagnostics" })
map("n", "<leader>uD", function()
	vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

-- Go to definition in vertical split (right)
map("n", "<leader>cd", function()
	vim.cmd("vsplit")
	vim.lsp.buf.definition()
end, { desc = "Goto definition in vsplit" })
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

-- Replacing
map("v", "<leader>rw", [[:<C-u>'<,'>s/\%V]], { desc = "Replace within selection" })

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
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })

-- IntelliJ-style duplicate line/selection
map("n", "<C-d>", function()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local line = vim.api.nvim_get_current_line()
	vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { line })
	vim.api.nvim_win_set_cursor(0, { lnum + 1, col })
end, { desc = "Duplicate line" })
map("v", "<C-d>", function()
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	vim.api.nvim_buf_set_lines(0, end_line, end_line, false, lines)
	vim.api.nvim_win_set_cursor(0, { end_line + 1, 0 })
end, { desc = "Duplicate selection" })
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

-- Diffview
-- Keep Diffview lhs definitions only here.
-- Do not duplicate them in lazy plugin `keys`, or lazy.nvim will treat them
-- as lazy-load triggers, delete the real mappings on first use, and never
-- restore them for command-only plugins like Diffview.
local function default_branch()
	local res = vim.system({ "git", "rev-parse", "--verify", "main" }, { capture_output = true }):wait()
	return res.code == 0 and "main" or "master"
end

map("n", "<leader>GD", "<cmd>DiffviewOpen<cr>", { desc = "Repo diff" })
map("n", "<leader>GF", "<cmd>DiffviewFileHistory --follow %<cr>", { desc = "File history" })
map("n", "<leader>GH", "<cmd>DiffviewFileHistory<cr>", { desc = "Repo history" })
map("n", "<leader>GL", "<Cmd>.DiffviewFileHistory --follow<CR>", { desc = "Line history" })
map("v", "<leader>GL", "<Esc><Cmd>'<,'>DiffviewFileHistory --follow<CR>", { desc = "Range history" })
map("n", "<leader>Gq", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" })
map("n", "<leader>Gm", function()
	vim.cmd("DiffviewOpen " .. default_branch())
end, { desc = "Diff vs main/master" })
map("n", "<leader>GM", function()
	vim.cmd("DiffviewOpen HEAD..origin/" .. default_branch())
end, { desc = "Diff vs origin/main" })

-- Run Go program
map("n", "<leader>gr", "<cmd>term go run .<cr>", { desc = "Go run (current dir)" })
map("n", "<leader>gR", "<cmd>term go run %<cr>", { desc = "Go run (current file)" })
map("n", "<leader>gb", "<cmd>term go build .<cr>", { desc = "Go build" })
map("n", "<leader>gt", "<cmd>term go test ./...<cr>", { desc = "Go test all" })

-- Split line at cursor (like reverse of J), stay in normal mode
-- ga: text right of cursor goes to line above
-- gA: text right of cursor goes to line below
map("n", "ga", function()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local left = line:sub(1, col)
	local right = line:sub(col + 1)
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { left, right })
	vim.api.nvim_win_set_cursor(0, { lnum, 0 })
end, { desc = "Split line up (text right of cursor goes up)" })

map("n", "gA", function()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local left = line:sub(1, col)
	local right = line:sub(col + 1)
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { left, right })
	vim.api.nvim_win_set_cursor(0, { lnum + 1, 0 })
end, { desc = "Split line down (text right of cursor goes down)" })

-- Treesitter Text Objects (visual and operator-pending modes)
-- These require nvim-treesitter-textobjects plugin
-- Select mappings
map({ "x", "o" }, "af", function()
	require("nvim-treesitter.textobjects.select").select_textobject("@function.outer")
end, { desc = "Select outer function" })
map({ "x", "o" }, "if", function()
	require("nvim-treesitter.textobjects.select").select_textobject("@function.inner")
end, { desc = "Select inner function" })
map({ "x", "o" }, "ac", function()
	require("nvim-treesitter.textobjects.select").select_textobject("@class.outer")
end, { desc = "Select outer class" })
map({ "x", "o" }, "ic", function()
	require("nvim-treesitter.textobjects.select").select_textobject("@class.inner")
end, { desc = "Select inner class" })
map({ "x", "o" }, "aa", function()
	require("nvim-treesitter.textobjects.select").select_textobject("@parameter.outer")
end, { desc = "Select outer parameter" })
map({ "x", "o" }, "ia", function()
	require("nvim-treesitter.textobjects.select").select_textobject("@parameter.inner")
end, { desc = "Select inner parameter" })
map({ "x", "o" }, "al", function()
	require("nvim-treesitter.textobjects.select").select_textobject("@loop.outer")
end, { desc = "Select outer loop" })
map({ "x", "o" }, "il", function()
	require("nvim-treesitter.textobjects.select").select_textobject("@loop.inner")
end, { desc = "Select inner loop" })
map({ "x", "o" }, "ai", function()
	require("nvim-treesitter.textobjects.select").select_textobject("@conditional.outer")
end, { desc = "Select outer conditional" })
map({ "x", "o" }, "ii", function()
	require("nvim-treesitter.textobjects.select").select_textobject("@conditional.inner")
end, { desc = "Select inner conditional" })

-- Move to next text object
map({ "n", "x", "o" }, "]f", function()
	require("nvim-treesitter.textobjects.move").goto_next_start("@function.outer")
end, { desc = "Next function start" })
map({ "n", "x", "o" }, "]c", function()
	require("nvim-treesitter.textobjects.move").goto_next_start("@class.outer")
end, { desc = "Next class start" })
map({ "n", "x", "o" }, "]a", function()
	require("nvim-treesitter.textobjects.move").goto_next_start("@parameter.inner")
end, { desc = "Next parameter start" })

-- Move to previous text object
map({ "n", "x", "o" }, "[f", function()
	require("nvim-treesitter.textobjects.move").goto_previous_start("@function.outer")
end, { desc = "Previous function start" })
map({ "n", "x", "o" }, "[c", function()
	require("nvim-treesitter.textobjects.move").goto_previous_start("@class.outer")
end, { desc = "Previous class start" })
map({ "n", "x", "o" }, "[a", function()
	require("nvim-treesitter.textobjects.move").goto_previous_start("@parameter.inner")
end, { desc = "Previous parameter start" })
