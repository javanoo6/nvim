-- ./lua/plugins/neotest.lua

-- Testing: stock neotest setup with Java, Go, and Python adapters
local uv = vim.uv or vim.loop

local IGNORED_DIRS = {
	[".git"] = true,
	[".gradle"] = true,
	[".idea"] = true,
	[".mvn"] = true,
	[".pytest_cache"] = true,
	[".svn"] = true,
	[".venv"] = true,
	["build"] = true,
	["dist"] = true,
	["node_modules"] = true,
	["out"] = true,
	["target"] = true,
	["venv"] = true,
}

local PATH_SEP = package.config:sub(1, 1)
local active_scope = nil

local function normalize(path)
	return vim.fs.normalize(path)
end

local function path_starts_with(path, prefix)
	path = normalize(path)
	prefix = normalize(prefix)
	return path == prefix or vim.startswith(path, prefix .. PATH_SEP)
end

local function find_upwards(start_path, markers)
	local dir = vim.fs.dirname(start_path)
	while dir and dir ~= "" do
		for _, marker in ipairs(markers) do
			if uv.fs_stat(vim.fs.joinpath(dir, marker)) then
				return dir
			end
		end
		local parent = vim.fs.dirname(dir)
		if not parent or parent == dir then
			return nil
		end
		dir = parent
	end
	return nil
end

local function current_scope()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		return nil
	end

	path = normalize(path)
	local filetype = vim.bo.filetype
	local markers_by_ft = {
		go = { "go.mod", "go.work" },
		java = { "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts" },
		python = { "pyproject.toml", "pytest.ini", "setup.py", "setup.cfg" },
	}

	local focus_root = markers_by_ft[filetype] and find_upwards(path, markers_by_ft[filetype]) or nil
	if not focus_root then
		focus_root = vim.fs.dirname(path)
	end

	return {
		filetype = filetype,
		path = path,
		focus_root = normalize(focus_root),
	}
end

local function get_scope()
	return active_scope or current_scope()
end

local function activate_scope()
	local scope = current_scope()
	active_scope = scope
	if not scope then
		return nil
	end

	if not path_starts_with(vim.fn.getcwd(), scope.focus_root) then
		vim.cmd("silent noautocmd cd " .. vim.fn.fnameescape(scope.focus_root))
	end

	return scope
end

local function scoped_discovery_filter(name, rel_path, root)
	if IGNORED_DIRS[name] then
		return false
	end

	local scope = get_scope()
	if not scope then
		return true
	end

	root = normalize(root)
	if not path_starts_with(scope.path, root) then
		return false
	end

	if scope.focus_root == root then
		return true
	end

	if not path_starts_with(scope.focus_root, root) then
		return false
	end

	local focus_rel = vim.fs.relpath(root, scope.focus_root)
	if not focus_rel or focus_rel == "" or focus_rel == "." then
		return true
	end

	local candidate = rel_path == "." and name or (rel_path .. "/" .. name)
	return candidate == focus_rel
		or vim.startswith(focus_rel, candidate .. "/")
		or vim.startswith(candidate, focus_rel .. "/")
end

local function clear_and_run(run_fn)
	return function(...)
		activate_scope()
		require("neotest").summary.open()
		require("neotest").output_panel.clear()
		require("neotest").output_panel.open()
		return run_fn(...)
	end
end

return {
	{
		"rcasia/neotest-java",
		ft = "java",
		cmd = { "NeotestJava" },
		dependencies = {
			"nvim-java/nvim-java",
			"mfussenegger/nvim-dap",
		},
	},
	{
		"fredrikaverpil/neotest-golang",
		ft = "go",
		build = function()
			vim.system({ "go", "install", "gotest.tools/gotestsum@latest" }):wait()
		end,
	},
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			"rcasia/neotest-java",           -- Java (Maven/Gradle)
			"fredrikaverpil/neotest-golang", -- Go
			"nvim-neotest/neotest-python", -- Python
		},
		keys = {
			{
				"<leader>tt",
				clear_and_run(function()
					require("neotest").run.run(vim.fn.expand("%"))
				end),
				desc = "Run File",
			},
			{
				"<leader>tT",
				clear_and_run(function()
					local scope = get_scope()
					require("neotest").run.run(scope and scope.focus_root or uv.cwd())
				end),
				desc = "Run All Test Files",
			},
			{
				"<leader>tr",
				clear_and_run(function()
					require("neotest").run.run()
				end),
				desc = "Run Nearest",
			},
			{
				"<leader>tl",
				clear_and_run(function()
					require("neotest").run.run_last()
				end),
				desc = "Run Last",
			},
			{
				"<leader>ta",
				function()
					require("neotest").run.attach({ interactive = true })
				end,
				desc = "Attach to Running Test",
			},
			{
				"<leader>ts",
				function()
					activate_scope()
					require("neotest").summary.toggle()
				end,
				desc = "Toggle Summary",
			},
			{
				"<leader>to",
				function()
					require("neotest").output.open({ enter = true, auto_close = true })
				end,
				desc = "Show Output",
			},
			{
				"<leader>tO",
				function()
					require("neotest").output_panel.toggle()
				end,
				desc = "Toggle Output Panel",
			},
			{
				"<leader>tc",
				function()
					require("neotest").output_panel.clear()
				end,
				desc = "Clear Output Panel",
			},
			{
				"<leader>tS",
				function()
					require("neotest").run.stop({ interactive = true })
				end,
				desc = "Stop (Interactive)",
			},
			{
				"<leader>tw",
				function()
					require("neotest").watch.toggle(vim.fn.expand("%"))
				end,
				desc = "Toggle Watch",
			},
		},
		config = function()
			require("neotest").setup({
				discovery = {
					filter_dir = scoped_discovery_filter,
				},
				adapters = {
					require("neotest-java")({
						incremental_build = true,
					}),
					require("neotest-golang")({
						runner = "gotestsum",
					}),
					require("neotest-python")({
						dap = { justMyCode = false },
					}),
				},
				status = { virtual_text = true },
				output_panel = {
					open = "botright split | resize 15",
				},
				quickfix = {
					open = function()
						vim.cmd("copen")
					end,
				},
			})
		end,
	},
}
