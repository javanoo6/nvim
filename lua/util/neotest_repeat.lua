local M = {}
local client
local active

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Neotest repeat" })
end

local function outcome(tree, results)
  local passed = false
  for _, position in tree:iter() do
    local result = results[position.id]
    if result and result.status == "failed" then
      return "failed"
    end
    if position.type == "test" then
      if not result or (result.status ~= "passed" and result.status ~= "skipped") then
        return "incomplete"
      end
      passed = passed or result.status == "passed"
    end
  end
  return passed and "passed" or "incomplete"
end

function M.run(limit, ctx)
  if active then
    notify("A repeat run is already active; stop it with <leader>tS", vim.log.levels.WARN)
    return
  end
  local args = { strategy = "integrated", concurrent = false }
  local session = { cancelled = false }
  active = session
  require("nio").run(function()
    session.tree, session.adapter = require("util.neotest_scope").resolve_nearest(ctx, args, client)
    if not session.tree then
      notify("No tests found", vim.log.levels.WARN)
      return
    end
    args.adapter = args.adapter or session.adapter
    local position = session.tree:data()

    local count = 0
    while not session.cancelled and (not limit or count < limit) do
      -- Yield between attempts so even a fast adapter remains cancellable.
      require("nio").sleep(10)
      if session.cancelled then
        break
      end
      count = count + 1
      notify(("Run %d%s: %s"):format(count, limit and ("/" .. limit) or "", position.name))
      client:run_tree(session.tree, vim.deepcopy(args))
      if session.cancelled then
        break
      end
      local status = outcome(session.tree, client:get_results(args.adapter))
      if status ~= "passed" then
        notify(
          status == "failed" and ("Stopped on failure at run %d"):format(count)
            or ("Stopped at run %d: missing results, runner error, or all tests skipped"):format(count),
          vim.log.levels.WARN
        )
        return
      end
    end
    notify(("%s after %d run%s"):format(session.cancelled and "Cancelled" or "Completed", count, count == 1 and "" or "s"))
  end, function(ok, err)
    active = nil
    if not ok then
      vim.schedule(function()
        notify("Repeat run stopped: " .. tostring(err), vim.log.levels.ERROR)
      end)
    end
  end)
end

function M.prompt(ctx)
  vim.ui.input({ prompt = "Maximum test runs (stop on failure): ", default = "10" }, function(value)
    if value == nil then
      return
    end
    local limit = tonumber(value)
    if not limit or limit < 1 or limit == math.huge or limit ~= math.floor(limit) then
      notify("Enter a positive whole number", vim.log.levels.WARN)
      return
    end
    M.run(limit, ctx)
  end)
end

function M.stop()
  if not active then
    return false
  end
  active.cancelled = true
  local session = active
  if session.tree then
    require("nio").run(function()
      client:stop(session.tree, { adapter = session.adapter })
    end)
  end
  return true
end

return setmetatable(M, {
  __call = function(_, neotest_client)
    client = neotest_client
    return M
  end,
})
