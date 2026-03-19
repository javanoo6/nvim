-- ./lua/plugins/nvim-java.lua

return {
	'nvim-java/nvim-java',
	config = function()
		require('java').setup({
			-- Startup checks
			checks = {
				nvim_version = true,
				nvim_jdtls_conflict = true,
			},

			-- Extensions (no pinned versions — let nvim-java pick compatible ones)
			lombok = { enable = true },
			java_test = { enable = true },
			java_debug_adapter = { enable = true },
			spring_boot_tools = { enable = true },

			jdk = {
				auto_install = false,
			},

			-- Logging
			log = {
				use_console = false,
				use_file = true,
				level = 'warn',
				log_file = vim.fn.stdpath('state') .. '/nvim-java.log',
				max_lines = 1000,
				show_location = false,
			},
		})
		vim.lsp.enable('jdtls')
	end,
}
