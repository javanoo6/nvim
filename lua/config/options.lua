-- ./lua/config/options.lua

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = "a"
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
opt.clipboard = "unnamedplus"
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.updatetime = 250
opt.timeoutlen = 300
opt.undofile = true
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.completeopt = "menu,menuone,noselect"
opt.pumheight = 10
opt.showmode = false
opt.laststatus = 3
opt.fillchars = { eob = " " }

-- Disable lspconfig jdtls (we use nvim-jdtls)
vim.g.lspconfig_jdtls_enabled = false

-- Better search
opt.inccommand = "split"      -- Preview substitutions live
opt.virtualedit = "block"     -- Allow cursor in virtual space in visual block mode
opt.smoothscroll = true       -- Smooth scrolling (Neovim 0.10+)

-- Disable folding - always show unfolded code
opt.foldenable = false

-- Better completion experience
opt.completeopt = "menu,menuone,noselect,preview"
opt.pumblend = 10             -- Slight transparency for popup menu
opt.winblend = 10             -- Slight transparency for floating windows
