local nio = require("nio")
local logger = require("neotest-java.logger")

-- Local override for Neovim 0.11 compatibility.
-- neotest-java issues LSP requests while still inside a fast-event context,
-- which trips vim.lsp.Client:request() on 0.11.x when it emits LspRequest.

--- @param deps { client_provider: fun(cwd: neotest-java.Path): vim.lsp.Client }
--- @return neotest-java.ClasspathProvider
local function ClasspathProvider(deps)
	return {
		get_classpath = function(base_dir, additional_classpath_entries)
			local started = vim.uv.hrtime()
			additional_classpath_entries = additional_classpath_entries or {}

			local base_dir_uri = vim.uri_from_fname(base_dir:to_string())
			local client = deps.client_provider(base_dir)
			local bufnr = vim.tbl_keys(client.attached_buffers)[1]
			local runtime = nio.control.future()
			local test = nio.control.future()

			-- Leave fast-event context before issuing LSP requests.
			nio.scheduler()

			client:request("workspace/executeCommand", {
				command = "java.project.getClasspaths",
				arguments = { base_dir_uri, vim.json.encode({ scope = "runtime" }) },
			}, function(err, result)
				if err then
					runtime.set_error(err)
				else
					logger.warn(
						("[timing] java.project.getClasspaths(runtime) finished in %.1f ms"):format(
							(vim.uv.hrtime() - started) / 1e6
						)
					)
					runtime.set(result.classpaths)
				end
			end, bufnr)

			client:request("workspace/executeCommand", {
				command = "java.project.getClasspaths",
				arguments = { base_dir_uri, vim.json.encode({ scope = "test" }) },
			}, function(err, result)
				if err then
					test.set_error(err)
				else
					logger.warn(
						("[timing] java.project.getClasspaths(test) finished in %.1f ms"):format(
							(vim.uv.hrtime() - started) / 1e6
						)
					)
					test.set(result.classpaths)
				end
			end, bufnr)

			local additional = vim.iter(additional_classpath_entries)
				:map(function(path)
					return path:to_string()
				end)
				:totable()

			local classpath = vim
				.iter({
					runtime.wait(),
					test.wait(),
					additional,
				})
				:flatten()
				:join(":")
			logger.warn(("[timing] combined classpath resolution finished in %.1f ms"):format((vim.uv.hrtime() - started) / 1e6))
			return classpath
		end,
	}
end

return ClasspathProvider
