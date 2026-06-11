-- ./lua/config/keymaps.lua
--
-- NOTE: Yanky (Yank History) Keymaps:
--   p / P        - Paste after/before (yanky-aware)
--   <C-p>        - Cycle yank history forward (after paste)
--   <C-n>        - Cycle yank history backward (after paste)
--   <leader>r    - Open yank history picker
--
-- NOTE: Command Line (Cmdline) Completion:
--   Uses nvim-cmp cmdline completion.
--   <Down> / <Up>   - Next / previous completion item
--   <CR>            - Confirm selection without executing when menu is visible
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
--   <leader>Gt     - Open git mergetool
--   <leader>GQ     - Finish git mergetool (diff mode only)
--   <leader>GA     - Abort git mergetool (diff mode only)
--   <leader>Gb     - Diff vs branch/ref (prompt)
--   <leader>Gm     - Diff vs main/master
--   <leader>GM     - Diff vs origin/main
--   <leader>Gq     - Close Diffview
--   ]x / [x          - Next/prev conflict in merge view
--   <leader>Co/Ct    - Choose ours/theirs for current conflict
--   <leader>Cb/CB    - Choose both/base for current conflict
--   <leader>C0       - Choose none for current conflict
--   <leader>CO/CT/CA - Choose ours/theirs/all for whole file
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
local inlay_hints = require("util.inlay_hints")
local frequent_roots = require("util.frequent_roots")

-- Custom project tracking retained in util.frequent_roots, but disabled for now.
-- frequent_roots.setup()

-- Movement (no leader)
map({ "n", "x" }, "j", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up (display line)" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down (display line)" })
map({ "n", "x", "o" }, "$", "^", { desc = "First non-blank char" })
map({ "n", "x", "o" }, "^", "$", { desc = "End of line" })

-- Direction model in this config:
--   j = up, k = down
-- Keep modifier variants aligned with that mental model where possible.
-- Windows
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-k>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- Terminal mode
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Terminal window navigation (without leaving terminal mode)
map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Go to left window" })
map("t", "<C-j>", "<C-\\><C-n><C-w>k", { desc = "Go to upper window" })
map("t", "<C-k>", "<C-\\><C-n><C-w>j", { desc = "Go to lower window" })
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
local function move_current_buffer_to_split(split_cmd)
  local source_win = vim.api.nvim_get_current_win()
  local source_buf = vim.api.nvim_get_current_buf()

  vim.cmd(split_cmd)

  local target_win = vim.api.nvim_get_current_win()
  local target_buf = vim.api.nvim_get_current_buf()

  vim.api.nvim_win_set_buf(source_win, target_buf)
  vim.api.nvim_win_set_buf(target_win, source_buf)
end

map("n", "<leader>b-", function()
  move_current_buffer_to_split("new")
end, { desc = "Move buffer below" })
map("n", "<leader>b|", function()
  move_current_buffer_to_split("vnew")
end, { desc = "Move buffer right" })

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
map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Files
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New file" })

-- Projects
map("n", "<leader>fp", "<cmd>Telescope projects<cr>", { desc = "Projects" })
-- Custom project picker retained, but inactive:
-- map("n", "<leader>fp", function()
--   frequent_roots.pick_projects()
-- end, { desc = "Projects" })
map("n", "<leader>hm", function()
  frequent_roots.manage_manual()
end, { desc = "Manual dirs" })

-- Quit
map("n", "<leader>qq", "<cmd>AutoSession save<cr><cmd>qa<cr>", { desc = "Quit all" })

-- Lazy
map("n", "<leader>Pl", "<cmd>Lazy<cr>", { desc = "Lazy" })

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
map("n", "<leader>ue", function()
  util.toggle_neotree_reveal_on_open()
end, { desc = "Toggle Neo-tree reveal on open" })
map("n", "<leader>uD", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })
map("n", "<leader>uh", function()
  inlay_hints.toggle()
end, { desc = "Toggle inlay hints" })
map("n", "<leader>uu", function()
  util.toggle_reference_underline()
end, { desc = "Toggle reference underline" })
map("n", "<leader>uH", function()
  util.toggle_reference_background()
end, { desc = "Toggle reference background" })
map("n", "<leader>ui", function()
  require("util.ui_debug").inspect()
end, { desc = "Inspect UI highlights" })
map("n", "<leader>uT", function()
  require("util.ui_debug").toggle_treesitter()
end, { desc = "Toggle Treesitter buffer" })
map("n", "<leader>uI", function()
  require("util.ui_debug").toggle_illuminate()
end, { desc = "Toggle references buffer" })

-- Go to definition in vertical split (right)
map("n", "<leader>cd", function()
  vim.cmd("vsplit")
  vim.lsp.buf.definition()
end, { desc = "Goto definition in vsplit" })
map("n", "<leader>cp", function()
  vim.lsp.buf.code_action({
    filter = function(action)
      return action.title:match("package")
    end,
    apply = true,
  })
end, { desc = "Fix package declaration" })
map("n", "<leader>cO", function()
  vim.lsp.buf.code_action({
    context = {
      only = { "source.organizeImports" },
      diagnostics = {},
    },
    apply = true,
  })
end, { desc = "Organize imports" })

-- Replacing
map("v", "<leader>rw", [[:<C-u>'<,'>s/\%V]], { desc = "Replace within selection" })

-- Treesitter re-attach
map("n", "<leader>Xh", function()
  vim.treesitter.stop()
  vim.treesitter.start()
  vim.notify("Treesitter rehighlighted")
end, { desc = "Rehighlight buffer" })

local function treesitter_select_parent()
  require("vim.treesitter._select").select_parent(vim.v.count1)
end

local function treesitter_start_selection(fallback_key)
  if not vim.treesitter.get_parser(0, nil, { error = false }) then
    if fallback_key then
      vim.api.nvim_feedkeys(vim.keycode(fallback_key), "n", false)
    end
    return
  end

  vim.cmd.normal({ "v", bang = true })
  treesitter_select_parent()
end

local function treesitter_select_child()
  require("vim.treesitter._select").select_child(vim.v.count1)
end

local function treesitter_select_next()
  require("vim.treesitter._select").select_next(vim.v.count1)
end

map("n", "<CR>", function()
  treesitter_start_selection("<CR>")
end, { desc = "Treesitter start selection" })
map("n", "<A-o>", function()
  treesitter_start_selection()
end, { desc = "Treesitter start selection" })
map("x", "<CR>", treesitter_select_parent, { desc = "Treesitter select parent" })
map("x", "<A-o>", treesitter_select_parent, { desc = "Treesitter select parent" })
map("x", "<Tab>", function()
  treesitter_select_parent()
end, { desc = "Treesitter select parent" })
map("x", "<S-Tab>", function()
  treesitter_select_child()
end, { desc = "Treesitter select child" })
map("x", "<A-i>", treesitter_select_child, { desc = "Treesitter select child" })
map("x", "<BS>", function()
  treesitter_select_next()
end, { desc = "Treesitter select next" })

map("n", "<leader>XC", function()
  local ok, java = pcall(require, "java")
  if ok and java.build and java.build.clean_workspace then
    java.build.clean_workspace()
    vim.notify("Requested JDTLS workspace clean. Restart Neovim after it completes.", vim.log.levels.WARN)
    return
  end
  vim.notify("nvim-java workspace clean API is unavailable", vim.log.levels.ERROR)
end, { desc = "Clean JDTLS workspace" })

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

local function open_diffview_against_ref(ref)
  if not ref or vim.trim(ref) == "" then
    return
  end
  vim.cmd.DiffviewOpen({ args = { vim.trim(ref) .. "...HEAD" } })
end

local function pick_diffview_ref()
  local ok_builtin, builtin = pcall(require, "telescope.builtin")
  if ok_builtin then
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    builtin.git_branches({
      prompt_title = "Diffview Base Branch",
      show_remote_tracking_branches = true,
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not selection then
            return
          end
          open_diffview_against_ref(selection.value or selection[1])
        end)
        return true
      end,
    })
    return
  end

  vim.ui.input({ prompt = "Diffview base branch/ref: " }, open_diffview_against_ref)
end

map("n", "<leader>GD", "<cmd>DiffviewOpen<cr>", { desc = "Repo diff" })
map("n", "<leader>GF", "<cmd>DiffviewFileHistory --follow %<cr>", { desc = "File history" })
map("n", "<leader>GH", "<cmd>DiffviewFileHistory<cr>", { desc = "Repo history" })
map("n", "<leader>GL", "<Cmd>.DiffviewFileHistory --follow<CR>", { desc = "Line history" })
map("v", "<leader>GL", "<Esc><Cmd>'<,'>DiffviewFileHistory --follow<CR>", { desc = "Range history" })
map("n", "<leader>Gt", "<cmd>tabnew | terminal git mergetool<cr>", { desc = "Open git mergetool" })
map("n", "<leader>Gq", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" })
map("n", "<leader>Gb", pick_diffview_ref, { desc = "Diff vs branch/ref" })
map("n", "<leader>Gm", function()
  vim.cmd.DiffviewOpen({ args = { default_branch() } })
end, { desc = "Diff vs main/master" })
map("n", "<leader>GM", function()
  vim.cmd.DiffviewOpen({ args = { "HEAD..origin/" .. default_branch() } })
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
  require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
end, { desc = "Select outer function" })
map({ "x", "o" }, "if", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
end, { desc = "Select inner function" })
map({ "x", "o" }, "ac", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
end, { desc = "Select outer class" })
map({ "x", "o" }, "ic", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
end, { desc = "Select inner class" })
map({ "x", "o" }, "aa", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@parameter.outer", "textobjects")
end, { desc = "Select outer parameter" })
map({ "x", "o" }, "ia", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@parameter.inner", "textobjects")
end, { desc = "Select inner parameter" })
map({ "x", "o" }, "al", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@loop.outer", "textobjects")
end, { desc = "Select outer loop" })
map({ "x", "o" }, "il", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@loop.inner", "textobjects")
end, { desc = "Select inner loop" })
map({ "x", "o" }, "ai", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@conditional.outer", "textobjects")
end, { desc = "Select outer conditional" })
map({ "x", "o" }, "ii", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@conditional.inner", "textobjects")
end, { desc = "Select inner conditional" })

-- Move to next text object
map({ "n", "x", "o" }, "]f", function()
  require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
end, { desc = "Next function start" })
map({ "n", "x", "o" }, "]c", function()
  require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects")
end, { desc = "Next class start" })
map({ "n", "x", "o" }, "]a", function()
  require("nvim-treesitter-textobjects.move").goto_next_start("@parameter.inner", "textobjects")
end, { desc = "Next parameter start" })

-- Move to previous text object
map({ "n", "x", "o" }, "[f", function()
  require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
end, { desc = "Previous function start" })
map({ "n", "x", "o" }, "[c", function()
  require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects")
end, { desc = "Previous class start" })
map({ "n", "x", "o" }, "[a", function()
  require("nvim-treesitter-textobjects.move").goto_previous_start("@parameter.inner", "textobjects")
end, { desc = "Previous parameter start" })
