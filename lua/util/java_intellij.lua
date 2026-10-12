local M = {}
local original_config
local original_find_root

function M.is_source_buffer(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  -- Diffview revision/index buffers can have buftype="" and filetype=java.
  -- Walking their virtual URI finds cwd's pom.xml as ".", yielding file://.
  -- Reject URI schemes, but retain Windows drive paths (C:/ or C:\).
  local virtual = name:match("^%a[%w+.-]*:") and not name:match("^%a:[/\\]")
  return vim.bo[bufnr].buftype == "" and name ~= "" and not virtual
end

function M.unavailable(action, step)
  vim.notify(action .. " is pending IntelliJ migration Step " .. step, vim.log.levels.WARN, { title = "Java" })
end

function M.project_options(root, opts)
  local cfg = vim.deepcopy(opts)
  if not cfg.build_tool and vim.uv.fs_stat(root .. "/pom.xml") then
    for _, name in ipairs({ "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts", "gradlew" }) do
      if vim.uv.fs_stat(root .. "/" .. name) then
        cfg.build_tool = "maven"
        break
      end
    end
  end
  return cfg
end

function M.setup(opts)
  vim.lsp.enable("jdtls", false)
  local plugin = require("intellij-lsp")
  vim.api.nvim_create_user_command("JavaInfo", function()
    local client = vim.lsp.get_clients({ bufnr = 0, name = "intellij" })[1]
    local cfg = plugin.config
    local status, detail = require("intellij-lsp.server_download").status(cfg)
    local progress = require("intellij-lsp.status")
    local state = client and (progress.describe(progress.get(client.id)) or "idle") or "unavailable"
    local lines = {
      "backend: IntelliJ LSP (JDTLS disabled)",
      "EULA accepted: " .. tostring(opts.accept_eula),
      "analysis JDK: " .. opts.default_sdk,
      "server bundle: " .. require("intellij-lsp.server_bundles").version,
      "server: " .. tostring(cfg.server_path or detail),
      "bundle status: " .. tostring(status),
      "client: " .. (client and (client.name .. " #" .. client.id) or "not attached"),
      "root: " .. tostring(client and client.config.root_dir),
      "state: " .. state,
      "initial import complete: " .. tostring(client and require("intellij-lsp.progress").is_ready(client.id) or false),
    }
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "JavaInfo" })
  end, { desc = "Show IntelliJ Java backend configuration" })

  -- Until acceptance, keep the plugin inspectable without launching a server
  -- that is guaranteed to reject its missing --eula argument.
  if not opts.accept_eula then
    plugin.config = opts
    return
  end

  local factory = require("intellij-lsp.client")
  original_find_root = original_find_root or factory.find_root
  factory.find_root = function(bufnr)
    if not M.is_source_buffer(bufnr) then
      return nil
    end
    return original_find_root(bufnr)
  end
  local editor_commands = require("intellij-lsp.extensions").EDITOR_COMMANDS
  editor_commands["editor.action.triggerSuggest"] = function()
    if vim.fn.mode():sub(1, 1) == "i" then
      require("cmp").complete()
    end
  end
  editor_commands["editor.action.rename"] = function()
    vim.lsp.buf.rename(nil, { name = "intellij", bufnr = vim.api.nvim_get_current_buf() })
  end
  original_config = original_config or factory.config
  factory.config = function(root, cfg)
    cfg = M.project_options(root, cfg)
    local config = original_config(root, cfg)
    config.capabilities = vim.tbl_deep_extend(
      "force",
      config.capabilities,
      require("cmp_nvim_lsp").default_capabilities(),
      require("lsp-file-operations").default_capabilities()
    )
    local on_attach = config.on_attach
    config.on_attach = function(client, bufnr)
      on_attach(client, bufnr)
      -- Upstream enables built-in completion even with autotrigger=false.
      -- nvim-cmp owns completion in this config.
      vim.lsp.completion.enable(false, client.id, bufnr)
    end
    return config
  end
  plugin.setup(opts)
  require("util.java_file_templates").setup()
end

return M
