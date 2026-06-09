-- ./lua/plugins/nvim-java.lua

return {
  "nvim-java/nvim-java",
  dependencies = {
    "JavaHello/spring-boot.nvim",
  },
  config = function()
    local java21_home = vim.env.NVIM_JAVA_HOME or vim.env.JAVA_HOME or "/usr/lib/jvm/java-21-openjdk-amd64"
    if vim.fn.isdirectory(java21_home) ~= 1 then
      vim.notify("Java home missing: " .. java21_home, vim.log.levels.WARN, { title = "nvim-java" })
    end
    local java21_bin = java21_home .. "/bin"
    local java_jdtls = require("util.java_jdtls")
    local java_patches = require("util.java_patches")
    local jdtls_build = java_jdtls.resolve_local_build()
    local default_jdtls_version = jdtls_build.default_jdtls_version
    local jdtls_version = jdtls_build.jdtls_version
    local jdtls_dir_override = jdtls_build.jdtls_dir_override
    local capabilities =
      vim.tbl_deep_extend("force", require("cmp_nvim_lsp").default_capabilities(), require("lsp-file-operations").default_capabilities())
    local debug_log = java_jdtls.make_debug_log()

    local function has_root_file(root_dir, name)
      return root_dir and vim.uv.fs_stat(root_dir .. "/" .. name) ~= nil
    end

    local function should_prefer_maven(root_dir)
      if not has_root_file(root_dir, "pom.xml") then
        return false
      end

      return has_root_file(root_dir, "build.gradle")
        or has_root_file(root_dir, "build.gradle.kts")
        or has_root_file(root_dir, "settings.gradle")
        or has_root_file(root_dir, "settings.gradle.kts")
        or has_root_file(root_dir, "gradlew")
    end

    vim.api.nvim_create_user_command("JavaInfo", function()
      local bufnr = vim.api.nvim_get_current_buf()
      local client = vim.lsp.get_clients({ bufnr = bufnr, name = "jdtls" })[1] or vim.lsp.get_clients({ name = "jdtls" })[1]
      local root_dir = client and client.config and client.config.root_dir or require("util").get_root(bufnr)
      local prefer_maven = should_prefer_maven(root_dir)
      local lines = {
        "JAVA_HOME: " .. java21_home,
        "java: " .. (vim.fn.executable(java21_bin .. "/java") == 1 and (java21_bin .. "/java") or vim.fn.exepath("java")),
        "JDTLS version: " .. tostring(jdtls_version),
        "JDTLS dir: " .. (jdtls_dir_override or "package-managed"),
        "root: " .. tostring(root_dir),
        "mixed Maven/Gradle root: " .. tostring(prefer_maven),
        "import.maven.enabled: true",
        "import.gradle.enabled: " .. tostring(not prefer_maven),
      }

      if client then
        lines[#lines + 1] = "client: " .. client.name .. " #" .. client.id
        local server_info = client.server_info or {}
        if server_info.version then
          lines[#lines + 1] = "server version: " .. tostring(server_info.version)
        end
      else
        lines[#lines + 1] = "client: not attached"
      end

      vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "JavaInfo" })
    end, { desc = "Show Java/JDTLS configuration for the current buffer" })

    -- Allow pinning a released JDTLS milestone or pointing at a manually
    -- unpacked custom build without editing the plugin itself. Default to
    -- the local JDTLS build when it exists so Neovim uses the patched server.
    java_jdtls.patch_pkgm_install_dir(jdtls_dir_override)
    java_jdtls.register_info_command(jdtls_dir_override, jdtls_version)

    require("java").setup({
      checks = {
        nvim_version = true,
        nvim_jdtls_conflict = true,
      },
      jdtls = {
        version = jdtls_version,
      },
      lombok = { enable = true },
      java_test = { enable = true },
      java_debug_adapter = { enable = true },
      spring_boot_tools = { enable = true },
      jdk = { auto_install = false },
      log = {
        use_console = false,
        use_file = true,
        level = "warn",
        log_file = vim.fn.stdpath("state") .. "/nvim-java.log",
        max_lines = 1000,
        show_location = false,
      },
    })

    -- Guard nvim-java against malformed/empty JDTLS payloads.
    java_patches.apply_refactor_patches(debug_log)

    -- Patch nvim-java's hardcoded -Xms1G with custom heap sizes.
    -- Must happen after setup() so the module is already loaded.
    java_jdtls.patch_jdtls_cmd({
      default_jdtls_version = default_jdtls_version,
      jdtls_version = jdtls_version,
      jdtls_dir_override = jdtls_dir_override,
    })

    vim.lsp.config("jdtls", {
      capabilities = capabilities,
      before_init = function(params, config)
        local root_dir = config.root_dir
        local prefer_maven = should_prefer_maven(root_dir)

        config.settings = config.settings or {}
        config.settings.java = config.settings.java or {}
        config.settings.java["import"] = config.settings.java["import"] or {}
        config.settings.java["import"].maven = config.settings.java["import"].maven or {}
        config.settings.java["import"].gradle = config.settings.java["import"].gradle or {}

        if prefer_maven then
          config.settings.java["import"].maven.enabled = true
          config.settings.java["import"].gradle.enabled = false
        end

        params.initializationOptions = params.initializationOptions or {}
        params.initializationOptions.settings = vim.deepcopy(config.settings)
      end,
      flags = {
        -- The local JDTLS build can assert while applying incremental
        -- textDocument/didChange edits, which leaves its in-memory source out
        -- of sync and produces bogus parse diagnostics around comments.
        allow_incremental_sync = false,
      },
      cmd_env = {
        JAVA_HOME = java21_home,
        PATH = java21_bin .. ":" .. vim.env.PATH,
      },
      settings = {
        java = {
          configuration = {
            runtimes = {
              {
                name = "JavaSE-21",
                path = java21_home,
                default = true,
              },
            },
          },
          ["import"] = {
            maven = {
              enabled = true,
            },
            gradle = {
              enabled = true,
            },
          },
          maven = {
            -- Prefer attached dependency sources over decompiled class files
            -- when Maven artifacts publish -sources.jar files.
            downloadSources = true,
          },
          referencesCodeLens = {
            enabled = true,
          },
          implementationsCodeLens = {
            enabled = true,
          },
          inlayHints = {
            parameterNames = {
              -- JDTLS parameter-name hints regularly return invalid or unstable
              -- positions for chained/generic calls in this setup, which
              -- causes misplaced labels and Neovim 0.11 inlay-hint extmark
              -- errors ("Invalid 'col': out of range").
              enabled = "none",
            },
            parameterTypes = {
              enabled = true,
            },
            variableTypes = {
              enabled = true,
            },
            formatParameters = {
              enabled = true,
            },
          },
        },
      },
    })

    vim.lsp.enable("jdtls")
  end,
}
