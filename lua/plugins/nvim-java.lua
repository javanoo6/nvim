-- ./lua/plugins/nvim-java.lua

return {
	'nvim-java/nvim-java',
	config = function()
		require('java').setup({
			-- Startup checks
			checks = {
				nvim_version = true,    -- Check Neovim version
				nvim_jdtls_conflict = true, -- Check for nvim-jdtls conflict
			},

			-- JDTLS configuration
			jdtls = {
				version = '1.54.0',
			},

			-- Extensions
			lombok = {
				enable = true,
				version = '1.18.40',
			},

			java_test = {
				enable = true,
				version = '0.43.0',
			},

			java_debug_adapter = {
				enable = true,
				version = '0.58.2',
			},

			spring_boot_tools = {
				enable = true,
				version = '1.55.1',
			},

			jdk = {
				auto_install = false,
			},

			-- Logging
			log = {
				use_console = true,
				use_file = true,
				level = 'info',
				log_file = vim.fn.stdpath('state') .. '/nvim-java.log',
				max_lines = 1000,
				show_location = false,
			},
		})
		 vim.lsp.enable('jdtls')
	end,
}
