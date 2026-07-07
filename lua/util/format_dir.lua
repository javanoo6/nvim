local M = {}

local skip_dir_names = {
  [".git"] = true,
  [".hg"] = true,
  [".svn"] = true,
  [".idea"] = true,
  [".vscode"] = true,
  ["node_modules"] = true,
  ["dist"] = true,
  ["build"] = true,
  ["target"] = true,
  ["coverage"] = true,
  ["intellij-code-formatter"] = true,
  [".next"] = true,
  [".nuxt"] = true,
  [".venv"] = true,
  ["venv"] = true,
  [".mypy_cache"] = true,
  [".pytest_cache"] = true,
  [".ruff_cache"] = true,
}

local confirm_large_dir_threshold = 200

local function normalize(path)
  if not path or path == "" then
    return nil
  end
  return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

local function executable(name)
  return vim.fn.executable(name) == 1 and vim.fn.exepath(name) or "<missing>"
end

local function fd_executable()
  local fd = vim.fn.exepath("fd")
  if fd ~= "" then
    return fd
  end

  fd = vim.fn.exepath("fdfind")
  if fd ~= "" then
    return fd
  end

  return nil
end

function M.formatter_info()
  local home = vim.env.HOME
  local jar = home .. "/.config/nvim/intellij-code-formatter/formatter-cli/target/formatter-cli-full.jar"
  local editorconfig = home .. "/.config/nvim/.editorconfig"
  local lines = {
    "java: " .. executable("java"),
    "idea formatter jar: " .. (vim.fn.filereadable(jar) == 1 and jar or "<missing> " .. jar),
    ".editorconfig: " .. (vim.fn.filereadable(editorconfig) == 1 and editorconfig or "<missing> " .. editorconfig),
    "stylua: " .. executable("stylua"),
    "prettier: " .. executable("prettier"),
    "gofumpt: " .. executable("gofumpt"),
    "goimports-reviser: " .. executable("goimports-reviser"),
    "golines: " .. executable("golines"),
    "ruby formatter: RuboCop through RVM/project bundle (checked per project)",
    "rvm script: " .. (vim.fn.filereadable(home .. "/.rvm/scripts/rvm") == 1 and home .. "/.rvm/scripts/rvm" or "<missing>"),
    "zsh: " .. executable("zsh"),
    "fd: " .. (fd_executable() or "<missing>"),
  }
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "FormatterInfo" })
end

local function format_buffer(conform, bufnr)
  local format_err
  local did_edit
  local attempted = conform.format({
    bufnr = bufnr,
    timeout_ms = 10000,
    lsp_format = "fallback",
    quiet = true,
  }, function(err, edited)
    format_err = err
    did_edit = edited
  end)
  return attempted, format_err, did_edit
end

local function detect_filetype(bufnr, path)
  if vim.bo[bufnr].filetype ~= "" then
    return vim.bo[bufnr].filetype
  end

  local filetype = vim.filetype.match({ buf = bufnr, filename = path })
  if filetype and filetype ~= "" then
    vim.bo[bufnr].filetype = filetype
  end
  return vim.bo[bufnr].filetype
end

local function supports_formatting(formatters_by_ft, path)
  if vim.fn.filereadable(path) ~= 1 then
    return false
  end

  local filetype = vim.filetype.match({ filename = path })
  if not filetype or filetype == "" then
    return false
  end

  local formatters = formatters_by_ft[filetype]
  return type(formatters) == "table" and not vim.tbl_isempty(formatters)
end

local function format_file(conform, path)
  if vim.fn.filereadable(path) ~= 1 then
    return false, "unreadable"
  end

  local existing = vim.fn.bufnr(path)
  local had_existing_buffer = existing ~= -1
  local bufnr = had_existing_buffer and existing or vim.fn.bufadd(path)

  vim.fn.bufload(bufnr)
  detect_filetype(bufnr, path)

  local formatters, lsp = conform.list_formatters_to_run(bufnr)
  if vim.tbl_isempty(formatters) and not lsp then
    if not had_existing_buffer then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
    return false, "no formatter"
  end

  local ok, attempted, format_err, did_edit = pcall(format_buffer, conform, bufnr)
  if not ok then
    if not had_existing_buffer then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
    return false, attempted or "format failed"
  end

  if not attempted then
    if not had_existing_buffer then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
    return false, "no formatter"
  end

  if format_err then
    if not had_existing_buffer then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
    return false, format_err
  end

  local modified = did_edit or vim.bo[bufnr].modified
  if modified then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("silent update")
    end)
  end

  if not had_existing_buffer then
    pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
  end

  return modified, nil
end

local function collect_files(formatters_by_ft, dir)
  local fd = fd_executable()
  if not fd then
    return nil, "fd/fdfind executable not found"
  end

  local args = {
    fd,
    "--type",
    "file",
    "--hidden",
    "--absolute-path",
    "--color",
    "never",
  }

  for name in pairs(skip_dir_names) do
    table.insert(args, "--exclude")
    table.insert(args, name)
  end

  table.insert(args, ".")
  table.insert(args, dir)

  local result = vim.system(args, { text = true }):wait()
  if result.code ~= 0 then
    return nil, vim.trim(result.stderr or "fd failed")
  end

  local files = {}
  for path in vim.gsplit(result.stdout or "", "\n", { trimempty = true }) do
    path = normalize(path)
    if path and supports_formatting(formatters_by_ft, path) then
      files[#files + 1] = path
    end
  end

  table.sort(files)
  return files
end

local function get_current_buffer_dir()
  local path = normalize(vim.api.nvim_buf_get_name(0))
  if not path or path == "" or vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  local dir = normalize(vim.fs.dirname(path))
  if dir and vim.fn.isdirectory(dir) == 1 then
    return dir
  end

  return nil
end

local function prompt_for_dir(callback)
  vim.ui.input({
    prompt = "Directory to format: ",
    default = require("util").get_cwd(),
    completion = "dir",
  }, function(input)
    if not input or input == "" then
      return
    end

    callback(vim.fn.fnamemodify(input, ":p"))
  end)
end

function M.format_dir(conform, formatters_by_ft, dir)
  dir = normalize(dir)
  if vim.fn.isdirectory(dir) ~= 1 then
    vim.notify("FormatDir: not a directory: " .. tostring(dir), vim.log.levels.ERROR)
    return
  end

  local files, collect_err = collect_files(formatters_by_ft, dir)
  if collect_err then
    vim.notify("FormatDir: " .. collect_err, vim.log.levels.ERROR)
    return
  end

  if vim.tbl_isempty(files) then
    vim.notify("FormatDir: no supported files found", vim.log.levels.INFO)
    return
  end

  if #files > confirm_large_dir_threshold then
    local choice = vim.fn.confirm(string.format("Format %d files under %s?", #files, vim.fn.fnamemodify(dir, ":~")), "&Yes\n&No", 2)
    if choice ~= 1 then
      return
    end
  end

  local changed = 0
  local skipped = 0
  local failed = 0
  local index = 1

  local function process_next()
    if index > #files then
      vim.notify(
        string.format("FormatDir complete: %d changed, %d skipped, %d failed", changed, skipped, failed),
        failed > 0 and vim.log.levels.WARN or vim.log.levels.INFO
      )
      return
    end

    local path = files[index]
    index = index + 1

    local did_change, err = format_file(conform, path)
    if err == "no formatter" or err == "unreadable" then
      skipped = skipped + 1
    elseif err then
      failed = failed + 1
      vim.notify("FormatDir failed: " .. path .. "\n" .. tostring(err), vim.log.levels.WARN)
    elseif did_change then
      changed = changed + 1
    end

    if index % 25 == 0 or index > #files then
      vim.notify(string.format("FormatDir progress: %d/%d", math.min(index - 1, #files), #files), vim.log.levels.INFO)
    end

    vim.schedule(process_next)
  end

  vim.notify(string.format("FormatDir started: %d files under %s", #files, vim.fn.fnamemodify(dir, ":~")), vim.log.levels.INFO)
  vim.schedule(process_next)
end

function M.register_commands(conform, formatters_by_ft)
  vim.api.nvim_create_user_command("FormatterInfo", M.formatter_info, {
    desc = "Show configured formatter executable status",
  })

  vim.api.nvim_create_user_command("FormatDir", function(command)
    local dir = command.args ~= "" and vim.fn.fnamemodify(command.args, ":p") or require("util").get_cwd()
    M.format_dir(conform, formatters_by_ft, dir)
  end, {
    nargs = "?",
    complete = "dir",
    desc = "Format all files in a directory recursively",
  })

  vim.api.nvim_create_user_command("FormatDirPick", function()
    local dir = get_current_buffer_dir()
    if dir then
      M.format_dir(conform, formatters_by_ft, dir)
      return
    end

    prompt_for_dir(function(path)
      M.format_dir(conform, formatters_by_ft, path)
    end)
  end, {
    desc = "Format current buffer directory or prompt for one",
  })
end

return M
