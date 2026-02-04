-- ./lua/config/autocmds.lua

local util = require("util")
local augroup = util.augroup

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank()
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

-- Suppress inlay hint errors (known Neovim bug with decoration provider)
vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup("inlay_hint_fix"),
  callback = function(args)
    local bufnr = args.buf
    -- Disable inlay hints on buffer changes to prevent "Invalid 'col'" errors
    vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "InsertLeave" }, {
      group = augroup("inlay_hint_refresh_" .. bufnr),
      buffer = bufnr,
      callback = function()
        -- Small delay to let LSP update before refreshing hints
        vim.defer_fn(function()
          pcall(function()
            if vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }) then
              vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
              vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            end
          end)
        end, 50)
      end,
    })
  end,
})
