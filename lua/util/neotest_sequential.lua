local M = {}

local scope = require("util.neotest_scope")

local warned_internal_client = false

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
    vim.notify("Neotest internal client layout changed; sequential test run unavailable", vim.log.levels.WARN)
  end
end

local function current_file_path()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return nil
  end
  return vim.fs.normalize(path)
end

local function ensure_file_tree(client, path)
  local adapter_id = select(1, client:_get_adapter(path))
  if not adapter_id then
    return nil, nil
  end

  local tree = client:get_position(path, { adapter = adapter_id })
  if tree then
    return tree, adapter_id
  end

  client:_update_positions(path, { adapter = adapter_id })
  return client:get_position(path, { adapter = adapter_id }), adapter_id
end

local function collect_tests(tree)
  local tests = {}
  for _, node in tree:iter_nodes() do
    local position = node:data()
    if position.type == "test" then
      table.insert(tests, position)
    end
  end
  return tests
end

local function run_tests(client, adapter_id, tests, args)
  args = args or {}
  for index, test in ipairs(tests) do
    vim.notify(("Running test %d/%d: %s"):format(index, #tests, test.name), vim.log.levels.INFO)
    local tree = client:get_position(test.id, { adapter = adapter_id })
    if tree then
      client:run_tree(tree, vim.tbl_extend("force", args, { adapter = adapter_id, concurrent = false }))
    else
      vim.notify(("Skipping undiscovered test: %s"):format(test.name), vim.log.levels.WARN)
    end
  end
end

function M.run_current_file_tests(args)
  scope.activate_scope()
  require("neotest").summary.open()
  require("neotest").output_panel.clear()

  local path = current_file_path()
  if not path then
    vim.notify("Sequential Neotest run requires a file-backed buffer", vim.log.levels.WARN)
    return
  end

  local client = neotest_client()
  if not client then
    return
  end

  require("nio").run(function()
    local tree, adapter_id = ensure_file_tree(client, path)
    if not tree or not adapter_id then
      vim.notify("No Neotest adapter found for current file", vim.log.levels.WARN)
      return
    end

    local tests = collect_tests(tree)
    if #tests == 0 then
      vim.notify("No test methods found in current file", vim.log.levels.INFO)
      return
    end

    vim.notify(("Running %d test%s sequentially"):format(#tests, #tests == 1 and "" or "s"), vim.log.levels.INFO)
    run_tests(client, adapter_id, tests, args)
  end)
end

return M
