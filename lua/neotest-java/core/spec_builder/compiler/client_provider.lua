local Path = require("neotest-java.model.path")
local logger = require("neotest-java.logger")

--- @param deps { get_clients: fun(opts: table): vim.lsp.Client[], globpath: fun(dir: string, pattern: string, nosuf: boolean, list: boolean): string[], bufadd: fun(path: string): number, bufload: fun(path: string), sleep: fun(ms: number), hrtime: fun(): number }
--- @return fun(cwd: neotest-java.Path): vim.lsp.Client
local function ClientProvider(deps)
  local client

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

  local function client_matches_cwd(lsp_client, cwd)
    local root = lsp_client and lsp_client.config and lsp_client.config.root_dir
    local cwd_string = cwd and cwd:to_string()
    return lsp_client
      and lsp_client.initialized
      and root
      and cwd_string
      and (path_has_prefix(cwd_string, root) or path_has_prefix(root, cwd_string))
  end

  local function find_client_for_cwd(cwd)
    for _, lsp_client in ipairs(deps.get_clients({ name = "jdtls" })) do
      if client_matches_cwd(lsp_client, cwd) then
        return lsp_client
      end
    end
    return nil
  end

  local function find_any_java_file(dir)
    return Path(
      assert(
        vim.iter(deps.globpath(dir:to_string(), Path("**/*.java"):to_string(), false, true)):next(),
        "No Java file found in the directory." .. dir:to_string()
      )
    )
  end

  local function preload_file_for_lsp(path)
    local buf = deps.bufadd(path:to_string())
    deps.bufload(path:to_string())
    return buf
  end

  local function wait(timeout_ms, condition, interval_ms)
    local start_time = deps.hrtime() / 1e6
    while true do
      if condition() then
        return true
      end
      local current_time = deps.hrtime() / 1e6
      if (current_time - start_time) > timeout_ms then
        return false
      end
      deps.sleep(interval_ms)
    end
  end

  return function(cwd)
    local started = deps.hrtime()
    if client_matches_cwd(client, cwd) then
      logger.warn(("[timing] reused existing jdtls client in %.1f ms"):format((deps.hrtime() - started) / 1e6))
      return client
    end

    client = find_client_for_cwd(cwd)
    if client then
      logger.warn(("[timing] found matching jdtls client in %.1f ms"):format((deps.hrtime() - started) / 1e6))
      return client
    end

    local any_java_file = find_any_java_file(cwd)
    local bufnr = preload_file_for_lsp(any_java_file)
    assert(
      wait(10000, function()
        client = deps.get_clients({ name = "jdtls", bufnr = bufnr })[1]
        return not not client and not not client.initialized
      end, 1000),
      "jdtls client not started in time"
    )
    logger.warn(("[timing] waited for jdtls startup in %.1f ms"):format((deps.hrtime() - started) / 1e6))
    return client
  end
end

return ClientProvider
