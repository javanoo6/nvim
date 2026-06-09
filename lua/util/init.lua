-- ./lua/util/init.lua

local M = {}

M.reference_style_state = {
  background = false,
  underline = true,
}

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

local function get_reference_background_color()
  local bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
  return bg and (bg + 0x101010) or nil
end

local function get_hl_attr(name, attr)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok and hl then
    return hl[attr]
  end
end

function M.apply_reference_style()
  local state = M.reference_style_state
  local bg = state.background and get_reference_background_color() or nil
  local underline = state.underline

  vim.api.nvim_set_hl(0, "IlluminatedWordText", { bg = bg, underline = underline })
  vim.api.nvim_set_hl(0, "IlluminatedWordRead", { bg = bg, underline = underline })
  vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { bg = bg, underline = underline, bold = state.background })
  vim.api.nvim_set_hl(0, "LspReferenceText", { bg = bg, underline = underline })
  vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = bg, underline = underline })
  vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = bg, underline = underline, bold = state.background })
end

function M.apply_diagnostic_style()
  local comment_fg = get_hl_attr("Comment", "fg")

  vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", {
    fg = comment_fg,
    strikethrough = true,
  })
end

function M.toggle_reference_underline()
  M.reference_style_state.underline = not M.reference_style_state.underline
  M.apply_reference_style()
  vim.notify("reference underline " .. (M.reference_style_state.underline and "on" or "off"))
end

function M.toggle_reference_background()
  M.reference_style_state.background = not M.reference_style_state.background
  M.apply_reference_style()
  vim.notify("reference background " .. (M.reference_style_state.background and "on" or "off"))
end

-- Root detection (simplified version of LazyVim.root)
M.root_patterns = {
  ".git",
  "_darcs",
  ".hg",
  ".bzr",
  ".svn",
  "lua",
  "Makefile",
  "package.json",
  "go.mod",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "settings.gradle",
  "settings.gradle.kts",
  "pyproject.toml",
  "setup.py",
  "Cargo.toml",
}

local function normalize(path)
  if not path or path == "" then
    return nil
  end
  if vim.startswith(path, "file://") then
    path = vim.uri_to_fname(path)
  end
  return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

local function path_has_prefix(path, prefix)
  path = normalize(path)
  prefix = normalize(prefix)
  if not path or not prefix then
    return false
  end
  if path == prefix then
    return true
  end
  local with_sep = prefix:sub(-1) == "/" and prefix or (prefix .. "/")
  return path:sub(1, #with_sep) == with_sep
end

local function get_buf_path(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return nil
  end
  return normalize(name)
end

local explorer_cwd_state = {
  initialized = false,
  pinned_path = nil,
  pinned_until = 0,
}

local function now_ms()
  return vim.uv.hrtime() / 1000000
end

local function is_pinned()
  return explorer_cwd_state.pinned_path ~= nil and now_ms() < explorer_cwd_state.pinned_until
end

local function ensure_explorer_cwd_tracking()
  if explorer_cwd_state.initialized then
    return
  end
  explorer_cwd_state.initialized = true

  vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("custom_explorer_cwd", { clear = true }),
    callback = function()
      local event = vim.v.event or {}
      local scope = event.scope
      local cwd = normalize(event.cwd)
      if scope == "window" then
        return
      end

      if is_pinned() and cwd and cwd ~= explorer_cwd_state.pinned_path then
        return
      end

      if cwd then
        vim.g.explorer_cwd = cwd
      end
    end,
  })
end

function M.get_cwd()
  local win_cwd = normalize(vim.fn.getcwd())
  local tab_cwd = normalize(vim.fn.getcwd(-1, 0))
  local global_cwd = normalize(vim.fn.getcwd(-1, -1))

  if win_cwd == tab_cwd or win_cwd == global_cwd then
    return win_cwd
  end

  local path = get_buf_path(0)
  if not path then
    return tab_cwd or global_cwd or win_cwd
  end

  if tab_cwd and path_has_prefix(path, tab_cwd) and not path_has_prefix(path, win_cwd) then
    return tab_cwd
  end

  if global_cwd and path_has_prefix(path, global_cwd) and not path_has_prefix(path, win_cwd) then
    return global_cwd
  end

  return win_cwd or tab_cwd or global_cwd
end

function M.get_global_cwd()
  return normalize(vim.fn.getcwd(-1, -1)) or M.get_cwd()
end

function M.set_explorer_cwd(path)
  ensure_explorer_cwd_tracking()
  path = normalize(path)
  if path then
    vim.g.explorer_cwd = path
  end
  return path
end

function M.pin_explorer_cwd(path, duration_ms)
  ensure_explorer_cwd_tracking()
  path = M.set_explorer_cwd(path)
  if not path then
    return nil
  end

  explorer_cwd_state.pinned_path = path
  explorer_cwd_state.pinned_until = now_ms() + (duration_ms or 1000)
  return path
end

function M.get_explorer_cwd()
  ensure_explorer_cwd_tracking()

  local raw = vim.g.explorer_cwd
  local path = normalize(raw)
  if is_pinned() and explorer_cwd_state.pinned_path then
    return explorer_cwd_state.pinned_path
  end
  if path and vim.fn.isdirectory(path) == 1 then
    return path
  end

  path = M.get_global_cwd()
  vim.g.explorer_cwd = path
  return path
end

function M.get_marker_root(bufnr)
  bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  local path = get_buf_path(bufnr)
  if not path then
    return nil
  end

  local root = vim.fs.find(M.root_patterns, { path = vim.fs.dirname(path), upward = true })[1]
  return root and vim.fs.dirname(root) or nil
end

function M.get_marker_root_from_path(path)
  path = normalize(path)
  if not path then
    return nil
  end

  local root = vim.fs.find(M.root_patterns, { path = vim.fs.dirname(path), upward = true })[1]
  return root and vim.fs.dirname(root) or nil
end

function M.get_lsp_root(bufnr)
  bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  local path = get_buf_path(bufnr)
  if not path then
    return nil
  end

  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local best
  for _, client in ipairs(clients) do
    local roots = {}

    if client.config and client.config.root_dir then
      roots[#roots + 1] = client.config.root_dir
    end
    if client.workspace_folders then
      for _, folder in ipairs(client.workspace_folders) do
        roots[#roots + 1] = folder.name or folder.uri
      end
    end

    for _, root in ipairs(roots) do
      root = normalize(root)
      if path_has_prefix(path, root) and (not best or #root > #best) then
        best = root
      end
    end
  end

  return best
end

function M.get_root(bufnr)
  bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  local path = get_buf_path(bufnr)
  local marker_root = M.get_marker_root(bufnr)
  local lsp_root = M.get_lsp_root(bufnr)
  local cwd = M.get_cwd()

  if marker_root then
    local root = marker_root
    if lsp_root and path_has_prefix(lsp_root, marker_root) then
      root = lsp_root
    end

    -- If the user narrowed scope with :cd/:lcd/:tcd into a subdirectory of the
    -- detected project, treat that cwd as the active root for root-aware tools.
    if cwd and path_has_prefix(cwd, root) and (not path or path_has_prefix(path, cwd)) then
      return cwd
    end

    return root
  end

  if lsp_root then
    if cwd and path_has_prefix(cwd, lsp_root) and (not path or path_has_prefix(path, cwd)) then
      return cwd
    end
    return lsp_root
  end

  return cwd
end

function M.get_root_basename(bufnr)
  local root = M.get_root(bufnr)
  if not root or root == "" then
    return nil
  end

  local name = vim.fs.basename(root)
  if name and name ~= "" then
    return name
  end

  local cwd = M.get_cwd()
  return cwd and vim.fs.basename(cwd) or nil
end

function M.get_root_from_path(path)
  local marker_root = M.get_marker_root_from_path(path)
  local cwd = M.get_cwd()

  if marker_root and cwd and path_has_prefix(cwd, marker_root) and path_has_prefix(path, cwd) then
    return cwd
  end

  return marker_root or cwd
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

  local pickers = {
    files = M.picker.find_files,
    live_grep = M.picker.live_grep,
    buffers = M.picker.buffers,
    oldfiles = M.picker.oldfiles,
    help_tags = M.picker.help_tags,
  }
  local run = pickers[picker] or M.picker.find_files
  run(opts)
end

-- LSP Icons for aerial and other plugins
M.icons = {
  kinds = {
    Array = " ",
    Boolean = " ",
    Class = " ",
    Color = " ",
    Constant = " ",
    Constructor = " ",
    Control = " ",
    Enum = " ",
    EnumMember = " ",
    Event = " ",
    Field = " ",
    File = " ",
    Folder = " ",
    Function = " ",
    Interface = " ",
    Key = " ",
    Keyword = " ",
    Method = " ",
    Module = " ",
    Namespace = " ",
    Null = "NULL",
    Number = " ",
    Object = " ",
    Operator = " ",
    Package = " ",
    Property = " ",
    Reference = " ",
    Snippet = " ",
    String = " ",
    Struct = " ",
    Text = " ",
    TypeParameter = " ",
    Unit = " ",
    Value = " ",
    Variable = " ",
  },
}

return M
