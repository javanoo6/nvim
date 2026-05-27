-- ./lua/plugins/lsp.lua

-- LSP: Language Server Protocol configuration
return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      { "j-hui/fidget.nvim", opts = {
        progress = {
          poll_rate = false,
        },
      } },
      "hrsh7th/cmp-nvim-lsp",
      "antosha417/nvim-lsp-file-operations",
    },
    config = function()
      local map = require("util").map
      local inlay_hints = require("util.inlay_hints")

      local function rename_symbol()
        local bufnr = vim.api.nvim_get_current_buf()
        if vim.bo[bufnr].filetype == "java" then
          vim.lsp.buf.rename(nil, {
            name = "jdtls",
            bufnr = bufnr,
          })
          return
        end

        vim.lsp.buf.rename()
      end

      vim.diagnostic.config({
        virtual_text = false,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = true,
        },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = require("util").augroup("lsp_attach"),
        callback = function(event)
          local opts = { buffer = event.buf }

          -- Register LSP keymaps in which-key (buffer-local, only shown in LSP buffers)
          require("which-key").add({
            { "gd", desc = "Goto Definitions", buffer = event.buf },
            { "gR", desc = "Goto References", buffer = event.buf },
            { "gy", desc = "Goto Type Definitions", buffer = event.buf },
            { "gI", desc = "Goto Implementations", buffer = event.buf },
            { "gD", desc = "Goto Declaration", buffer = event.buf },
            { "K", desc = "Hover", buffer = event.buf },
            { "gK", desc = "Signature Help", buffer = event.buf },
          })

          -- Glance
          map("n", "gd", "<cmd>Glance definitions<cr>", vim.tbl_extend("force", opts, { desc = "Goto Definitions" }))
          map("n", "gR", "<cmd>Glance references<cr>", vim.tbl_extend("force", opts, { desc = "Goto References" }))
          map("n", "gy", "<cmd>Glance type_definitions<cr>", vim.tbl_extend("force", opts, { desc = "Goto Type Definitions" }))
          map("n", "gI", "<cmd>Glance implementations<cr>", vim.tbl_extend("force", opts, { desc = "Goto Implementations" }))

          -- Native LSP
          map("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Goto declaration" }))
          map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))
          map("n", "gK", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
          -- <leader>ca is handled globally by actions-preview.nvim
          map("n", "<leader>cr", rename_symbol, vim.tbl_extend("force", opts, { desc = "Rename" }))

          -- Enable inlay hints if supported
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.server_capabilities.inlayHintProvider then
            vim.defer_fn(function()
              inlay_hints.apply_for_buffer(event.buf)
            end, 100)
          end

          if client and client.name == "jdtls" and client.server_capabilities.codeLensProvider then
            local group = require("util").augroup("java_codelens_" .. event.buf)

            local function refresh_codelens()
              if vim.api.nvim_buf_is_valid(event.buf) and vim.bo[event.buf].buflisted ~= false then
                pcall(vim.lsp.codelens.refresh, { bufnr = event.buf })
              end
            end

            vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
              group = group,
              buffer = event.buf,
              callback = refresh_codelens,
            })

            vim.schedule(refresh_codelens)
          end
        end,
      })

      -- LSP server management
      map("n", "<leader>lr", "<cmd>LspRestart<cr>", { desc = "Restart LSP" })
      map("n", "<leader>li", "<cmd>LspInfo<cr>", { desc = "LSP info" })
      map("n", "<leader>ll", "<cmd>LspLog<cr>", { desc = "LSP log" })

      local capabilities =
        vim.tbl_deep_extend("force", require("cmp_nvim_lsp").default_capabilities(), require("lsp-file-operations").default_capabilities())

      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "bashls",
          "helm_ls",
          "jsonls",
          "yamlls",
          "gopls",
          "pyright",
        },
        handlers = {
          function(server_name)
            if server_name ~= "jdtls" then
              require("lspconfig")[server_name].setup({
                capabilities = capabilities,
              })
            end
          end,

          -- Go specific
          ["gopls"] = function()
            require("lspconfig").gopls.setup({
              capabilities = capabilities,
              cmd = { "gopls" },
              filetypes = { "go", "gomod", "gowork", "gotmpl" },
              root_dir = require("lspconfig.util").root_pattern("go.work", "go.mod", ".git"),
              settings = {
                gopls = {
                  -- Auto-complete unimported packages
                  completeUnimported = true,
                  -- Use placeholders in function signatures
                  usePlaceholders = true,
                  -- Analyses
                  analyses = {
                    unusedparams = true,
                    shadow = true,
                  },
                  staticcheck = true,
                  gofumpt = true,
                  -- Inlay hints
                  hints = {
                    assignVariableTypes = true,
                    compositeLiteralFields = true,
                    compositeLiteralTypes = true,
                    constantValues = true,
                    functionTypeParameters = true,
                    parameterNames = true,
                    rangeVariableTypes = true,
                  },
                  ui = {
                    annotation = {
                      bounds = true,
                      escape = true,
                      inline = true,
                    },
                  },
                },
              },
            })
          end,

          ["helm_ls"] = function()
            require("lspconfig").helm_ls.setup({
              capabilities = capabilities,
            })
          end,

          -- Lua specific
          ["lua_ls"] = function()
            vim.lsp.config("lua_ls", {
              capabilities = capabilities,
              on_init = function(client)
                if client.workspace_folders then
                  local path = client.workspace_folders[1].name
                  if path ~= vim.fn.stdpath("config")
                    and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
                  then
                    return
                  end
                end

                client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua or {}, {
                  runtime = {
                    version = "LuaJIT",
                    path = {
                      "lua/?.lua",
                      "lua/?/init.lua",
                    },
                  },
                  diagnostics = {
                    globals = { "vim" },
                  },
                  workspace = {
                    checkThirdParty = false,
                    library = {
                      vim.env.VIMRUNTIME,
                      vim.api.nvim_get_runtime_file("lua", true),
                      vim.api.nvim_get_runtime_file("lua/lspconfig", false)[1],
                    },
                  },
                  telemetry = {
                    enable = false,
                  },
                  hint = {
                    enable = true,
                    arrayIndex = "Auto",
                    await = true,
                    awaitPropagate = true,
                    paramName = "Literal",
                    paramType = true,
                    setType = true,
                    semicolon = "Disable",
                  },
                })
              end,
              settings = {
                Lua = {},
              },
            })
            vim.lsp.enable("lua_ls")
          end,
        },
      })

      -- Rounded borders for floating windows
      local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
      function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
        opts = opts or {}
        opts.border = "rounded"
        return orig_util_open_floating_preview(contents, syntax, opts, ...)
      end

      -- Java keymaps (using <leader>j group defined in which-key)
      local map = require("util").map
      local java_debug = require("util.java_debug")
      local function jdtls_range_from_selection(bufnr, mode)
        local start_pos = vim.fn.getpos("v")
        local end_pos = vim.fn.getpos(".")
        local start_row = start_pos[2]
        local start_col = start_pos[3]
        local end_row = end_pos[2]
        local end_col = end_pos[3]

        if start_row == end_row and end_col < start_col then
          end_col, start_col = start_col, end_col
        elseif end_row < start_row then
          start_row, end_row = end_row, start_row
          start_col, end_col = end_col, start_col
        end

        if mode == "V" then
          start_col = 1
          local lines = vim.api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, true)
          end_col = #lines[1]
        end

        return {
          start = { start_row, start_col - 1 },
          ["end"] = { end_row, end_col - 1 },
        }
      end

      local function run_java_refactor(action_name)
        return function()
          local ok_factory, factory = pcall(require, "java-refactor.utils.instance-factory")
          if not ok_factory then
            vim.notify("nvim-java refactor API is unavailable", vim.log.levels.ERROR, { title = "nvim-java" })
            return
          end

          local ok_lsp, lsp_utils = pcall(require, "java-core.utils.lsp")
          if not ok_lsp then
            vim.notify("nvim-java LSP helpers are unavailable", vim.log.levels.ERROR, { title = "nvim-java" })
            return
          end

          local client = lsp_utils.get_jdtls()
          local bufnr = vim.api.nvim_get_current_buf()
          local mode = vim.api.nvim_get_mode().mode
          local params

          if mode == "v" or mode == "V" then
            local range = jdtls_range_from_selection(bufnr, mode)
            params = vim.lsp.util.make_given_range_params(range.start, range["end"], bufnr, client.offset_encoding)
          else
            params = vim.lsp.util.make_range_params(0, client.offset_encoding)
          end

          params.context = {
            diagnostics = vim.lsp.diagnostic.get_line_diagnostics(0),
            triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
            only = { "refactor.extract.variable" },
          }

          local ok_runner, runner = pcall(require, "async.runner")
          if not ok_runner then
            vim.notify("nvim-java async runner is unavailable", vim.log.levels.ERROR, { title = "nvim-java" })
            return
          end

          local ok_error_handler, get_error_handler = pcall(require, "java-refactor.utils.error_handler")
          if not ok_error_handler then
            vim.notify("nvim-java error handler is unavailable", vim.log.levels.ERROR, { title = "nvim-java" })
            return
          end

          runner(function()
            factory.get_action().refactor:refactor(action_name, params, nil)
          end)
            .catch(get_error_handler("Failed to apply Java refactoring"))
            .run()
        end
      end

      map("n", "<leader>jr", "<cmd>JavaRunnerRunMain<cr>", { desc = "Run Main" })
      map("n", "<leader>jd", java_debug.debug_main, { desc = "Debug Main" })
      map("n", "<leader>jc", "<cmd>JavaRunnerStopMain<cr>", { desc = "Stop Main" })
      map("n", "<leader>ja", java_debug.attach_remote, { desc = "Attach Remote JVM" })
      map("n", "<leader>jt", "<cmd>JavaTestRunCurrentClass<cr>", { desc = "Test Current Class" })
      map("n", "<leader>jT", "<cmd>JavaTestDebugCurrentClass<cr>", { desc = "Debug Current Class" })
      map("n", "<leader>jm", "<cmd>JavaTestRunCurrentMethod<cr>", { desc = "Test Current Method" })
      map("n", "<leader>jM", "<cmd>JavaTestDebugCurrentMethod<cr>", { desc = "Debug Current Method" })
      map("n", "<leader>jD", "<cmd>JavaTestDebugAllTests<cr>", { desc = "Debug All Tests" })
      map("n", "<leader>jv", "<cmd>JavaTestViewLastReport<cr>", { desc = "View Test Report" })

    end,
  },

  -- Code action preview with diff (replaces default code action picker)
  {
    "aznhe21/actions-preview.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local actions = require("actions-preview")

      require("actions-preview").setup({
        telescope = {
          sorting_strategy = "ascending",
          layout_strategy = "vertical",
          layout_config = {
            width = 0.8,
            height = 0.9,
            prompt_position = "bottom",
            preview_cutoff = 20,
          },
        },
      })

      local function code_actions_from_any_mode()
        if vim.fn.mode() == "i" then
          vim.cmd("stopinsert")
          vim.schedule(actions.code_actions)
          return
        end

        actions.code_actions()
      end

      vim.keymap.set({ "n", "v" }, "<leader>ca", actions.code_actions, { desc = "Code action" })
      vim.keymap.set({ "n", "v", "i" }, "<A-CR>", code_actions_from_any_mode, { desc = "Code action" })
    end,
  },

  -- Inline diagnostics with wrapping support (replaces built-in virtual_text/virtual_lines)
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000,
    opts = {
      preset = "modern",
      options = {
        show_source = true,
        use_icons_from_diagnostic = true,
        multilines = {
          enabled = true,
          always_show = false,
        },
        overflow = {
          mode = "wrap",
        },
        break_line = {
          enabled = true,
          after = 80,
        },
      },
    },
    config = function(_, opts)
      local tid = require("tiny-inline-diagnostic")
      tid.setup(opts)
      tid.enable()
      vim.diagnostic.config({ virtual_text = false })
    end,
  },
}
