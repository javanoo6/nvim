return {
  "JetBrains/intellij-lsp.nvim",
  commit = "9cfad18005470e4187090013e08f92ec9e437219",
  lazy = false,
  dependencies = { "hrsh7th/cmp-nvim-lsp", "antosha417/nvim-lsp-file-operations", "mfussenegger/nvim-dap" },
  opts = function()
    return {
      accept_eula = true, -- User accepted bundle 263.6379.0 EULA on 2026-10-10.
      default_sdk = vim.env.NVIM_JAVA_HOME or vim.env.JAVA_HOME or "/usr/lib/jvm/java-21-openjdk-amd64",
      filetypes = { "java" },
      autotrigger = false,
      word_triggers = false,
      completeopt = false,
      enter_accepts_completion = false,
      signature_help = false,
      keymaps = false,
      references = false,
      colorscheme = false,
      git = false,
      single_key_select = false,
      folding = false,
      inlay_hints = false, -- Existing repo hint controls own this setting.
      inlay_hint_settings = {
        jetbrains = {
          java = {
            ["hints.collapse complex types"] = false,
          },
        },
      },
      file_templates = true,
      format_on_save = false,
      run = false, -- Scoped launch/UI setup is owned by our helpers.
      debug = false,
    }
  end,
  config = function(_, opts)
    require("util.java_intellij").setup(opts)
    require("util.debug_ui").setup()
    require("util.java_launch").setup()
    require("util.java_workspace").setup()
  end,
}
