local M = {}
local pending
local output = require("intellij-lsp.output")

local function fail(message)
  output.append("--- " .. message .. " ---", "DiagnosticError")
  output.open()
  vim.notify(message, vim.log.levels.ERROR, { title = "Java" })
end

local function command(client, name, args, callback, bufnr)
  client:request("workspace/executeCommand", { command = name, arguments = args }, callback, bufnr)
end

local function run_build(task, build, callback)
  local label = build.tool or "build tool"
  output.append("--- " .. label .. ": building: " .. table.concat(build.command, " ") .. " ---", "Title")
  output.open({ focus = false })
  local fragments = { stdout = "", stderr = "" }
  local function sink(stream)
    return vim.schedule_wrap(function(_, data)
      if not data then
        return
      end
      local lines = vim.split(fragments[stream] .. data, "\n", { plain = true })
      fragments[stream] = table.remove(lines)
      for _, line in ipairs(lines) do
        output.append(line, require("intellij-lsp.progress")._import_hl(nil, line))
      end
    end)
  end
  local spawned, proc = pcall(
    vim.system,
    build.command,
    {
      cwd = build.cwd,
      text = true,
      stdout = sink("stdout"),
      stderr = sink("stderr"),
    },
    vim.schedule_wrap(function(result)
      for _, fragment in pairs(fragments) do
        if fragment ~= "" then
          output.append(fragment)
        end
      end
      task.building = false
      if task.cancelled then
        if pending == task then
          pending = nil
        end
        output.append("--- " .. label .. ": build stopped ---", "DiagnosticWarn")
        return
      end
      output.append("--- " .. label .. ": build " .. (result.code == 0 and "succeeded" or "failed, exit " .. result.code) .. " ---")
      if result.code ~= 0 then
        output.open()
      end
      callback(result.code == 0)
    end)
  )
  if not spawned then
    fail("Could not start Java build: " .. tostring(proc))
    callback(false)
    return
  end
  task.proc = proc
end

function M.launch(main_class, uri, no_debug, opts)
  opts = opts or {}
  local bufnr = vim.uri_to_bufnr(uri)
  local client = require("intellij-lsp.client").find_ancestor_client(vim.uri_to_fname(uri))
  if not client or not client.initialized or not require("intellij-lsp.progress").is_ready(client.id) then
    fail("Java workspace is not ready; check :JavaInfo")
    return
  end
  if pending then
    vim.notify("A Java launch/build is already pending", vim.log.levels.WARN)
    return
  end
  -- Compile current source rather than silently running its last saved version.
  local saved, save_err = pcall(vim.api.nvim_buf_call, bufnr, function()
    vim.cmd("silent update")
  end)
  if not saved then
    fail("Could not save Java source: " .. tostring(save_err))
    return
  end
  local task = { client = client, cancelled = false }
  pending = task
  local function active()
    return pending == task and not task.cancelled and not client:is_stopped()
  end
  local function start()
    if not active() then
      return
    end
    command(client, "intellij.java.resolveLaunch", { { uri = uri } }, function(err, paths)
      vim.schedule(function()
        if not active() then
          return
        end
        pending = nil
        if err or not paths or not paths.javaExec then
          fail("Could not resolve Java launch: " .. vim.inspect(err or paths))
          return
        end
        require("dap").run({
          type = "intellij_jvm",
          request = "launch",
          name = main_class,
          mainClass = main_class,
          classPaths = paths.classpath or {},
          modulePaths = paths.modulePath or {},
          moduleName = paths.moduleName,
          moduleContentPaths = paths.moduleContentPaths or {},
          javaExec = paths.javaExec,
          vmArgs = opts.vmArgs or paths.vmArgs or {},
          args = opts.args,
          cwd = opts.cwd or paths.workingDirectory,
          env = opts.env,
          console = "internalConsole",
          noDebug = no_debug,
          intellij_client_id = client.id,
          intellij_root = client.config.root_dir,
        })
      end)
    end, bufnr)
  end
  if opts.build == false then
    start()
    return
  end
  command(client, "intellij.java.resolveBuildCommand", { { uri = uri } }, function(err, resolved)
    vim.schedule(function()
      if not active() then
        return
      end
      local build, reason = require("intellij-lsp.run")._build_to_run(resolved)
      if err or not build then
        pending = nil
        fail("Java build unavailable: " .. vim.inspect(err or reason or resolved))
        return
      end
      task.building = true
      run_build(task, build, function(ok)
        task.building = false
        if not active() then
          return
        end
        if ok then
          start()
        else
          pending = nil
        end
      end)
    end)
  end, bufnr)
end

local function classes(symbols, result)
  for _, symbol in ipairs(symbols or {}) do
    if symbol.kind == vim.lsp.protocol.SymbolKind.Class then
      result[#result + 1] = symbol
    end
    classes(symbol.children, result)
  end
end

function M.at_cursor(no_debug, opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "intellij" })[1]
  if not client then
    fail("No IntelliJ client attached to this Java buffer")
    return
  end
  client:request("textDocument/documentSymbol", { textDocument = { uri = vim.uri_from_bufnr(bufnr) } }, function(err, symbols)
    if err or not symbols or not vim.api.nvim_buf_is_valid(bufnr) then
      fail("Could not find Java main class at the cursor")
      return
    end
    local candidates = {}
    classes(symbols, candidates)
    local main_class = require("intellij-lsp.run")._enclosing_class(bufnr, candidates, row)
    if not main_class then
      fail("Place the cursor inside the Java class to launch")
      return
    end
    vim.schedule(function()
      M.launch(main_class, vim.uri_from_bufnr(bufnr), no_debug, opts)
    end)
  end, bufnr)
end

function M.stop()
  if pending then
    local task = pending
    task.cancelled = true
    if task.building then
      task.proc:kill("sigterm")
    else
      pending = nil
    end
    return
  end
  local dap = require("dap")
  local owner = vim.lsp.get_clients({ bufnr = 0, name = "intellij" })[1]
  for _, session in pairs(dap.sessions()) do
    if session.config.type == "intellij_jvm" and (not owner or session.config.intellij_client_id == owner.id) then
      dap.set_session(session)
      dap.terminate()
      return
    end
  end
  vim.notify("No IntelliJ Java session to stop", vim.log.levels.INFO)
end

function M.setup()
  local run = require("intellij-lsp.run")
  run.setup({ build_before_run = true })
  run.launch = M.launch
  run.run_at_cursor = M.at_cursor
  -- Upstream captures its original launch in the lens handler; replace it too.
  vim.lsp.commands["intellij.jvm.runMain"] = function(cmd)
    local args = (cmd.arguments or {})[1] or {}
    if args.mainClass then
      M.launch(args.mainClass, args.uri or vim.uri_from_bufnr(0), args.noDebug ~= false)
    end
  end
  vim.api.nvim_create_user_command("IntellijLspDebug", function(cmd)
    M.at_cursor(false, { build = not cmd.bang })
  end, { bang = true, desc = "Debug Java class at cursor (! skips build)" })
  require("dap").adapters.intellij_jvm = function(callback, config)
    local client = vim.lsp.get_client_by_id(config.intellij_client_id)
    if not client or client:is_stopped() or client.config.root_dir ~= config.intellij_root then
      fail("The Java launch workspace is no longer running; launch again from its source buffer")
      return
    end
    command(client, "start_debug_server", { vim.uri_from_fname(config.intellij_root) }, function(err, port)
      if err or type(port) ~= "number" then
        fail("Could not start IntelliJ debug adapter: " .. vim.inspect(err or port))
        return
      end
      callback({ type = "server", host = "127.0.0.1", port = port, id = "intellij_jvm" })
    end)
  end
  vim.api.nvim_create_user_command("IntellijLspRunStop", M.stop, { desc = "Stop Java build/program" })
  vim.api.nvim_create_user_command("IntellijLspDebugStop", M.stop, { desc = "Stop Java build/program" })
  output.keymap("<C-c>", M.stop, "Stop Java build/program")
end

return M
