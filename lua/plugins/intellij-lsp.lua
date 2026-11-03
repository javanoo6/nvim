return {
  "JetBrains/intellij-lsp.nvim",
  commit = "77dc3e118a381e59f0d0b3e368e4b3a088280ab7",
  lazy = false,
  dependencies = { "hrsh7th/cmp-nvim-lsp", "antosha417/nvim-lsp-file-operations", "mfussenegger/nvim-dap" },
  opts = function()
    return {
      -- Upstream asks for consent to this bundle's agreement and remembers it.
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
      jvm_args = {
        "-Xms128m",
        "-Xmx1024m",
        "-XX:ReservedCodeCacheSize=512m",
        "-XX:+IgnoreUnrecognizedVMOptions",
        "-XX:+UseG1GC",
        "-XX:SoftRefLRUPolicyMSPerMB=50",
        "-XX:CICompilerCount=2",
        "-XX:+HeapDumpOnOutOfMemoryError",
        "-XX:-OmitStackTraceInFastThrow",
        "-ea",
        "-Dsun.io.useCanonCaches=false",
        "-Djdk.http.auth.tunneling.disabledSchemes=",
        "-Djdk.attach.allowAttachSelf=true",
        "-Djdk.module.illegalAccess.silent=true",
        "-Dkotlinx.coroutines.debug=off",
        "-XX:ErrorFile=" .. vim.fn.expand("~/java_error_in_idea_%p.log"),
        "-XX:HeapDumpPath=" .. vim.fn.expand("~/java_error_in_idea.hprof"),
        "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED",
        "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED",
        "-javaagent:/home/konkov/Desktop/APPS/mine-javafilter.jar=jetbrains",
      },
    }
  end,
  config = function(_, opts)
    require("util.java_intellij").setup(opts)
    require("util.debug_ui").setup()
    require("util.java_launch").setup()
    require("util.java_workspace").setup()
  end,
}
