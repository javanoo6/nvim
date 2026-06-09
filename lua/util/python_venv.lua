local M = {}

local util = require("util")
M.env_state = {
  root = nil,
  vars = {},
}

local root_markers = {
  "pyproject.toml",
  "setup.py",
  "setup.cfg",
  "tox.ini",
  "pytest.ini",
  "requirements.txt",
}

local function normalize(path)
  if not path or path == "" then
    return nil
  end

  return vim.fs.normalize(path)
end

local function active_python()
  local ok, venv_selector = pcall(require, "venv-selector")
  if not ok then
    return nil
  end

  return venv_selector.python()
end

local function active_venv()
  local ok, venv_selector = pcall(require, "venv-selector")
  if not ok then
    return nil
  end

  return venv_selector.venv()
end

local function python_root(bufnr)
  bufnr = bufnr or 0
  local name = vim.api.nvim_buf_get_name(bufnr)

  if name ~= "" then
    local root = vim.fs.find(root_markers, {
      path = vim.fs.dirname(name),
      upward = true,
    })[1]

    if root then
      return vim.fs.dirname(root)
    end
  end

  return util.get_root(bufnr)
end

local function env_name_default()
  local venv = active_venv()
  if venv and venv ~= "" then
    return vim.fs.basename(venv)
  end

  return ".venv"
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function unquote(value)
  if #value >= 2 then
    local first = value:sub(1, 1)
    local last = value:sub(-1)
    if (first == '"' and last == '"') or (first == "'" and last == "'") then
      value = value:sub(2, -2)
    end
  end

  value = value:gsub("\\n", "\n")
  value = value:gsub('\\"', '"')
  value = value:gsub("\\'", "'")
  value = value:gsub("\\\\", "\\")
  return value
end

local function parse_env_line(line)
  line = trim(line)
  if line == "" or vim.startswith(line, "#") then
    return nil
  end

  if vim.startswith(line, "export ") then
    line = trim(line:sub(8))
  end

  local key, value = line:match("^([%a_][%w_]*)%s*=%s*(.*)$")
  if not key then
    return nil
  end

  value = trim(value)
  if value == "" then
    return key, ""
  end

  return key, unquote(value)
end

local function read_env_file(path)
  local lines = vim.fn.readfile(path)
  local vars = {}

  for _, line in ipairs(lines) do
    local key, value = parse_env_line(line)
    if key then
      vars[key] = value
    end
  end

  return vars
end

local function clear_loaded_env()
  for key in pairs(M.env_state.vars) do
    vim.env[key] = nil
  end

  M.env_state.root = nil
  M.env_state.vars = {}
end

function M.apply_project_env(bufnr)
  bufnr = bufnr or 0
  local root = python_root(bufnr)
  local env_file = root and normalize(root .. "/.env") or nil

  clear_loaded_env()

  if not env_file or vim.fn.filereadable(env_file) ~= 1 then
    return false
  end

  local vars = read_env_file(env_file)
  for key, value in pairs(vars) do
    vim.env[key] = value
  end

  M.env_state.root = root
  M.env_state.vars = vars
  return true
end

local function validate_env_name(name)
  if not name or name == "" then
    return nil, "Venv name is required"
  end

  if name == "." or name == ".." or vim.startswith(name, "/") or name:find("\\") or name:find("/") then
    return nil, "Use a local venv name like .venv or .venv-py312"
  end

  return name
end

local function env_path(root, name)
  return normalize(root .. "/" .. name)
end

local function is_safe_child(root, path)
  root = normalize(root)
  path = normalize(path)
  if not root or not path or root == path then
    return false
  end

  local prefix = root:sub(-1) == "/" and root or (root .. "/")
  return path:sub(1, #prefix) == prefix
end

local function open_terminal(argv, cwd, title, on_exit)
  vim.cmd("botright 12split")
  vim.cmd("enew")

  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].bufhidden = "wipe"

  if title and title ~= "" then
    pcall(vim.api.nvim_buf_set_name, buf, "python://" .. title)
  end

  vim.fn.termopen(argv, {
    cwd = cwd,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          vim.notify(title .. " finished")
        else
          vim.notify(title .. " failed (" .. code .. ")", vim.log.levels.ERROR)
        end

        if on_exit then
          on_exit(code)
        end
      end)
    end,
  })

  vim.cmd("startinsert")
end

local function activate_env(path)
  local python = path .. "/bin/python"
  if vim.fn.filereadable(python) ~= 1 then
    vim.notify("No python executable in " .. path, vim.log.levels.ERROR)
    return
  end

  require("venv-selector").activate_from_path(python, "venv")
end

local function parse_create_args(opts)
  local args = opts.fargs or {}
  local name = args[1] or opts.name or env_name_default()
  local python = opts.python or table.concat(vim.list_slice(args, 2), " ")

  if python == "" then
    python = "python3"
  end

  return name, python
end

function M.select()
  vim.cmd("VenvSelect")
end

function M.create(opts)
  opts = opts or {}

  local root = python_root(0)
  if not root then
    vim.notify("No Python project root found", vim.log.levels.ERROR)
    return
  end

  local name, python = parse_create_args(opts)
  local validated, err = validate_env_name(name)
  if not validated then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  name = validated

  if vim.fn.executable(python) ~= 1 then
    vim.notify("Python executable not found: " .. python, vim.log.levels.ERROR)
    return
  end

  local path = env_path(root, name)
  if not is_safe_child(root, path) then
    vim.notify("Refusing to create venv outside project root", vim.log.levels.ERROR)
    return
  end

  if vim.fn.isdirectory(path) == 1 then
    vim.notify("Venv already exists: " .. name, vim.log.levels.WARN)
    return
  end

  vim.fn.mkdir(vim.fs.dirname(path), "p")
  open_terminal({ python, "-m", "venv", path }, root, "python-venv-create", function(code)
    if code == 0 then
      activate_env(path)
      vim.notify("Created and activated " .. name)
    end
  end)
end

function M.recreate(opts)
  opts = opts or {}

  local root = python_root(0)
  if not root then
    vim.notify("No Python project root found", vim.log.levels.ERROR)
    return
  end

  local name, python = parse_create_args(opts)
  local validated, err = validate_env_name(name)
  if not validated then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  name = validated

  if vim.fn.executable(python) ~= 1 then
    vim.notify("Python executable not found: " .. python, vim.log.levels.ERROR)
    return
  end

  local path = env_path(root, name)
  if not is_safe_child(root, path) then
    vim.notify("Refusing to recreate venv outside project root", vim.log.levels.ERROR)
    return
  end

  if vim.fn.isdirectory(path) == 1 and vim.fn.delete(path, "rf") ~= 0 then
    vim.notify("Failed to remove existing venv: " .. name, vim.log.levels.ERROR)
    return
  end

  vim.fn.mkdir(vim.fs.dirname(path), "p")
  open_terminal({ python, "-m", "venv", path }, root, "python-venv-recreate", function(code)
    if code == 0 then
      activate_env(path)
      vim.notify("Recreated and activated " .. name)
    end
  end)
end

function M.install(opts)
  opts = opts or {}

  local python = active_python()
  if not python or python == "" then
    vim.notify("Select or create a Python venv first", vim.log.levels.ERROR)
    return
  end

  local root = python_root(0) or util.get_root()
  local requirements = root and normalize(root .. "/requirements.txt") or nil
  local args = opts.args or ""
  local argv = { python, "-m", "pip", "install" }

  if args == "" then
    if requirements and vim.fn.filereadable(requirements) == 1 then
      vim.list_extend(argv, { "-r", requirements })
    else
      vim.list_extend(argv, { "-e", root })
    end
  else
    vim.list_extend(argv, vim.split(args, "%s+", { trimempty = true }))
  end

  open_terminal(argv, root, "python-venv-install", function(code)
    if code == 0 then
      local ok, venv_selector = pcall(require, "venv-selector")
      if ok then
        venv_selector.restart_lsp_servers()
      end
    end
  end)
end

function M.prompt_create()
  vim.ui.input({ prompt = "Venv name: ", default = env_name_default() }, function(name)
    if not name or name == "" then
      return
    end

    vim.ui.input({ prompt = "Base python: ", default = "python3" }, function(python)
      if not python or python == "" then
        return
      end

      M.create({ name = name, python = python })
    end)
  end)
end

function M.prompt_recreate()
  vim.ui.input({ prompt = "Recreate venv: ", default = env_name_default() }, function(name)
    if not name or name == "" then
      return
    end

    vim.ui.input({ prompt = "Base python: ", default = "python3" }, function(python)
      if not python or python == "" then
        return
      end

      M.recreate({ name = name, python = python })
    end)
  end)
end

function M.prompt_install()
  vim.ui.input({ prompt = "pip install args (empty = project deps): " }, function(args)
    if args == nil then
      return
    end

    M.install({ args = args })
  end)
end

function M.register_commands()
  local command_names = {
    "PythonVenvSelect",
    "PythonVenvCreate",
    "PythonVenvRecreate",
    "PythonVenvInstall",
  }

  for _, name in ipairs(command_names) do
    pcall(vim.api.nvim_del_user_command, name)
  end

  vim.api.nvim_create_user_command("PythonVenvSelect", function()
    M.select()
  end, { desc = "Select Python venv" })

  vim.api.nvim_create_user_command("PythonVenvCreate", function(opts)
    M.create(opts)
  end, {
    desc = "Create Python venv in project root",
    nargs = "*",
  })

  vim.api.nvim_create_user_command("PythonVenvRecreate", function(opts)
    M.recreate(opts)
  end, {
    desc = "Recreate Python venv in project root",
    nargs = "*",
  })

  vim.api.nvim_create_user_command("PythonVenvInstall", function(opts)
    M.install({ args = opts.args })
  end, {
    desc = "Install dependencies into active Python venv",
    nargs = "*",
  })
end

return M
