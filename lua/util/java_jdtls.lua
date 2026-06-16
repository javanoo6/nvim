local M = {}

function M.resolve_local_build()
  local local_jdtls_dir = "/home/konkov/Desktop/JDTLS/eclipse.jdt.ls/org.eclipse.jdt.ls.product/target/repository"
  local has_local_jdtls = vim.uv.fs_stat(local_jdtls_dir) ~= nil
  local default_jdtls_version = has_local_jdtls and "local-recordrefactor" or "1.54.0"
  local jdtls_version = vim.env.NVIM_JDTLS_VERSION or default_jdtls_version
  local jdtls_dir_override = vim.env.NVIM_JDTLS_DIR

  if not jdtls_dir_override or jdtls_dir_override == "" then
    jdtls_dir_override = has_local_jdtls and local_jdtls_dir or nil
  end

  return {
    default_jdtls_version = default_jdtls_version,
    jdtls_version = jdtls_version,
    jdtls_dir_override = jdtls_dir_override,
  }
end

function M.make_debug_log()
  local debug_enabled = vim.env.NVIM_JDTLS_DEBUG == "1"
  if not debug_enabled then
    return function() end
  end

  local debug_log_path = vim.fn.stdpath("state") .. "/java-refactor-debug.log"
  return function(label, payload)
    local ok, encoded = pcall(vim.json.encode, payload)
    local line = string.format("%s %s %s\n", os.date("%Y-%m-%d %H:%M:%S"), label, ok and encoded or vim.inspect(payload))
    vim.fn.writefile({ line }, debug_log_path, "a")
  end
end

function M.patch_pkgm_install_dir(jdtls_dir_override)
  if not jdtls_dir_override or jdtls_dir_override == "" then
    return
  end

  local Manager = require("pkgm.manager")
  local orig_get_install_dir = Manager.get_install_dir

  Manager.get_install_dir = function(self, name, version)
    if name == "jdtls" then
      return jdtls_dir_override
    end

    return orig_get_install_dir(self, name, version)
  end
end

function M.patch_jdtls_cmd(opts)
  local jdtls_cmd = require("java-core.ls.servers.jdtls.cmd")
  local java_version_map = require("java-core.constants.java_version")
  local orig_get_jvm_args = jdtls_cmd.get_jvm_args
  local orig_validate_java_version = jdtls_cmd.validate_java_version
  local warned_validate_skip = false

  jdtls_cmd.get_jvm_args = function(cfg)
    local list = orig_get_jvm_args(cfg)
    for i, v in ipairs(list) do
      if v == "-Xms1G" then
        list[i] = "-Xms2G"
        break
      end
    end
    list:push("-Xmx8G")
    return list
  end

  if opts.jdtls_version ~= opts.default_jdtls_version or (opts.jdtls_dir_override and opts.jdtls_dir_override ~= "") then
    jdtls_cmd.validate_java_version = function(cfg, env)
      local version = cfg.jdtls and cfg.jdtls.version or opts.jdtls_version
      if not java_version_map[version] then
        if not warned_validate_skip then
          warned_validate_skip = true
          vim.notify(
            string.format("Skipping nvim-java JDTLS version gate for custom JDTLS %s", version),
            vim.log.levels.WARN,
            { title = "nvim-java" }
          )
        end
        return
      end

      local ok, current_version = pcall(orig_validate_java_version, cfg, env)
      if ok then
        return current_version
      end

      vim.notify(
        string.format("Skipping nvim-java JDTLS version gate for custom JDTLS %s", opts.jdtls_version),
        vim.log.levels.WARN,
        { title = "nvim-java" }
      )
    end
  end
end

function M.register_info_command(jdtls_dir_override, jdtls_version)
  vim.api.nvim_create_user_command("JdtlsLocalInfo", function()
    local info = {
      configured_dir = jdtls_dir_override or "package-managed",
      configured_version = jdtls_version,
    }

    local clients = vim.lsp.get_clients({ name = "jdtls" })
    local client = clients[1]
    if client then
      local server_info = client.server_info or {}
      info.active_client = {
        id = client.id,
        root_dir = client.config and client.config.root_dir or nil,
        name = server_info.name,
        version = server_info.version,
      }
    else
      info.active_client = "not attached"
    end

    if jdtls_dir_override and jdtls_dir_override ~= "" then
      local plugins = vim.fn.glob(jdtls_dir_override .. "/plugins/org.eclipse.jdt.core.manipulation_*.jar", false, true)
      info.core_manipulation_bundle = plugins[1] or "missing"
    end

    vim.notify(vim.inspect(info), vim.log.levels.INFO, { title = "JDTLS Local Info" })
  end, {
    desc = "Show the configured local JDTLS directory and active server info",
  })
end

return M
