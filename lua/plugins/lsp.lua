-- ./lua/plugins/lsp.lua

-- LSP: Language Server Protocol configuration
return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"hrsh7th/cmp-nvim-lsp",
			"antosha417/nvim-lsp-file-operations",
		},
		config = function()
			local map = require("util").map

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
						{ "gd", desc = "Goto Definitions",     buffer = event.buf },
						{ "gR", desc = "Goto References",      buffer = event.buf },
						{ "gy", desc = "Goto Type Definitions", buffer = event.buf },
						{ "gI", desc = "Goto Implementations", buffer = event.buf },
						{ "gD", desc = "Goto Declaration",     buffer = event.buf },
						{ "K",  desc = "Hover",                buffer = event.buf },
						{ "gK", desc = "Signature Help",       buffer = event.buf },
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
					map("n", "<leader>cr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))

					-- Enable inlay hints if supported
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.server_capabilities.inlayHintProvider then
						vim.defer_fn(function()
							vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
						end, 100)
					end

					-- Toggle inlay hints keymap
					map("n", "<leader>uh", function()
						local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
						vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
					end, vim.tbl_extend("force", opts, { desc = "Toggle inlay hints" }))
				end,
			})

			-- LSP server management
			map("n", "<leader>lr", "<cmd>LspRestart<cr>", { desc = "Restart LSP" })
			map("n", "<leader>li", "<cmd>LspInfo<cr>", { desc = "LSP info" })
			map("n", "<leader>ll", "<cmd>LspLog<cr>", { desc = "LSP log" })

			local capabilities = vim.tbl_deep_extend(
				"force",
				require("cmp_nvim_lsp").default_capabilities(),
				require("lsp-file-operations").default_capabilities()
			)

			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"bashls",
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

					-- Lua specific
					["lua_ls"] = function()
						require("lspconfig").lua_ls.setup({
							capabilities = capabilities,
							settings = {
								Lua = {
									diagnostics = { globals = { "vim" } },
									workspace = { checkThirdParty = false },
								},
							},
						})
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
			map("n", "<leader>jr", "<cmd>JavaRunnerRunMain<cr>", { desc = "Run Main" })
			map("n", "<leader>jc", "<cmd>JavaRunnerStopMain<cr>", { desc = "Stop Main" })
			map("n", "<leader>jt", "<cmd>JavaTestRunCurrentClass<cr>", { desc = "Test Current Class" })
			map("n", "<leader>jm", "<cmd>JavaTestRunCurrentMethod<cr>", { desc = "Test Current Method" })
			map("n", "<leader>jv", "<cmd>JavaTestViewLastReport<cr>", { desc = "View Test Report" })

			-- Java refactor / generate keymaps (filetype-local, jdtls code actions)
			local function jdtls_action(kind)
				return function()
					vim.lsp.buf.code_action({ context = { only = { kind } } })
				end
			end

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				group = require("util").augroup("java_keymaps"),
				callback = function(event)
					local opts = { buffer = event.buf }
					-- Refactor
					map("n", "<leader>jRe", jdtls_action("refactor.extract.function"),    vim.tbl_extend("force", opts, { desc = "Extract function" }))
					map("n", "<leader>jRv", jdtls_action("refactor.extract.variable"),    vim.tbl_extend("force", opts, { desc = "Extract variable" }))
					map("n", "<leader>jRc", jdtls_action("refactor.extract.constant"),    vim.tbl_extend("force", opts, { desc = "Extract constant" }))
					map("n", "<leader>jRf", jdtls_action("refactor.extract.field"),       vim.tbl_extend("force", opts, { desc = "Extract field" }))
					map("n", "<leader>jRi", jdtls_action("refactor.extract.interface"),   vim.tbl_extend("force", opts, { desc = "Extract interface" }))
					map("n", "<leader>jRp", jdtls_action("refactor.introduce.parameter"), vim.tbl_extend("force", opts, { desc = "Introduce parameter" }))
					map("n", "<leader>jRs", jdtls_action("refactor.change.signature"),    vim.tbl_extend("force", opts, { desc = "Change signature" }))
					map("n", "<leader>jRm", jdtls_action("refactor.move"),                vim.tbl_extend("force", opts, { desc = "Move" }))
					map("n", "<leader>jRa", jdtls_action("refactor.assign.variable"),     vim.tbl_extend("force", opts, { desc = "Assign variable" }))
					map("n", "<leader>jRq", jdtls_action("quickassist"),                  vim.tbl_extend("force", opts, { desc = "Quick assist" }))
					-- Generate
					map("n", "<leader>jga", jdtls_action("source.generate.accessors"),       vim.tbl_extend("force", opts, { desc = "Accessors" }))
					map("n", "<leader>jgc", jdtls_action("source.generate.constructors"),     vim.tbl_extend("force", opts, { desc = "Constructors" }))
					map("n", "<leader>jgd", jdtls_action("source.generate.delegateMethods"),  vim.tbl_extend("force", opts, { desc = "Delegate methods" }))
					map("n", "<leader>jgf", jdtls_action("source.generate.finalModifiers"),   vim.tbl_extend("force", opts, { desc = "Final modifiers" }))
					map("n", "<leader>jgh", jdtls_action("source.generate.hashCodeEquals"),   vim.tbl_extend("force", opts, { desc = "hashCode / equals" }))
					map("n", "<leader>jgt", jdtls_action("source.generate.toString"),         vim.tbl_extend("force", opts, { desc = "toString" }))
					map("n", "<leader>jgo", jdtls_action("source.overrideMethods"),           vim.tbl_extend("force", opts, { desc = "Override methods" }))
					map("n", "<leader>jgs", jdtls_action("source.sortMembers"),               vim.tbl_extend("force", opts, { desc = "Sort members" }))
				end,
			})
		end,
	},

	-- Code action preview with diff (replaces default code action picker)
	{
		"aznhe21/actions-preview.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
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
			vim.keymap.set({ "n", "v" }, "<leader>ca", require("actions-preview").code_actions, { desc = "Code action" })
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
