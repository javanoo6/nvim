-- ./lua/lang/java/core.lua

-- Java Core: Base JDTLS configuration
-- Handles language server setup, capabilities, and core settings

local M = {}

local home = vim.env.HOME
local mason_path = home .. "/.local/share/nvim/mason"

-- Detect OS for jdtls config path
function M.get_os()
	if vim.fn.has("mac") == 1 then return "mac" end
	if vim.fn.has("win32") == 1 then return "win" end
	return "linux"
end

-- Project-specific workspace directory
function M.get_workspace_dir()
	local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
	return home .. "/.cache/jdtls/workspace/" .. project_name
end

-- Find Java executable
function M.get_java_cmd()
	local java_home = os.getenv("JAVA_HOME")
	if java_home then
		return java_home .. "/bin/java"
	end
	return "java"
end

-- LSP capabilities with nvim-cmp
function M.get_capabilities()
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	local cmp_ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
	if cmp_ok then
		capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
	end
	return capabilities
end

-- Extended capabilities for jdtls
function M.get_extended_capabilities()
	local ok, jdtls = pcall(require, "jdtls")
	if not ok then return {} end
	local extendedClientCapabilities = jdtls.extendedClientCapabilities
	extendedClientCapabilities.resolveAdditionalTextEditsSupport = true
	return extendedClientCapabilities
end

-- Core JDTLS settings
function M.get_settings()
	return {
		java = {
			home = "/usr/lib/jvm/java-21-openjdk-amd64",

			eclipse = { downloadSources = true },

			maven = {
				downloadSources = true,
				updateSnapshots = true,
			},

			gradle = {
				enabled = true,
				wrapper = { enabled = true },
			},

			configuration = {
				updateBuildConfiguration = "automatic",
				runtimes = {
					{ name = "JavaSE-17", path = "/usr/lib/jvm/java-17-openjdk-amd64" },
					{ name = "JavaSE-21", path = "/usr/lib/jvm/java-21-openjdk-amd64" },
				},
			},

			implementationsCodeLens = { enabled = true },
			referencesCodeLens = { enabled = true },
			references = { includeDecompiledSources = true },
			inlayHints = { parameterNames = { enabled = "all" } },
			signatureHelp = { enabled = true, description = { enabled = true } },

			format = { enabled = true },

			completion = {
				favoriteStaticMembers = {
					"org.junit.jupiter.api.Assertions.*",
					"org.junit.jupiter.api.Assumptions.*",
					"org.junit.jupiter.api.DynamicTest.*",
					"org.mockito.Mockito.*",
					"org.mockito.ArgumentMatchers.*",
					"org.mockito.BDDMockito.*",
					"org.assertj.core.api.Assertions.*",
					"org.assertj.core.api.BDDAssertions.*",
					"org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
					"org.springframework.test.web.servlet.result.MockMvcResultMatchers.*",
					"org.springframework.test.web.servlet.result.MockMvcResultHandlers.*",
					"org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*",
					"org.hamcrest.Matchers.*",
					"org.hamcrest.CoreMatchers.*",
					"java.util.Objects.requireNonNull",
					"java.util.Objects.requireNonNullElse",
				},
				importOrder = { "java", "javax", "jakarta", "org", "com", "", "#" },
				filteredTypes = {
					"com.sun.*",
					"io.micrometer.shaded.*",
					"java.awt.*",
					"jdk.*",
					"sun.*",
				},
			},

			sources = {
				organizeImports = {
					starThreshold = 9999,
					staticStarThreshold = 9999,
				},
			},

			codeGeneration = {
				toString = {
					template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
				},
				hashCodeEquals = {
					useInstanceof = true,
					useJava7Objects = true,
				},
				useBlocks = true,
				generateComments = false,
			},
		},
	}
end

-- Build jdtls command
function M.get_cmd()
	return {
		M.get_java_cmd(),
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-javaagent:" .. mason_path .. "/share/jdtls/lombok.jar",
		"-Xms512m",
		"-Xmx4g",
		"-XX:+UseG1GC",
		"-XX:+UseStringDeduplication",
		"--add-modules=ALL-SYSTEM",
		"--add-opens", "java.base/java.util=ALL-UNNAMED",
		"--add-opens", "java.base/java.lang=ALL-UNNAMED",
		"-jar", mason_path .. "/share/jdtls/plugins/org.eclipse.equinox.launcher.jar",
		"-configuration", mason_path .. "/packages/jdtls/config_" .. M.get_os(),
		"-data", M.get_workspace_dir(),
	}
end

-- Find project root
function M.get_root_dir()
	return require("jdtls.setup").find_root({
		"pom.xml",
		"build.gradle",
		"build.gradle.kts",
		"settings.gradle",
		"settings.gradle.kts",
		".git",
		"mvnw",
		"gradlew",
	})
end

return M
