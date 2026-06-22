-- ./lua/plugins/lsp.lua

-- LSP: Language Server Protocol configuration
return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "LspInfo", "PyrightInfo", "PythonLspUsePyright", "PythonLspUseBasedPyright" },
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
      local java_codelens = require("util.java_codelens")
      local java_field_usages = require("util.java_field_usages")
      local inlay_hints = require("util.inlay_hints")
      java_field_usages.setup()
      inlay_hints.setup()
      local function resolve_pyright_cmd()
        local exepath = vim.fn.exepath("pyright-langserver")
        if exepath ~= "" then
          return { exepath, "--stdio" }, exepath
        end

        local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/pyright-langserver"
        if vim.fn.executable(mason_bin) == 1 then
          return { mason_bin, "--stdio" }, mason_bin
        end

        return { "pyright-langserver", "--stdio" }, nil
      end

      vim.api.nvim_create_user_command("PyrightInfo", function()
        local cmd, resolved = resolve_pyright_cmd()
        local lines = {
          "Pyright command: " .. table.concat(cmd, " "),
          "Resolved binary: " .. (resolved or "<not found>"),
          "exepath('pyright-langserver'): " .. vim.fn.exepath("pyright-langserver"),
          "node: " .. vim.fn.exepath("node"),
          "PATH: " .. (vim.env.PATH or ""),
        }
        vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "PyrightInfo" })
      end, { desc = "Show resolved Pyright command info" })

      local function show_lsp_info()
        if vim.fn.exists(":LspInfo") == 2 then
          vim.cmd("LspInfo")
          return
        end

        vim.cmd("checkhealth vim.lsp")
      end

      local function rename_symbol()
        local original_handler = vim.lsp.handlers["textDocument/rename"]
        local restored = false

        local function restore_handler()
          if restored then
            return
          end

          restored = true
          if vim.lsp.handlers["textDocument/rename"] ~= original_handler then
            vim.lsp.handlers["textDocument/rename"] = original_handler
          end
        end

        vim.lsp.handlers["textDocument/rename"] = function(...)
          local result = { pcall(original_handler, ...) }
          local ok = table.remove(result, 1)
          vim.schedule(function()
            inlay_hints.refresh_loaded_buffers()
            restore_handler()
          end)
          if not ok then
            error(result[1])
          end

          return unpack(result)
        end

        vim.defer_fn(restore_handler, 120000)

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
      vim.diagnostic.enable(true)
      vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
        config = vim.tbl_extend("force", config or {}, { border = "rounded" })
        return vim.lsp.handlers.hover(err, result, ctx, config)
      end
      vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
        config = vim.tbl_extend("force", config or {}, { border = "rounded" })
        return vim.lsp.handlers.signature_help(err, result, ctx, config)
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        group = require("util").augroup("lsp_attach"),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
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
          if client and client.server_capabilities.inlayHintProvider then
            vim.defer_fn(function()
              inlay_hints.apply_for_buffer(event.buf)
            end, 100)
          end

          if client and client.name == "jdtls" and client.server_capabilities.codeLensProvider then
            java_codelens.attach(event.buf, client)
          end

          if client and client.name == "jdtls" then
            java_field_usages.attach(event.buf, client)
          end
        end,
      })

      -- LSP server management
      map("n", "<leader>lr", "<cmd>LspRestart<cr>", { desc = "Restart LSP" })
      map("n", "<leader>li", show_lsp_info, { desc = "LSP info" })
      map("n", "<leader>ll", "<cmd>LspLog<cr>", { desc = "LSP log" })

      local capabilities =
        vim.tbl_deep_extend("force", require("cmp_nvim_lsp").default_capabilities(), require("lsp-file-operations").default_capabilities())

      local pyright_cmd = resolve_pyright_cmd()
      vim.lsp.config("pyright", {
        capabilities = capabilities,
        cmd = pyright_cmd,
      })
      vim.lsp.enable("pyright")

      vim.lsp.config("basedpyright", {
        capabilities = capabilities,
      })

      local function switch_python_lsp(server_name)
        local stopped = {}
        for _, client in ipairs(vim.lsp.get_clients()) do
          if client.name == "pyright" or client.name == "basedpyright" then
            stopped[client.name] = true
            client:stop(true)
          end
        end

        vim.defer_fn(function()
          vim.lsp.enable(server_name)
          vim.notify("Python LSP enabled: " .. server_name, vim.log.levels.INFO)
        end, next(stopped) and 100 or 0)
      end

      vim.api.nvim_create_user_command("PythonLspUsePyright", function()
        switch_python_lsp("pyright")
      end, { desc = "Use pyright for Python buffers" })

      vim.api.nvim_create_user_command("PythonLspUseBasedPyright", function()
        switch_python_lsp("basedpyright")
      end, { desc = "Use basedpyright for Python buffers" })

      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "bashls",
          "helm_ls",
          "jsonls",
          "yamlls",
          "gopls",
          "pyright",
          "basedpyright",
          "ts_ls",
        },
        automatic_enable = {
          exclude = { "pyright", "basedpyright" },
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

          -- Lua specific
          ["lua_ls"] = function()
            vim.lsp.config("lua_ls", {
              capabilities = capabilities,
              on_init = function(client)
                if client.workspace_folders then
                  local path = client.workspace_folders[1].name
                  if
                    path ~= vim.fn.stdpath("config")
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

      -- Java keymaps (using <leader>j group defined in which-key)
      local java_debug = require("util.java_debug")
      local java_runner = require("util.java_runner")
      map("n", "<leader>jr", java_runner.run_main, { desc = "Run Main" })
      map("n", "<leader>jd", java_debug.debug_main, { desc = "Debug Main" })
      map("n", "<leader>jc", java_runner.stop_main, { desc = "Stop Main" })
      map("n", "<leader>jl", java_runner.toggle_logs, { desc = "Toggle Runner Logs" })
      map("n", "<leader>ja", java_debug.attach_remote, { desc = "Attach Remote JVM" })
    end,
  },

  -- Code action preview with diff (replaces default code action picker)
  {
    "aznhe21/actions-preview.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local function native_code_action()
        vim.lsp.buf.code_action()
      end

      local function set_code_action_maps(code_action)
        local function code_actions_from_any_mode()
          if vim.fn.mode() == "i" then
            vim.cmd("stopinsert")
            vim.schedule(code_action)
            return
          end

          code_action()
        end

        vim.keymap.set({ "n", "v" }, "<leader>ca", code_action, { desc = "Code action" })
        vim.keymap.set({ "n", "v", "i" }, "<A-CR>", code_actions_from_any_mode, { desc = "Code action" })
      end

      local actions_ok, actions = pcall(require, "actions-preview")
      local hl_ok, hl = pcall(require, "actions-preview.highlight")
      local themes_ok, themes = pcall(require, "telescope.themes")
      local entry_display_ok, entry_display = pcall(require, "telescope.pickers.entry_display")

      if not (actions_ok and hl_ok and themes_ok and entry_display_ok) then
        vim.notify("actions-preview unavailable; using native LSP code actions", vim.log.levels.WARN)
        set_code_action_maps(native_code_action)
        return
      end

      local function classify_action(action)
        local raw = action.action or {}
        local has_edit = raw.edit ~= nil
        local has_command = raw.command ~= nil
        local label

        if has_edit and has_command then
          label = "edit+cmd"
        elseif has_edit then
          label = "diff"
        elseif has_command then
          label = "cmd"
        else
          label = "plain"
        end

        return {
          client = action:client_name(),
          has_edit = has_edit,
          has_command = has_command,
          label = label,
        }
      end

      local function make_value(action)
        local meta = classify_action(action)
        local title = string.format("[%s] %s", meta.label, action:title())

        return {
          title = title,
          client_name = meta.client,
          meta = meta,
          -- Keep previewable actions grouped before command-only ones.
          ordinal = string.format("%d %d %s %s", meta.has_edit and 0 or 1, meta.has_command and 1 or 0, meta.client, action:title()),
        }
      end

      local function make_make_display()
        local displayer = entry_display.create({
          separator = " ",
          items = {
            { width = 8 },
            { width = 12 },
            { remaining = true },
          },
        })

        return function(entry)
          local value = entry.value
          local meta = value.meta or {}
          local kind_hl = meta.has_edit and "DiagnosticOk" or (meta.has_command and "DiagnosticWarn" or "Comment")

          return displayer({
            { string.format("[%s]", meta.label or "plain"), kind_hl },
            { value.client_name or "", "Comment" },
            { value.title or "", "Normal" },
          })
        end
      end

      local setup_ok = pcall(actions.setup, {
        diff = {
          algorithm = "patience",
          ignore_whitespace = true,
          ctxlen = 4,
        },
        highlight_command = {
          function()
            return hl.delta()
          end,
        },
        telescope = vim.tbl_extend(
          "force",
          themes.get_dropdown({
            layout_config = {
              width = 0.85,
            },
          }),
          {
            sorting_strategy = "ascending",
            layout_strategy = "vertical",
            layout_config = {
              width = 0.85,
              height = 0.9,
              prompt_position = "top",
              preview_cutoff = 20,
              preview_height = function(_, _, max_lines)
                return math.max(15, max_lines - 12)
              end,
            },
            make_value = make_value,
            make_make_display = make_make_display,
          }
        ),
      })

      if not setup_ok then
        vim.notify("actions-preview setup failed; using native LSP code actions", vim.log.levels.WARN)
        set_code_action_maps(native_code_action)
        return
      end

      local function preview_or_native_code_action()
        local ok = pcall(actions.code_actions)
        if ok then
          return
        end

        vim.notify("actions-preview failed; using native LSP code actions", vim.log.levels.WARN)
        native_code_action()
      end

      set_code_action_maps(preview_or_native_code_action)
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
      vim.schedule(function()
        tid.enable()
      end)
      vim.diagnostic.config({ virtual_text = false })
    end,
  },
}
