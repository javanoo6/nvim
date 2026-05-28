-- ./lua/plugins/nvim-java.lua

return {
  "nvim-java/nvim-java",
  dependencies = {
    "JavaHello/spring-boot.nvim",
  },
  config = function()
    local java21_home = "/usr/lib/jvm/java-21-openjdk-amd64"
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
