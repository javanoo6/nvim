local M = {}

local function request(client, name, args, bufnr)
  local nio = require("nio")
  local future = nio.control.future()
  vim.schedule(function()
    client:request("workspace/executeCommand", { command = name, arguments = args }, function(err, result)
      if err then
        future.set_error(err.message or vim.inspect(err))
      else
        future.set(result)
      end
    end, bufnr)
  end)
  return future.wait()
end

local function context(path)
  local nio = require("nio")
  nio.scheduler()
  local bufnr = vim.fn.bufadd(path)
  vim.fn.bufload(bufnr)
  vim.bo[bufnr].filetype = "java"
  local factory = require("intellij-lsp.client")
  local client = factory.find_ancestor_client(path)
  if not client then
    local root = assert(factory.find_root(bufnr), "No Java build root for tests")
    local id = vim.lsp.start(factory.config(root, require("intellij-lsp").config), { bufnr = bufnr })
    client = assert(vim.lsp.get_client_by_id(id))
  else
    vim.lsp.buf_attach_client(bufnr, client.id)
  end
  local deadline = vim.uv.hrtime() + 120000000000
  while not (client.initialized and require("intellij-lsp.progress").is_ready(client.id)) do
    assert(vim.uv.hrtime() < deadline, "IntelliJ test workspace import timed out; see :JavaInfo")
    nio.sleep(100)
  end
  return client, bufnr
end

local function method_signature(classname, method, paths)
  local nio = require("nio")
  local future = nio.control.future()
  vim.schedule(function()
    vim.system(
      { vim.fs.dirname(paths.javaExec) .. "/javap", "-classpath", table.concat(paths.classpath, ":"), classname },
      { text = true },
      function(result)
        future.set(result)
      end
    )
  end)
  local result = future.wait()
  assert(result.code == 0, "Cannot resolve compiled test method: " .. result.stderr)
  for name, params in result.stdout:gmatch("([%w_]+)%(([^)]*)%)") do
    if name == method then
      return name .. "(" .. params .. ")"
    end
  end
  error("Compiled test method not found: " .. method)
end

function M.create()
  local nio = require("nio")
  local Path = require("neotest-java.model.path")
  local adapter = require("neotest-java")({ disable_update_notifications = true }, {
    method_id_resolver = {
      resolve_complete_method_id = function(_, method)
        return method
      end,
    },
  })
  adapter.name = "neotest-intellij-java"
  adapter.build_spec = function(args)
    local groups = {}
    for _, pos in args.tree:iter() do
      if pos.type == "test" then
        local base = pos.path:match("^(.-)/src/test/") or vim.fs.dirname(pos.path)
        groups[base] = groups[base] or { path = pos.path, tests = {}, files = {} }
        groups[base].files[pos.path] = true
        table.insert(groups[base].tests, pos)
      end
    end
    local specs = {}
    for _, group in pairs(groups) do
      local client, bufnr = context(group.path)
      nio.scheduler()
      for path in pairs(group.files) do
        local test_buf = vim.fn.bufadd(path)
        vim.fn.bufload(test_buf)
        vim.api.nvim_buf_call(test_buf, function()
          vim.cmd("silent update")
        end)
      end
      local uri = vim.uri_from_fname(group.path)
      local build = request(client, "intellij.java.resolveBuildCommand", { { uri = uri } }, bufnr)
      assert(build and build.supported and build.command and #build.command > 0, "No supported Java test compiler")
      local future = nio.control.future()
      vim.schedule(function()
        vim.system(build.command, { cwd = build.cwd, text = true }, function(result)
          future.set(result)
        end)
      end)
      local compiled = future.wait()
      assert(compiled.code == 0, "Test compilation failed:\n" .. compiled.stdout .. compiled.stderr)
      local paths = request(client, "intellij.java.resolveLaunch", { { uri = uri } }, bufnr)
      assert(paths and paths.javaExec and paths.classpath, "No IntelliJ test launch paths")
      assert(not paths.modulePath or #paths.modulePath == 0, "JPMS test modules are not supported by this console bridge")
      local jar = adapter.config.junit_jar:to_string()
      assert(vim.fn.filereadable(jar) == 1, "JUnit Console jar missing; run :NeotestJava setup")
      local reports = nio.fn.tempname()
      vim.fn.mkdir(reports, "p")
      local cli = {
        "execute",
        "--classpath=" .. table.concat(paths.classpath, ":"),
        "--reports-dir=" .. reports,
        "--fail-if-no-tests",
        "--disable-banner",
        "--details=tree",
      }
      for _, pos in ipairs(group.tests) do
        local classname, method = pos.id:match("^(.-)#(.-)%(")
        assert(classname and method, "Unsupported Java test node: " .. pos.id)
        cli[#cli + 1] = "--select-method=" .. classname .. "#" .. method_signature(classname, method, paths)
      end
      local spec = { cwd = paths.workingDirectory, context = { reports_dir = Path(reports) } }
      if args.strategy == "dap" then
        spec.strategy = {
          type = "intellij_jvm",
          request = "launch",
          name = "JUnit tests",
          mainClass = "org.junit.platform.console.ConsoleLauncher",
          classPaths = { jar },
          javaExec = paths.javaExec,
          vmArgs = paths.vmArgs or {},
          args = cli,
          cwd = paths.workingDirectory,
          console = "internalConsole",
          noDebug = false,
          intellij_client_id = client.id,
          intellij_root = client.config.root_dir,
        }
      else
        spec.command = { paths.javaExec }
        vim.list_extend(spec.command, paths.vmArgs or {})
        vim.list_extend(spec.command, { "-jar", jar })
        vim.list_extend(spec.command, cli)
      end
      specs[#specs + 1] = spec
    end
    assert(#specs > 0, "No runnable Java tests selected")
    return #specs == 1 and specs[1] or specs
  end
  return adapter
end

return M
