-- Platform/path fixtures and real LazyGit helper RPC; no browser or vault writes.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo)
local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture, "p")
local passed = 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. "\nactual: " .. vim.inspect(actual))
  passed = passed + 1
end
local expand, has, executable, system, stdpath, notify =
  vim.fn.expand, vim.fn.has, vim.fn.executable, vim.system, vim.fn.stdpath, vim.notify
local helper_env, xdg_env, app_env = vim.env.NVIM_LAZYGIT_OPEN_HELPER, vim.env.XDG_CONFIG_HOME, vim.env.NVIM_APPNAME
local observed = {}
vim.notify = function(message, level)
  observed[#observed + 1] = { message, level }
end
local socket = fixture .. "/rpc.sock"
local server
local function restore()
  vim.fn.expand, vim.fn.has, vim.fn.executable = expand, has, executable
  vim.system, vim.fn.stdpath, vim.notify = system, stdpath, notify
end
local function run()
  local obsidian = require("plugins.obsidian")
  local captured
  for _, platform in ipairs({ "linux", "mac" }) do
    local home = fixture .. "/" .. (platform == "mac" and "Users/Example User" or "home/Example User")
    vim.fn.expand = function(value)
      return value == "~" and home or expand(value)
    end
    vim.fn.has = function(value)
      if value == "mac" then
        return platform == "mac" and 1 or 0
      end
      return has(value)
    end
    vim.fn.executable = function(value)
      return value == "xdg-open" and 1 or executable(value)
    end
    vim.system = function(command)
      captured = command
      return {
        wait = function()
          return { code = 0 }
        end,
      }
    end
    local opts = obsidian.opts()
    equal(opts.workspaces[1].path, home .. "/Obsidian", platform .. " home-derived vault path")
    local url = 'https://example.invalid/a path?q="quote"&x=$literal'
    opts.follow_url_func(url)
    equal(captured, { platform == "mac" and "open" or "xdg-open", url }, platform .. " native opener preserves one URL argument")
  end
  vim.fn.has = function()
    return 0
  end
  vim.fn.executable = function()
    return 0
  end
  obsidian.opts().follow_url_func("https://example.invalid/")
  equal(observed[#observed][2], vim.log.levels.ERROR, "Missing URL opener reports error")
  equal(observed[#observed][1]:find("no handler found", 1, true) ~= nil, true, "Missing opener cause retained")
  vim.system = function()
    error("fixture spawn failure")
  end
  vim.fn.has = function(value)
    return value == "mac" and 1 or has(value)
  end
  obsidian.opts().follow_url_func("https://example.invalid/")
  equal(observed[#observed][1]:find("fixture spawn failure", 1, true) ~= nil, true, "Opener spawn error handled")
  local old_obsidian = package.loaded.obsidian
  local setup_called
  package.loaded.obsidian = {
    setup = function()
      setup_called = true
    end,
  }
  obsidian.config(nil, { workspaces = { { path = fixture .. "/missing vault" } } })
  equal(setup_called, true, "Missing vault keeps plugin inspectable")
  equal(observed[#observed][1], "Obsidian workspace missing: " .. fixture .. "/missing vault", "Missing vault warning names path")
  package.loaded.obsidian = old_obsidian
  restore()

  -- LazyGit resolves its own global config directory; no OS-path guessing.
  local nvim_config = fixture .. "/custom nvim config"
  vim.fn.mkdir(nvim_config .. "/lazygit", "p")
  vim.fn.mkdir(nvim_config .. "/scripts", "p")
  vim.fn.writefile(vim.fn.readfile(repo .. "/lazygit/config.yml"), nvim_config .. "/lazygit/config.yml")
  vim.fn.writefile(vim.fn.readfile(repo .. "/scripts/lazygit-open-in-nvim.sh"), nvim_config .. "/scripts/lazygit-open-in-nvim.sh")
  vim.fn.stdpath = function(kind)
    return kind == "config" and nvim_config or stdpath(kind)
  end
  vim.fn.executable = function(command)
    return command == "lazygit" and 1 or executable(command)
  end
  local config_helper = require("util.lazygit_config")
  for _, dir in ipairs({ fixture .. "/linux/.config/lazygit", fixture .. "/mac/Library/Application Support/lazygit" }) do
    vim.fn.mkdir(dir, "p")
    vim.fn.writefile({ "gui: {}" }, dir .. "/config.yml")
    vim.system = function(command)
      equal(command, { "lazygit", "--print-config-dir" }, "Native LazyGit config-directory query")
      return {
        wait = function()
          return { code = 0, stdout = dir .. "\n" }
        end,
      }
    end
    config_helper.setup()
    equal(
      vim.g.lazygit_config_file_path,
      { dir .. "/config.yml", nvim_config .. "/lazygit/config.yml" },
      "Native global config followed by repo overrides"
    )
    equal(
      vim.env.NVIM_LAZYGIT_OPEN_HELPER,
      nvim_config .. "/scripts/lazygit-open-in-nvim.sh",
      "Helper follows stdpath config, preserving spaces"
    )
  end
  vim.system = function()
    return {
      wait = function()
        return { code = 0, stdout = fixture .. "/missing-global\n" }
      end,
    }
  end
  config_helper.setup()
  equal(vim.g.lazygit_config_file_path, { nvim_config .. "/lazygit/config.yml" }, "Missing optional global config omitted")
  vim.system = function()
    return {
      wait = function()
        return { code = 1, stdout = "" }
      end,
    }
  end
  config_helper.setup()
  equal(vim.g.lazygit_config_file_path, { nvim_config .. "/lazygit/config.yml" }, "Failed directory query keeps repo config")
  restore()

  -- Use an isolated Neovim server to execute the real shell helper and open_file.
  local nvim = vim.fn.exepath("nvim")
  local init = fixture .. "/server-init.lua"
  vim.fn.writefile({
    "vim.opt.runtimepath:prepend(" .. string.format("%q", repo) .. ")",
    "vim.g.portability_source_win = vim.api.nvim_get_current_win()",
    "local buf = vim.api.nvim_create_buf(false, true)",
    "vim.bo[buf].filetype = 'lazygit'",
    "vim.api.nvim_open_win(buf, true, {relative='editor', row=1, col=1, width=20, height=5})",
  }, init)
  server = vim.system({ nvim, "--headless", "-u", init, "-i", "NONE", "--listen", socket }, { text = true })
  assert(
    vim.wait(5000, function()
      return vim.uv.fs_stat(socket) ~= nil
    end, 20),
    "RPC server did not start"
  )
  local command
  for _, line in ipairs(vim.fn.readfile(repo .. "/lazygit/config.yml")) do
    command = command or line:match("^  open: '(.*)'$")
  end
  assert(command, "Missing os.open config command")
  local filename = "file space 'quote\" $literal `tick`.txt"
  local file = fixture .. "/" .. filename
  vim.fn.writefile({ "fixture" }, file)
  local resolved = command:gsub("{{filename}}", function()
    return vim.fn.shellescape(filename)
  end)
  local result = vim.system({ "sh", "-c", resolved }, { cwd = fixture, text = true, env = { NVIM = socket } }):wait()
  equal(result.code, 0, "Configured helper opens difficult filename through actual RPC")
  local opened = vim.system({ nvim, "--server", socket, "--remote-expr", 'expand("%:p")' }, { text = true }):wait()
  equal(vim.trim(opened.stdout), file, "RPC opens exact path in existing Neovim")
  local context = vim
    .system({
      nvim,
      "--server",
      socket,
      "--remote-expr",
      'luaeval("vim.api.nvim_get_current_win() == vim.g.portability_source_win and 1 or 0")',
    }, { text = true })
    :wait()
  equal(vim.trim(context.stdout), "1", "RPC closes LazyGit float and preserves source window")
  -- Standalone fallback derives helper from XDG_CONFIG_HOME + NVIM_APPNAME.
  local config_root = fixture .. "/xdg config"
  local app = "custom-app"
  vim.fn.mkdir(config_root .. "/" .. app .. "/scripts", "p")
  vim.fn.writefile(
    vim.fn.readfile(repo .. "/scripts/lazygit-open-in-nvim.sh"),
    config_root .. "/" .. app .. "/scripts/lazygit-open-in-nvim.sh"
  )
  vim.env.NVIM_LAZYGIT_OPEN_HELPER = nil
  result = vim
    .system({ "sh", "-c", resolved }, { cwd = fixture, text = true, env = { NVIM = socket, XDG_CONFIG_HOME = config_root, NVIM_APPNAME = app } })
    :wait()
  equal(result.code, 0, "Standalone config helper fallback handles custom XDG/app paths")
end
local ok, err = xpcall(run, debug.traceback)
restore()
vim.env.NVIM_LAZYGIT_OPEN_HELPER, vim.env.XDG_CONFIG_HOME, vim.env.NVIM_APPNAME = helper_env, xdg_env, app_env
if server then
  server:kill(15)
  server:wait()
end
vim.fn.delete(fixture, "rf")
assert(ok, err)
print("Portability: " .. passed .. " assertions passed")
