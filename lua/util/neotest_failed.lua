local M = {}

local scope = require("util.neotest_scope")

local uv = vim.uv or vim.loop
local path_sep = package.config:sub(1, 1)
local warned_internal_client = false

local function normalize(path)
  return vim.fs.normalize(path)
end

local function path_starts_with(path, prefix)
  if not path or path == "" then
    return false
  end
  path = normalize(path)
  prefix = normalize(prefix)
  return path == prefix or vim.startswith(path, prefix .. path_sep)
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
    vim.notify("Neotest internal client layout changed; failed-test rerun unavailable", vim.log.levels.WARN)
  end
end

local function failed_tests_in_scope()
  local neotest_state = require("neotest").state
  local client = neotest_client()
  if not client then
    return {}
  end

  local current_scope = scope.get_scope()
  local root = current_scope and current_scope.focus_root or uv.cwd()
  local failed = {}

  for _, adapter_id in ipairs(neotest_state.adapter_ids() or {}) do
    local tree = neotest_state.positions(adapter_id)
    local results = client:get_results(adapter_id)
    if tree and results then
      for _, node in tree:iter_nodes() do
        local position = node:data()
        local result = results[position.id]
        if result and result.status == "failed" and position.type == "test" and path_starts_with(position.path, root) then
          table.insert(failed, {
            adapter_id = adapter_id,
            id = position.id,
            name = position.name,
            path = position.path,
          })
        end
      end
    end
  end

  table.sort(failed, function(left, right)
    if left.path == right.path then
      return left.name < right.name
    end
    return left.path < right.path
  end)

  return failed
end

function M.run_failed(args)
  args = args or {}
  scope.activate_scope()
  require("neotest").summary.open()
  require("neotest").output_panel.clear()

  local failed = failed_tests_in_scope()
  if #failed == 0 then
    vim.notify("No failed Neotest tests in current scope", vim.log.levels.INFO)
    return
  end

  vim.notify(("Running %d failed Neotest test%s"):format(#failed, #failed == 1 and "" or "s"), vim.log.levels.INFO)

  for _, test in ipairs(failed) do
    require("neotest").run.run(vim.tbl_extend("force", { test.id, adapter = test.adapter_id }, args))
  end
end

return M
