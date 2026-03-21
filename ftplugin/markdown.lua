-- ./ftplugin/markdown.lua

-- Markdown specific settings
vim.opt.wrap = true -- Wrap text
vim.opt.breakindent = true -- Match indent on line break
vim.opt.linebreak = true -- Line break on whole words

-- Allow j/k when navigating wrapped lines
vim.keymap.set("n", "k", "gj")
vim.keymap.set("n", "j", "gk")

-- Spell check
vim.opt.spelllang = 'en_us'
vim.opt.spell = true

-- Follow markdown anchor links: [Link Text](#anchor) -> jump to heading
local function follow_md_link()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local pos = 1
  while true do
    local ls, le, text, url = line:find("%[(.-)%]%((.-)%)", pos)
    if not ls then break end
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

-- Only set <CR> if obsidian.nvim is not loaded (it sets its own follow-link mapping)
if not package.loaded["obsidian"] then
  vim.keymap.set("n", "<CR>", follow_md_link, { buffer = true, desc = "Follow markdown link" })
end
