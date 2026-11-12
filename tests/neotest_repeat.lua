local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(repo)
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/nvim-nio")
local nio = require("nio")
local messages = {}
vim.notify = function(message)
  messages[#messages + 1] = message
end

package.loaded["util.preferences"] = {
  get = function()
    return false
  end,
}
local positions = {
  { id = "file", name = "test file", type = "file" },
  { id = "test", type = "test" },
}
local tree = {
  data = function()
    return positions[1]
  end,
  iter = function()
    return ipairs(positions)
  end,
}
local ctx = { path = "/tests/nearest.py", cursor = { 12, 0 } }
local no_nearest = false
package.loaded["util.neotest_scope"] = {
  resolve_nearest = function(captured, _, client)
    assert(captured == ctx, "Repeat uses the original file and cursor context")
    assert(client ~= nil, "Nearest resolution uses the consumer client")
    if not no_nearest then
      return tree, "adapter"
    end
  end,
}
package.loaded.neotest = {
  run = {
    get_last_run = function()
      error("Nearest repeat must not read last run")
    end,
  },
}
local runs, stops = 0, 0
local fail_at, cancel_at, throw_at, skip, missing
local results
local repeat_run = require("util.neotest_repeat")
repeat_run({
  run_tree = function(_, selected, args)
    assert(selected == tree and args.strategy == "integrated" and args.concurrent == false, "Repeat runs serially without DAP")
    runs = runs + 1
    nio.sleep(1)
    if runs == throw_at then
      error("runner exploded")
    end
    results = missing and {} or { test = { status = runs == fail_at and "failed" or skip and "skipped" or "passed" } }
    if runs == cancel_at then
      assert(repeat_run.stop(), "Active loop can be cancelled")
    end
  end,
  get_results = function()
    return results
  end,
  stop = function(_, selected, args)
    assert(selected == tree and args.adapter == "adapter", "Cancellation stops the repeated target")
    stops = stops + 1
  end,
})
local function run(limit)
  repeat_run.run(limit, ctx)
end
local function wait_for(message)
  assert(
    vim.wait(2000, function()
      for _, text in ipairs(messages) do
        if text:find(message, 1, true) then
          return true
        end
      end
    end, 5),
    vim.inspect(messages)
  )
  -- Completion callbacks must have released the session.
  vim.wait(20, function()
    return false
  end, 5)
end
local function reset()
  messages, runs, stops = {}, 0, 0
  fail_at, cancel_at, throw_at, skip, missing = nil, nil, nil, false, false
end
run(3)
wait_for("Completed after 3 runs")
assert(runs == 3, "Nearest target respects the run limit")
reset()
fail_at = 2
run(5)
wait_for("Stopped on failure at run 2")
assert(runs == 2, "Repeat stops at the expected attempt")
reset()
cancel_at = 2
run()
run()
wait_for("Cancelled after 2 runs")
assert(runs == 2 and stops == 1, "Cancellation stops the process and prevents more attempts")
assert(table.concat(messages, "\n"):find("already active", 1, true), "Duplicate loops are rejected")
assert(not repeat_run.stop(), "Inactive loop allows the ordinary stop picker")
reset()
skip = true
run()
wait_for("all tests skipped")
assert(runs == 1, "Invalid results prevent further attempts")
reset()
missing = true
run()
wait_for("missing results")
assert(runs == 1, "Invalid results prevent further attempts")
reset()
throw_at = 1
run()
wait_for("runner exploded")
reset()
run(1)
wait_for("Completed after 1 run")
reset()
no_nearest = true
run()
wait_for("No tests found")
assert(runs == 0, "Missing nearest target never falls back to last run")
no_nearest = false
vim.ui.input = function(_, callback)
  callback("0")
end
repeat_run.prompt(ctx)
assert(runs == 0 and messages[#messages]:find("positive whole number", 1, true), "Invalid count is rejected")
vim.ui.input = function(_, callback)
  callback(nil)
end
repeat_run.prompt(ctx)
assert(runs == 0, "Dismissing the count prompt runs nothing")
vim.ui.input = function(_, callback)
  callback("2")
end
repeat_run.prompt(ctx)
wait_for("Completed after 2 runs")
assert(runs == 2, "Repeat stops at the expected attempt")
print("Neotest repeat checks passed")
