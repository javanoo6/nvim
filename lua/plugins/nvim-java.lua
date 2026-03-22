-- ./lua/plugins/nvim-java.lua

return {
	"nvim-java/nvim-java",
	config = function()
		require("java").setup({
			checks = {
				nvim_version = true,
				nvim_jdtls_conflict = true,
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

		-- Patch nvim-java's hardcoded -Xms1G with custom heap sizes.
		-- Must happen after setup() so the module is already loaded.
		local jdtls_cmd = require('java-core.ls.servers.jdtls.cmd')
		local orig_get_jvm_args = jdtls_cmd.get_jvm_args
		jdtls_cmd.get_jvm_args = function(cfg)
			local list = orig_get_jvm_args(cfg)
			for i, v in ipairs(list) do
				if v == '-Xms1G' then
					list[i] = '-Xms2G'
					break
				end
			end
			list:push('-Xmx8G')
			return list
		end

		-- nvim-java's jdtls schema only accepts { version } — vmargs and settings
		-- are silently ignored there. Use vim.lsp.config directly; nvim-java calls
		-- the same API internally and Neovim deep-merges multiple calls.
		vim.lsp.config("jdtls", {
			settings = {
				java = {
					format = {
						settings = {
							url = vim.fn.stdpath("config") .. "/Default-for-eclipse.xml",
							profile = "Default",
						},
					},
					completion = {
						importOrder = { "javax", "", "java", "", "#" },
					},
					sources = {
						organizeImports = {
							starThreshold = 5,
							staticStarThreshold = 3,
						},
					},
				},
			},
		})

		vim.lsp.enable("jdtls")
	end,
}
