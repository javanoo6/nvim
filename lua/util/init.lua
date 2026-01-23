local M = {}

-- Safe keymap set (replaces LazyVim.safe_keymap_set)
function M.map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Check if plugin is available (replaces LazyVim.has)
function M.has(plugin)
  return require("lazy.core.config").spec.plugins[plugin] ~= nil
end

-- Get plugin opts (replaces LazyVim.opts)
function M.opts(name)
  local plugin = require("lazy.core.config").spec.plugins[name]
  if not plugin then
    return {}
  end
  local Plugin = require("lazy.core.plugin")
  return Plugin.values(plugin, "opts", false)
end

-- Create autocmd helper
function M.augroup(name)
  return vim.api.nvim_create_augroup("custom_" .. name, { clear = true })
end

-- Toggle option helper (replaces LazyVim.toggle)
function M.toggle(option, values)
  if values then
    if vim.opt_local[option]:get() == values[1] then
      vim.opt_local[option] = values[2]
    else
      vim.opt_local[option] = values[1]
    end
    vim.notify(option .. " set to " .. vim.opt_local[option]:get())
  else
    vim.opt_local[option] = not vim.opt_local[option]:get()
    vim.notify(option .. " set to " .. tostring(vim.opt_local[option]:get()))
  end
end

-- Root detection (simplified version of LazyVim.root)
M.root_patterns = { ".git", "lua" }

function M.get_root()
  local path = vim.api.nvim_buf_get_name(0)
  path = path ~= "" and vim.loop.fs_realpath(path) or nil

  if not path then
    return vim.loop.cwd()
  end

  local root = vim.fs.find(M.root_patterns, { path = path, upward = true })[1]
  return root and vim.fs.dirname(root) or vim.loop.cwd()
end

-- Picker abstraction (telescope/fzf) - simplified
M.picker = nil -- Will be set by telescope/fzf plugin

function M.pick(picker, opts)
  if not M.picker then
    vim.notify("No picker available", vim.log.levels.ERROR)
    return
  end

  opts = opts or {}
  opts.cwd = opts.cwd or M.get_root()

  if picker == "files" then
    M.picker.find_files(opts)
  elseif picker == "live_grep" then
    M.picker.live_grep(opts)
  elseif picker == "buffers" then
    M.picker.buffers(opts)
  elseif picker == "oldfiles" then
    M.picker.oldfiles(opts)
  elseif picker == "help_tags" then
    M.picker.help_tags(opts)
  else
    M.picker.find_files(opts)
  end
end

-- Format helper (simplified)
M.formatters = {}

function M.format()
  if vim.lsp.buf.format then
    vim.lsp.buf.format({ async = false })
  end
end

return M
