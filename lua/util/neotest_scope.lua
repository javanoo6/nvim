local M = {}

local uv = vim.uv or vim.loop

local IGNORED_DIRS = {
  [".git"] = true,
  [".gradle"] = true,
  [".idea"] = true,
  [".mvn"] = true,
  [".pytest_cache"] = true,
  [".svn"] = true,
  [".venv"] = true,
  ["build"] = true,
  ["dist"] = true,
  ["node_modules"] = true,
  ["out"] = true,
  ["target"] = true,
  ["venv"] = true,
}

local PATH_SEP = package.config:sub(1, 1)
local active_scope = nil
local warned_internal_client = false

local function normalize(path)
  return vim.fs.normalize(path)
end

local function path_starts_with(path, prefix)
  path = normalize(path)
  prefix = normalize(prefix)
  return path == prefix or vim.startswith(path, prefix .. PATH_SEP)
end

local function find_upwards(start_path, markers)
  local dir = vim.fs.dirname(start_path)
  while dir and dir ~= "" do
    for _, marker in ipairs(markers) do
      if uv.fs_stat(vim.fs.joinpath(dir, marker)) then
        return dir
      end
    end
    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      return nil
    end
    dir = parent
  end
  return nil
end

function M.current_scope(bufnr)
  bufnr = bufnr or 0
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    return nil
  end

  path = normalize(path)
  local filetype = vim.bo[bufnr].filetype
  local markers_by_ft = {
    go = { "go.mod", "go.work" },
    java = { "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts" },
    python = { "pyproject.toml", "pytest.ini", "setup.py", "setup.cfg" },
  }

  local focus_root = markers_by_ft[filetype] and find_upwards(path, markers_by_ft[filetype]) or nil
  if not focus_root then
    focus_root = vim.fs.dirname(path)
  end

  return {
    filetype = filetype,
    path = path,
    focus_root = normalize(focus_root),
  }
end

function M.get_scope()
  return active_scope or M.current_scope()
end

function M.activate_scope(scope)
  scope = scope or M.current_scope()
  active_scope = scope
  if not scope then
    return nil
  end

  if not path_starts_with(vim.fn.getcwd(), scope.focus_root) then
    vim.cmd("silent noautocmd cd " .. vim.fn.fnameescape(scope.focus_root))
  end

  return scope
end

function M.scoped_discovery_filter(name, rel_path, root)
  if IGNORED_DIRS[name] then
    return false
  end

  local scope = M.get_scope()
  if not scope then
    return true
  end

  root = normalize(root)
  if not path_starts_with(scope.path, root) then
    return false
  end

  if scope.focus_root == root then
    return true
  end

  if not path_starts_with(scope.focus_root, root) then
    return false
  end

  local focus_rel = vim.fs.relpath(root, scope.focus_root)
  if not focus_rel or focus_rel == "" or focus_rel == "." then
    return true
  end

  local candidate = rel_path == "." and name or (rel_path .. "/" .. name)
  return candidate == focus_rel or vim.startswith(focus_rel, candidate .. "/") or vim.startswith(candidate, focus_rel .. "/")
end

function M.with_scope(run_fn)
  return function(...)
    local source_buf = vim.api.nvim_get_current_buf()
    local scope = M.activate_scope(M.current_scope(source_buf))
    local ctx = {
      bufnr = source_buf,
      path = scope and scope.path or vim.api.nvim_buf_get_name(source_buf),
      scope = scope,
    }

    require("neotest").summary.open()
    require("neotest").output_panel.clear()
    return run_fn(ctx, ...)
  end
end

local function current_package_path(path)
  path = path or vim.api.nvim_buf_get_name(0)
  if path == "" then
    return uv.cwd()
  end

  return vim.fs.dirname(normalize(path))
end

local function java_test_package_path(path)
  local normalized = normalize(path)
  local marker = PATH_SEP .. "src" .. PATH_SEP .. "main" .. PATH_SEP .. "java" .. PATH_SEP
  local idx = normalized:find(marker, 1, true)
  if not idx then
    return nil
  end

  local prefix = normalized:sub(1, idx - 1)
  local suffix = normalized:sub(idx + #marker)
  return normalize(prefix .. PATH_SEP .. "src" .. PATH_SEP .. "test" .. PATH_SEP .. "java" .. PATH_SEP .. suffix)
end

local function parent_dir(path)
  local parent = vim.fs.dirname(path)
  if not parent or parent == "" or parent == path then
    return nil
  end
  return normalize(parent)
end

local function candidate_package_dirs(path, scope)
  local dirs = {}
  local seen = {}

  local function add(dir)
    if not dir or dir == "" then
      return
    end
    dir = normalize(dir)
    if seen[dir] then
      return
    end
    seen[dir] = true
    table.insert(dirs, dir)
  end

  add(current_package_path(path))

  if scope and scope.filetype == "java" then
    add(java_test_package_path(vim.fs.dirname(path)))
  end

  if scope then
    add(scope.focus_root)
  end

  add(uv.cwd())

  return dirs
end

function M.current_package_target(ctx)
  local path = ctx and ctx.path or vim.api.nvim_buf_get_name(0)
  if path == "" then
    return uv.cwd()
  end

  path = normalize(path)
  local scope = ctx and ctx.scope or M.get_scope()
  local target_dirs = candidate_package_dirs(path, scope)
  local neotest_state = require("neotest").state

  for _, adapter_id in ipairs(neotest_state.adapter_ids() or {}) do
    local tree = neotest_state.positions(adapter_id)
    if tree and path_starts_with(path, tree:data().path) then
      for _, target_dir in ipairs(target_dirs) do
        local dir = target_dir
        while dir and path_starts_with(dir, tree:data().path) do
          local node = tree:get_key(dir)
          if node and node:data().type == "dir" then
            return node:data().id
          end
          dir = parent_dir(dir)
        end
      end
    end
  end

  return (scope and scope.focus_root) or uv.cwd()
end

local function current_file_target(path)
  path = path or vim.api.nvim_buf_get_name(0)
  if path == "" then
    return uv.cwd()
  end

  path = normalize(path)
  local neotest_state = require("neotest").state

  for _, adapter_id in ipairs(neotest_state.adapter_ids() or {}) do
    local tree = neotest_state.positions(adapter_id)
    if tree and path_starts_with(path, tree:data().path) then
      local node = tree:get_key(path)
      if node and node:data().type == "file" then
        return node:data().id
      end
    end
  end

  return path
end

local function neotest_client()
  local ok, get_tree_from_args = pcall(function()
    return require("neotest").run.get_tree_from_args
  end)
  if not ok or type(get_tree_from_args) ~= "function" then
    return nil
  end

  local name, client = debug.getupvalue(get_tree_from_args, 1)
  if name == "client" and type(client) == "table" then
    return client
  end

  if not warned_internal_client then
    warned_internal_client = true
    vim.notify("Neotest internal client layout changed; current-file discovery fallback disabled", vim.log.levels.WARN)
  end
end

local function ensure_current_file_discovered(path)
  local client = neotest_client()
  if not client then
    return
  end

  local adapter_id = select(1, client:get_adapter(path))
  if not adapter_id then
    return
  end

  if client:get_position(path, { adapter = adapter_id }) then
    return
  end

  client:_update_positions(path, { adapter = adapter_id })
end

function M.run_current_file(ctx)
  local path = ctx and ctx.path or vim.api.nvim_buf_get_name(0)
  if path == "" then
    require("neotest").run.run(uv.cwd())
    return
  end

  path = normalize(path)
  require("nio").run(function()
    ensure_current_file_discovered(path)
    require("neotest").run.run(current_file_target(path))
  end)
end

function M.focus_root_or_cwd()
  local scope = M.get_scope()
  return scope and scope.focus_root or uv.cwd()
end

return M
