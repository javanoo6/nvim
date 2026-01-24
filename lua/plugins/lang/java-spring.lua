-- ./lua/plugins/lang/java-spring.lua

-- Java Spring Boot: Spring Boot tools integration
-- Provides Spring Boot language server support

return {
	{
		"JavaHello/spring-boot.nvim",
		ft = { "java", "yaml", "jproperties" },
		dependencies = {
			"mfussenegger/nvim-jdtls",
		},
		opts = {
			ls_path = vim.fn.expand(
				"~/.local/share/spring-boot-ls/spring-boot-ls/extension/language-server/spring-boot-language-server-2.0.1-SNAPSHOT-exec.jar"
			),
			exploded_ls_jar_data = false,
			java_cmd = "java",
			log_file = vim.fn.stdpath("cache") .. "/spring-boot-ls.log",
			jdtls_name = "jdtls",
		},
	},
}
