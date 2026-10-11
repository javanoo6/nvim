-- Real async Conform subprocesses and fd, using disposable files only.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo)
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/conform.nvim")
local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture, "p")
local passed, messages = 0, {}
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. " expected " .. vim.inspect(expected) .. " got " .. vim.inspect(actual))
  passed = passed + 1
end
local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines or { "local x=1" }, path)
  return path
end
local function read(path)
  return vim.fn.readfile(path)
end
local function wait_for(predicate)
  assert(vim.wait(5000, predicate, 5), "Timed out: " .. vim.inspect(messages))
end
vim.notify = function(message)
  messages[#messages + 1] = message
end
local function terminal_message()
  for _, message in ipairs(messages) do
    if message:match("^FormatDir complete:") or message:match("^FormatDir cancelled:") then
      return message
    end
  end
end
local function run()
  local script = write(fixture .. "/formatter.py", {
    "import pathlib, sys, time",
    "time.sleep(0.15)",
    "if '03fail' in sys.argv[2]: sys.exit(1)",
    "p = pathlib.Path(sys.argv[1])",
    "p.write_text(p.read_text().replace('local x=1', 'local x = 1'))",
  })
  local conform = require("conform")
  local save_formats = 0
  conform.setup({
    format_on_save = function(bufnr)
      if not vim.b[bufnr].disable_autoformat then
        save_formats = save_formats + 1
        return { timeout_ms = 1000 }
      end
    end,
    formatters_by_ft = { lua = { "fixture" } },
    formatters = {
      fixture = {
        command = "python3",
        args = function(_, ctx)
          return { script, "$FILENAME", ctx.filename }
        end,
        stdin = false,
      },
    },
  })
  local helper = require("util.format_dir")
  helper.register_commands(conform, { lua = { "fixture" } })
  local tree = fixture .. "/tree"
  local changed = write(tree .. "/01changed.lua")
  write(tree .. "/02unchanged.lua", { "local x = 1" })
  write(tree .. "/03fail.lua")
  local modified = write(tree .. "/04modified.lua")
  local concurrent = write(tree .. "/05concurrent.lua")
  write(tree .. "/06last.lua")
  write(tree .. "/node_modules/excluded.lua")
  write(tree .. "/ignored.lua")
  write(tree .. "/.fdignore", { "ignored.lua" })
  write(tree .. "/unsupported.txt")
  local modified_buf = vim.fn.bufadd(modified)
  vim.fn.bufload(modified_buf)
  vim.api.nvim_buf_set_lines(modified_buf, 0, -1, false, { "local unsaved = true" })
  local concurrent_buf = vim.fn.bufadd(concurrent)
  vim.fn.bufload(concurrent_buf)
  local original_format = conform.format
  local active, maximum, ticks = 0, 0, 0
  conform.format = function(opts, callback)
    equal(opts.async, true, "Async formatting requested")
    active = active + 1
    maximum = math.max(maximum, active)
    if opts.bufnr == concurrent_buf then
      vim.defer_fn(function()
        vim.api.nvim_buf_set_lines(concurrent_buf, 0, -1, false, { "local edited_while_waiting = true" })
      end, 30)
    end
    return original_format(opts, function(err, edited)
      active = active - 1
      callback(err, edited)
    end)
  end
  local timer = vim.uv.new_timer()
  timer:start(
    10,
    10,
    vim.schedule_wrap(function()
      ticks = ticks + 1
    end)
  )
  helper.format_dir(conform, { lua = { "fixture" } }, tree)
  helper.format_dir(conform, { lua = { "fixture" } }, tree)
  wait_for(function()
    return terminal_message() ~= nil
  end)
  timer:stop()
  timer:close()
  equal(maximum, 1, "Only one request active")
  equal(ticks > 20, true, "Editor callbacks run during formatting")
  equal(terminal_message(), "FormatDir complete: 2 changed, 2 skipped, 2 failed (6/6 processed)", "Counts include unchanged files")
  equal(read(changed), { "local x = 1" }, "Formatted file written")
  equal(read(modified), { "local x=1" }, "Modified buffer never saved")
  equal(read(concurrent), { "local x=1" }, "Stale result never written")
  equal(vim.api.nvim_buf_get_lines(concurrent_buf, 0, -1, false), { "local edited_while_waiting = true" }, "Concurrent edits preserved")
  equal(read(tree .. "/ignored.lua"), { "local x=1" }, "fdignore honored")
  equal(read(tree .. "/node_modules/excluded.lua"), { "local x=1" }, "Excluded directory untouched")
  equal(messages[1]:find("already running", 1, true) ~= nil, true, "Overlapping run rejected")

  messages = {}
  local cancel_tree = fixture .. "/cancel"
  write(cancel_tree .. "/01changed.lua")
  local next_file = write(cancel_tree .. "/02next.lua")
  conform.format = function(opts, callback)
    vim.defer_fn(function()
      vim.cmd("FormatDirCancel")
    end, 30)
    return original_format(opts, callback)
  end
  helper.format_dir(conform, { lua = { "fixture" } }, cancel_tree)
  wait_for(function()
    return terminal_message() ~= nil
  end)
  equal(terminal_message(), "FormatDir cancelled: 1 changed, 0 skipped, 0 failed (1/2 processed)", "Cancellation finishes active request")
  equal(read(next_file), { "local x=1" }, "Cancellation stops next request")

  messages = {}
  conform.format = original_format
  helper.format_dir(conform, { lua = { "fixture" } }, cancel_tree)
  helper.cancel()
  wait_for(function()
    return terminal_message() ~= nil
  end)
  equal(terminal_message(), "FormatDir cancelled: 0 changed, 0 skipped, 0 failed (0/0 processed)", "Cancellation during discovery")
  equal(read(next_file), { "local x=1" }, "Discovery cancellation formats nothing")

  messages = {}
  helper.format_dir(conform, { lua = { "fixture" } }, cancel_tree)
  wait_for(function()
    return terminal_message() ~= nil
  end)
  equal(terminal_message(), "FormatDir complete: 1 changed, 1 skipped, 0 failed (2/2 processed)", "New run allowed after cancellation")

  messages = {}
  local readonly_tree = fixture .. "/readonly"
  local readonly_file = write(readonly_tree .. "/readonly.lua")
  local readonly_buf = vim.fn.bufadd(readonly_file)
  vim.fn.bufload(readonly_buf)
  vim.bo[readonly_buf].readonly = true
  helper.format_dir(conform, { lua = { "fixture" } }, readonly_tree)
  wait_for(function()
    return terminal_message() ~= nil
  end)
  equal(terminal_message(), "FormatDir complete: 0 changed, 0 skipped, 1 failed (1/1 processed)", "Write failure counted")
  equal(read(readonly_file), { "local x=1" }, "Failed write leaves disk untouched")
  equal(vim.bo[readonly_buf].modified, true, "Failed write preserves formatted buffer")
  equal(vim.b[readonly_buf].disable_autoformat, nil, "Write failure restores save policy")

  local system = vim.system
  for _, spawn_failure in ipairs({ false, true }) do
    messages = {}
    vim.system = function(_, _, callback)
      if spawn_failure then
        error("fixture spawn failed")
      end
      callback({ code = 1, stderr = "fixture fd failed" })
    end
    helper.format_dir(conform, { lua = { "fixture" } }, tree)
    wait_for(function()
      return #messages > 0
    end)
    equal(messages[1]:find(spawn_failure and "spawn failed" or "fd failed", 1, true) ~= nil, true, "Discovery failure reported")
  end
  vim.system = system
  messages = {}
  helper.format_dir(conform, { lua = { "fixture" } }, cancel_tree)
  wait_for(function()
    return terminal_message() ~= nil
  end)
  equal(terminal_message(), "FormatDir complete: 0 changed, 2 skipped, 0 failed (2/2 processed)", "Discovery failure releases active run")
  equal(save_formats, 0, "Directory writes never trigger a second format")
end
local ok, err = xpcall(run, debug.traceback)
vim.fn.delete(fixture, "rf")
if not ok then
  print(err)
  vim.cmd("cquit 1")
end
print(string.format("FormatDir: %d assertions passed", passed))
