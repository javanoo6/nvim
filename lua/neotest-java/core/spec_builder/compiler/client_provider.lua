local Path = require("neotest-java.model.path")
local logger = require("neotest-java.logger")

--- @param deps { get_clients: fun(opts: table): vim.lsp.Client[], globpath: fun(dir: string, pattern: string, nosuf: boolean, list: boolean): string[], bufadd: fun(path: string): number, bufload: fun(path: string), sleep: fun(ms: number), hrtime: fun(): number }
--- @return fun(cwd: neotest-java.Path): vim.lsp.Client
local function ClientProvider(deps)
	local client

	local function find_any_java_file(dir)
		return Path(
			assert(
				vim.iter(deps.globpath(dir:to_string(), Path("**/*.java"):to_string(), false, true)):next(),
				"No Java file found in the directory." .. dir:to_string()
			)
		)
	end

	local function preload_file_for_lsp(path)
		local buf = deps.bufadd(path:to_string())
		deps.bufload(path:to_string())
		return buf
	end

	local function wait(timeout_ms, condition, interval_ms)
		local start_time = deps.hrtime() / 1e6
		while true do
			if condition() then
				return true
			end
			local current_time = deps.hrtime() / 1e6
			if (current_time - start_time) > timeout_ms then
				return false
			end
			deps.sleep(interval_ms)
		end
	end

	return function(cwd)
		local started = deps.hrtime()
		if client and client.initialized then
			logger.warn(("[timing] reused existing jdtls client in %.1f ms"):format((deps.hrtime() - started) / 1e6))
			return client
		end

		client = deps.get_clients({ name = "jdtls" })[1]
		if client and client.initialized then
			logger.warn(("[timing] found active jdtls client in %.1f ms"):format((deps.hrtime() - started) / 1e6))
			return client
		end

		local any_java_file = find_any_java_file(cwd)
		local bufnr = preload_file_for_lsp(any_java_file)
		assert(
			wait(10000, function()
				client = deps.get_clients({ name = "jdtls", bufnr = bufnr })[1]
				return not not client and not not client.initialized
			end, 1000),
			"jdtls client not started in time"
		)
		logger.warn(("[timing] waited for jdtls startup in %.1f ms"):format((deps.hrtime() - started) / 1e6))
		return client
	end
end

return ClientProvider
