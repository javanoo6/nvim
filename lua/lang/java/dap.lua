-- ./lua/lang/java/dap.lua
-- Java DAP: Debug Adapter Protocol configuration for Java
-- Handles debug adapter bundles and DAP setup

local M = {}

local home = vim.env.HOME
local mason_path = home .. "/.local/share/nvim/mason"

-- Collect debug bundles (debug adapter, test runner)
function M.get_bundles()
	local bundles = {}

	-- java-debug-adapter
	local debug_jar = vim.fn.glob(mason_path .. "/share/java-debug-adapter/com.microsoft.java.debug.plugin-*.jar", true)
	if debug_jar ~= "" then
		table.insert(bundles, debug_jar)
	end

	-- java-test (exclude runner and jacoco)
	local test_jars = vim.split(vim.fn.glob(mason_path .. "/share/java-test/*.jar", true), "\n")
	for _, jar in ipairs(test_jars) do
		if jar ~= ""
				and not jar:match("runner%-jar%-with%-dependencies")
				and not jar:match("jacocoagent") then
			table.insert(bundles, jar)
		end
	end

	return bundles
end

-- Setup DAP for Java
function M.setup_dap(client)
	local dap_ok, _ = pcall(require, "dap")
	if not dap_ok then return end

	local jdtls_ok, jdtls = pcall(require, "jdtls")
	if not jdtls_ok then return end

	jdtls.setup_dap({ hotcodereplace = "auto" })

	pcall(function()
		require("jdtls.dap").setup_dap_main_class_configs()
	end)
end

-- DAP configurations for Java
function M.get_dap_configurations()
	return {
		{
			name = "Debug (Attach) - Remote",
			type = "java",
			request = "attach",
			hostName = "127.0.0.1",
			port = 5005,
		},
		{
			name = "Debug Launch (2GB)",
			type = "java",
			request = "launch",
			vmArgs = "-Xmx2g",
		},
	}
end

return M
