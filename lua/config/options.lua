-- ./lua/config/options.lua

-- Homebrew's versioned JDK is not on PATH by default.
if vim.fn.has("macunix") == 1 then
  local java_home = vim.env.NVIM_JAVA_HOME or vim.env.JAVA_HOME
  if not java_home then
    for _, prefix in ipairs({ "/opt/homebrew", "/usr/local" }) do
      local candidate = prefix .. "/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
      if vim.fn.isdirectory(candidate) == 1 then
        java_home = candidate
        break
      end
    end
  end
  if java_home and vim.fn.isdirectory(java_home) == 1 then
    vim.env.JAVA_HOME = java_home
    vim.env.PATH = java_home .. "/bin:" .. vim.env.PATH
  end
end

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- Define the leader placeholder before plugins load so which-key can replace the
-- <Space> nop mapping with its trigger mapping instead of being overwritten later.
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true, desc = "Leader placeholder" })

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = ""
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.wrap = false
opt.breakindent = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true
require("util.clipboard").setup()
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.updatetime = 250
opt.timeoutlen = 500
opt.undofile = true
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.pumheight = 10
opt.showmode = false
opt.laststatus = 3
opt.fillchars = { eob = " " }

-- Disable lspconfig jdtls (we use nvim-jdtls)
vim.g.lspconfig_jdtls_enabled = false

-- Better search
opt.inccommand = "split" -- Preview substitutions live
opt.virtualedit = "block" -- Allow cursor in virtual space in visual block mode
opt.smoothscroll = true -- Smooth scrolling (Neovim 0.10+)

-- Session options (for auto-session to restore terminals, folds, window positions)
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- Disable folding - always show unfolded code
opt.foldenable = false

-- Better completion experience
opt.completeopt = "menu,menuone,noselect,preview"
opt.pumblend = 10 -- Slight transparency for popup menu
opt.winblend = 0
