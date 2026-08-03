local Path = require("neotest-java.model.path")

local logger = require("neotest-java.logger")
local nio = require("nio")

--- Local override for upstream neotest-java command/binaries.lua.
---
--- JDTLS can return nil for org.eclipse.jdt.ls.core.vm.location even when the
--- Java project is otherwise usable. Upstream passes that nil into Path(), which
--- crashes before Neotest can report a useful error. Fall back to the Java home
--- used by this Neovim config.

--- @class neotest-java.LspBinaries
--- @field java fun(cwd: neotest-java.Path): neotest-java.Path
--- @field javap fun(cwd: neotest-java.Path): neotest-java.Path

---@diagnostic disable: undefined-doc-name
--- @class neotest-java.BinariesDeps
--- @field client_provider fun(cwd: neotest-java.Path): vim.lsp.Client
--- @field is_windows? boolean
--- @field schedule? fun(fn: fun()) Defaults to vim.schedule. Inject a synchronous pass-through in tests.

local function executable_java_home()
  local java = vim.fn.exepath("java")
  if java == "" then
    return nil
  end

  local bin = vim.fs.dirname(vim.uv.fs_realpath(java) or java)
  local home = vim.fs.dirname(bin)
  if home and home ~= "" then
    return home
  end
end

local function configured_java_home()
  local candidates = {}
  local function add_candidate(home)
    if home and home ~= "" then
      candidates[#candidates + 1] = home
    end
  end

  add_candidate(vim.env.NVIM_JAVA_HOME)
  add_candidate(vim.env.JAVA_HOME)
  add_candidate(executable_java_home())
  add_candidate("/usr/lib/jvm/java-21-openjdk-amd64")

  for _, home in ipairs(candidates) do
    if vim.fn.isdirectory(home) == 1 then
      return home
    end
  end
end

--- @param deps neotest-java.BinariesDeps
--- @return neotest-java.LspBinaries
local Binaries = function(deps)
  local is_windows = deps.is_windows
  if is_windows == nil then
    is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
  end

  local schedule = deps.schedule or vim.schedule

  local cached_java_homes = {}
  --- @param cwd neotest-java.Path
  local get_java_home = function(cwd)
    if cached_java_homes[cwd:to_string()] then
      return cached_java_homes[cwd:to_string()]
    end
    local client = deps.client_provider(cwd)

    logger.debug("Resolving Java home via JDTLS for cwd: " .. cwd:to_string())

    local cmd = {
      command = "java.project.getSettings",
      arguments = { vim.uri_from_fname(cwd:to_string()), { "org.eclipse.jdt.ls.core.vm.location" } },
    }
    local result_future = nio.control.future()
    schedule(function()
      ---@diagnostic disable-next-line: undefined-field
      client:request("workspace/executeCommand", cmd, function(err, res)
        if err then
          error("Error while getting Java home from lsp server: " .. vim.inspect(err))
        end
        if res and res.err then
          error("Error while getting Java home from lsp server: " .. vim.inspect(res.err))
        end
        result_future.set(res)
      end)
    end)
    local res = result_future.wait()
    local java_home = res and res["org.eclipse.jdt.ls.core.vm.location"] or nil

    if not java_home or java_home == "" then
      java_home = configured_java_home()
      assert(java_home, "JDTLS did not report a Java home and no fallback Java home was found. Set NVIM_JAVA_HOME or JAVA_HOME.")
      logger.warn("JDTLS did not report Java home; using fallback: " .. java_home)
    end

    cached_java_homes[cwd:to_string()] = java_home
    return java_home
  end

  return {
    --- @param cwd neotest-java.Path
    java = function(cwd)
      local exe_ext = is_windows and ".exe" or ""
      return Path(get_java_home(cwd)):append("bin/java" .. exe_ext)
    end,

    --- @param cwd neotest-java.Path
    javap = function(cwd)
      local exe_ext = is_windows and ".exe" or ""
      return Path(get_java_home(cwd)):append("bin/javap" .. exe_ext)
    end,
  }
end

return Binaries
