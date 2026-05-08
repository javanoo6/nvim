local logger = require("neotest-java.logger")

--- @param deps { client_provider: fun(cwd: neotest-java.Path): vim.lsp.Client }
--- @return NeotestJavaCompiler
local function LspCompiler(deps)
	return {
		compile = function(args)
			local started = vim.uv.hrtime()
			local client = deps.client_provider(args.base_dir)
			logger.warn(("[timing] buildWorkspace request scheduled after %.1f ms"):format((vim.uv.hrtime() - started) / 1e6))

			vim.schedule(function()
				client:request(
					"java/buildWorkspace",
					{ forceRebuild = args.compile_mode == "full" },
					function(err, result)
						logger.warn(
							("[timing] java/buildWorkspace callback after %.1f ms"):format(
								(vim.uv.hrtime() - started) / 1e6
							)
						)
						if err then
							logger.error("compilation failed: " .. vim.inspect(err))
						end
						if next(result.modulepaths) ~= nil then
							logger.error(
								"Java Platform Module System not supported. Temporarily remove "
									.. "module-info.java for the test duration. modulepath="
									.. vim.inspect(result.modulepaths)
							)
						end
					end
				)
			end)
		end,
	}
end

return LspCompiler
