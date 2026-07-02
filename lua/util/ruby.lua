-- ./lua/util/ruby.lua

local M = {}

M.version = "3.2.5"
M.bundler_version = "2.7.1"

local root_markers = {
  "Gemfile",
  ".ruby-version",
  ".ruby-gemset",
  ".env",
  ".git",
}

local function normalize(path)
  if not path or path == "" then
    return nil
  end
  return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function unquote(value)
  if #value >= 2 then
    local first = value:sub(1, 1)
    local last = value:sub(-1)
    if (first == '"' and last == '"') or (first == "'" and last == "'") then
      value = value:sub(2, -2)
    end
  end

  value = value:gsub("\\n", "\n")
  value = value:gsub('\\"', '"')
  value = value:gsub("\\'", "'")
  value = value:gsub("\\\\", "\\")
  return value
end

local function parse_env_line(line)
  line = trim(line)
  if line == "" or vim.startswith(line, "#") then
    return nil
  end

  if vim.startswith(line, "export ") then
    line = trim(line:sub(8))
  end

  local key, value = line:match("^([%a_][%w_]*)%s*=%s*(.*)$")
  if not key then
    return nil
  end

  return key, unquote(trim(value))
end

local function read_env_file(path)
  local vars = {}
  if not path or vim.fn.filereadable(path) ~= 1 then
    return vars
  end

  for _, line in ipairs(vim.fn.readfile(path)) do
    local key, value = parse_env_line(line)
    if key then
      vars[key] = value
    end
  end

  return vars
end

local function root_dir_for_path(fname)
  if not fname or fname == "" then
    return require("util").get_root(0)
  end

  local stat = vim.uv.fs_stat(fname)
  local search_path = stat and stat.type == "directory" and fname or vim.fs.dirname(fname)
  local marker = vim.fs.find(root_markers, {
    path = search_path,
    upward = true,
  })[1]

  if marker then
    return vim.fs.dirname(marker)
  end

  return require("util").get_root(0)
end

function M.root_dir(target, on_dir)
  local fname = target
  if type(target) == "number" then
    fname = vim.api.nvim_buf_get_name(target)
  end

  local root = root_dir_for_path(fname)
  if on_dir then
    on_dir(root)
    return
  end

  return root
end

function M.project_env(root)
  root = normalize(root)
  if not root then
    return {}
  end

  return read_env_file(root .. "/.env")
end

local function resolve_root_path(root, path)
  if not path or path == "" then
    return nil
  end

  if vim.startswith(path, "/") then
    return normalize(path)
  end

  return root and normalize(root .. "/" .. path) or normalize(path)
end

function M.bundle_gemfile_for(target)
  local root = M.root_dir(target)
  local env = M.project_env(root)
  local configured = resolve_root_path(root, env.BUNDLE_GEMFILE or vim.env.BUNDLE_GEMFILE)

  if configured and vim.fn.filereadable(configured) == 1 then
    return configured
  end

  if root and vim.fn.filereadable(root .. "/Gemfile") == 1 then
    return root .. "/Gemfile"
  end
end

function M.ruby_ref(root)
  root = normalize(root)
  local version = M.version
  local gemset

  if root then
    local version_file = root .. "/.ruby-version"
    local gemset_file = root .. "/.ruby-gemset"

    if vim.fn.filereadable(version_file) == 1 then
      local lines = vim.fn.readfile(version_file)
      version = trim(lines[1] or "")
      version = version ~= "" and version or M.version
    end

    if vim.fn.filereadable(gemset_file) == 1 then
      local lines = vim.fn.readfile(gemset_file)
      gemset = trim(lines[1] or "")
    end
  end

  if gemset and gemset ~= "" then
    return version .. "@" .. gemset
  end

  return version
end

function M.rvm_script(command, opts)
  opts = opts or {}
  local root = opts.root or M.root_dir(0)
  local env = {}
  local gemfile = opts.gemfile or M.bundle_gemfile_for(root)
  if gemfile then
    env[#env + 1] = "BUNDLE_GEMFILE=" .. vim.fn.shellescape(gemfile)
  end

  local prefix = #env > 0 and (table.concat(env, " ") .. " ") or ""
  local ruby_ref = opts.ruby_ref or M.ruby_ref(root)
  return table.concat({
    "source ~/.rvm/scripts/rvm",
    "rvm_silence_path_mismatch_check_flag=1 " .. prefix .. "rvm " .. vim.fn.shellescape(ruby_ref) .. " do " .. command,
  }, " && ")
end

function M.rvm_cmd(command, opts)
  return { "zsh", "-lc", M.rvm_script(command, opts) }
end

function M.ruby_lsp_cmd(root_dir)
  return M.rvm_cmd("ruby-lsp", { root = root_dir })
end

return M
