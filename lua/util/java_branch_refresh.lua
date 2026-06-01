local util = require("util")

local M = {}

local java_root_markers = {
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "settings.gradle",
  "settings.gradle.kts",
}

local state = {
  roots = {},
  restart_inflight = false,
}

local function normalize(path)
  if not path or path == "" then
    return nil
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

local function is_java_root(root)
  if not root then
    return false
  end
  for _, marker in ipairs(java_root_markers) do
    if vim.uv.fs_stat(root .. "/" .. marker) then
      return true
    end
  end
  return false
end

local function resolve_git_dir(root)
  local git_path = vim.fs.find(".git", { path = root, upward = true, limit = 1 })[1]
  if not git_path then
    return nil
  end

  local stat = vim.uv.fs_stat(git_path)
  if stat and stat.type == "directory" then
    return normalize(git_path)
  end

  local head = vim.fn.readfile(git_path, "", 1)[1]
  local gitdir = head and head:match("^gitdir:%s*(.-)%s*$")
  if not gitdir or gitdir == "" then
    return nil
  end

  if not vim.startswith(gitdir, "/") then
    gitdir = vim.fs.dirname(git_path) .. "/" .. gitdir
  end

  return normalize(gitdir)
end

local function get_head_signature(root)
  local git_dir = resolve_git_dir(root)
  if not git_dir then
    return nil
  end

  local head = vim.fn.readfile(git_dir .. "/HEAD", "", 1)[1]
  if not head or head == "" then
    return nil
  end

  return git_dir .. "::" .. head
end

local function iter_java_buffers()
  local bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "java" then
      bufs[#bufs + 1] = buf
    end
  end
  return bufs
end

local function get_root_for_buf(bufnr)
  local root = util.get_root(bufnr)
  if not is_java_root(root) then
    return nil
  end
  return normalize(root)
end

local function record_root(root)
  local signature = get_head_signature(root)
  if signature then
    state.roots[root] = signature
  end
end

local function roots_for_buffers()
  local roots = {}
  for _, buf in ipairs(iter_java_buffers()) do
    local root = get_root_for_buf(buf)
    if root then
      roots[root] = true
    end
  end
  return roots
end

local function restart_jdtls(changed_roots)
  if state.restart_inflight then
    return
  end
  state.restart_inflight = true

  local clients = vim.lsp.get_clients({ name = "jdtls" })
  local targets = {}
  for _, client in ipairs(clients) do
    local root_dir = client.config and client.config.root_dir or nil
    for root in pairs(changed_roots) do
      if path_has_prefix(root_dir, root) or path_has_prefix(root, root_dir) then
        targets[#targets + 1] = client
        break
      end
    end
  end

  if #targets > 0 then
    vim.lsp.stop_client(targets, true)
  end

  local restarted = false
  vim.defer_fn(function()
    for _, buf in ipairs(iter_java_buffers()) do
      local root = get_root_for_buf(buf)
      if root and changed_roots[root] then
        vim.api.nvim_buf_call(buf, function()
          pcall(vim.cmd, "silent! LspStart jdtls")
        end)
        restarted = true
      end
    end

    state.restart_inflight = false

    if restarted then
      local names = {}
      for root in pairs(changed_roots) do
        names[#names + 1] = vim.fs.basename(root)
      end
      table.sort(names)
      vim.notify("JDTLS refreshed after Git branch change: " .. table.concat(names, ", "), vim.log.levels.INFO)
    end
  end, 150)
end

function M.track_buffer(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local root = get_root_for_buf(bufnr)
  if root then
    record_root(root)
  end
end

function M.refresh_if_branch_changed()
  local changed_roots = {}

  for root in pairs(roots_for_buffers()) do
    local current = get_head_signature(root)
    local previous = state.roots[root]

    if current and previous and current ~= previous then
      changed_roots[root] = true
    end

    if current then
      state.roots[root] = current
    end
  end

  if next(changed_roots) then
    restart_jdtls(changed_roots)
  end
end

function M.setup()
  vim.api.nvim_create_user_command("JavaBranchRefresh", function()
    M.refresh_if_branch_changed()
  end, { desc = "Refresh JDTLS when the current Git HEAD changed" })
end

return M
