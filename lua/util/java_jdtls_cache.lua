local M = {}

local corruption_patterns = {
  "MalformedInputException",
  "Cannot set lower sequence number",
  "Failed to save JDT index",
  "Java Index broken",
  "%.safetable/org%.eclipse%.core%.resources",
  "%.metadata/%.plugins/org%.eclipse%.jdt%.core/.+%.index",
}

local function lsp_log_path()
  if vim.lsp and vim.lsp.log and vim.lsp.log.get_filename then
    local ok, path = pcall(vim.lsp.log.get_filename)
    if ok and path and path ~= "" then
      return path
    end
  end

  return vim.fn.stdpath("state") .. "/lsp.log"
end

local function workspace_root()
  return vim.fn.stdpath("cache") .. "/jdtls/workspace"
end

local function has_corruption_signal(line)
  for _, pattern in ipairs(corruption_patterns) do
    if line:find(pattern) then
      return true
    end
  end

  return false
end

local function workspace_paths_from_line(line)
  local paths = {}
  local root = workspace_root()
  local escaped_root = vim.pesc(root)

  for path in line:gmatch(escaped_root .. "/proj_[%w._-]+") do
    paths[path] = true
  end

  return paths
end

local function active_jdtls_workspaces()
  local active = {}
  local ok, lsp_utils = pcall(require, "java-core.utils.lsp")
  if not ok then
    return active
  end

  for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
    local root_dir = client.config and client.config.root_dir or client.root_dir
    if root_dir and root_dir ~= "" then
      active[lsp_utils.get_jdtls_cache_data_path(root_dir)] = true
    end
  end

  return active
end

local function unique_suffix()
  return os.date(".corrupt-%Y%m%d-%H%M%S")
end

local function quarantine(path)
  local target = path .. unique_suffix()
  local renamed = vim.fn.rename(path, target)
  if renamed == 0 then
    return true, target
  end

  return false, "rename failed: " .. vim.fn.string(renamed)
end

local function delete(path)
  local deleted = vim.fn.delete(path, "rf")
  if deleted == 0 then
    return true, path
  end

  return false, "delete failed: " .. vim.fn.string(deleted)
end

function M.find_corrupt_workspaces()
  local log = lsp_log_path()
  local file = io.open(log, "r")
  if not file then
    return {}, log
  end

  local paths = {}
  for line in file:lines() do
    if has_corruption_signal(line) then
      for path in pairs(workspace_paths_from_line(line)) do
        paths[path] = true
      end
    end
  end
  file:close()

  local found = {}
  for path in pairs(paths) do
    if vim.uv.fs_stat(path) then
      found[#found + 1] = path
    end
  end
  table.sort(found)

  return found, log
end

function M.clean_corrupt_workspaces(opts)
  opts = opts or {}

  local found, log = M.find_corrupt_workspaces()
  if #found == 0 then
    vim.notify("No corrupt JDTLS workspaces found in " .. log, vim.log.levels.INFO, { title = "JDTLS Cache" })
    return
  end

  local active = active_jdtls_workspaces()
  local cleaned = {}
  local skipped = {}
  local failed = {}

  for _, path in ipairs(found) do
    if active[path] then
      skipped[#skipped + 1] = path .. " (active JDTLS client)"
    else
      local ok, result
      if opts.delete then
        ok, result = delete(path)
      else
        ok, result = quarantine(path)
      end

      if ok then
        cleaned[#cleaned + 1] = result
      else
        failed[#failed + 1] = path .. " (" .. result .. ")"
      end
    end
  end

  local lines = {}
  local action = opts.delete and "Deleted" or "Quarantined"

  if #cleaned > 0 then
    lines[#lines + 1] = action .. " corrupt JDTLS workspaces:"
    vim.list_extend(lines, cleaned)
  end
  if #skipped > 0 then
    lines[#lines + 1] = "Skipped active workspaces:"
    vim.list_extend(lines, skipped)
  end
  if #failed > 0 then
    lines[#lines + 1] = "Failed:"
    vim.list_extend(lines, failed)
  end

  local level = #failed > 0 and vim.log.levels.ERROR or vim.log.levels.WARN
  vim.notify(table.concat(lines, "\n"), level, { title = "JDTLS Cache" })
end

function M.register_commands()
  vim.api.nvim_create_user_command("JavaCleanCorruptWorkspaces", function(command)
    M.clean_corrupt_workspaces({ delete = command.bang })
  end, {
    bang = true,
    desc = "Quarantine corrupt JDTLS workspaces found in the LSP log; bang deletes instead",
    force = true,
  })
end

return M
