-- Run after the built-in Markdown ftplugin so its undo script is preserved.

-- Markdown specific settings
vim.opt_local.wrap = true -- Wrap text
vim.opt_local.breakindent = true -- Match indent on line break
vim.opt_local.linebreak = true -- Line break on whole words

-- Spell check
vim.opt_local.spelllang = "en_us"
vim.opt_local.spell = true

local undo = "setlocal wrap< breakindent< linebreak< spelllang< spell<"
vim.b.undo_ftplugin = vim.b.undo_ftplugin and (vim.b.undo_ftplugin .. " | " .. undo) or undo

-- Follow markdown anchor links: [Link Text](#anchor) -> jump to heading
local function follow_md_link()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local pos = 1
  while true do
    local ls, le, text, url = line:find("%[(.-)%]%((.-)%)", pos)
    if not ls then
      break
    end
    if col >= ls and col <= le then
      if url:match("^#") then
        local escaped = vim.fn.escape(text, "\\[]().*^$+?{}|")
        vim.fn.search("^#\\+\\s\\+\\c" .. escaped, "w")
        vim.cmd("normal! zz")
      end
      return
    end
    pos = ls + 1
  end
end

-- Obsidian replaces this fallback on BufEnter for buffers inside its vault.
vim.keymap.set("n", "<CR>", follow_md_link, { buffer = true, desc = "Follow markdown link" })
vim.b.undo_ftplugin = vim.b.undo_ftplugin
  .. [[ | execute "lua if vim.fn.maparg('<CR>', 'n', false, true).desc == 'Follow markdown link' then vim.keymap.del('n', '<CR>', { buffer = 0 }) end"]]
