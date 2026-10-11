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
  local lines = {
    "Java: standalone IntelliJ formatter (reformat + optimize imports + rearrange)",
    "Markdown/Python/XML/YAML (.yaml/.yml)/shell: standalone IntelliJ formatter",
    "Formatter jar: " .. vim.fn.stdpath("config") .. "/intellij-code-formatter/formatter-cli/target/formatter-cli-full.jar",
    "Formatter jar readable: " .. tostring(
      vim.fn.filereadable(vim.fn.stdpath("config") .. "/intellij-code-formatter/formatter-cli/target/formatter-cli-full.jar") == 1
    ),
    "Formatter Java: " .. executable("java"),
    "Formatter style: " .. vim.fn.stdpath("config") .. "/.editorconfig",
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

local function format_file(conform, path, callback)
  if vim.fn.filereadable(path) ~= 1 then
    callback(false, "unreadable")
    return
  end

  local existing = vim.fn.bufnr(path)
  local had_existing_buffer = existing ~= -1
  local bufnr = had_existing_buffer and existing or vim.fn.bufadd(path)
  vim.fn.bufload(bufnr)

  local finished = false
  local function finish(changed, err)
    if finished then
      return
    end
    finished = true
    if not had_existing_buffer and vim.api.nvim_buf_is_valid(bufnr) and not vim.bo[bufnr].modified and #vim.fn.win_findbuf(bufnr) == 0 then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
    end
    callback(changed, err)
  end

  if vim.bo[bufnr].modified then
    finish(false, "modified buffer")
    return
  end
  detect_filetype(bufnr, path)

  local opts, prepare_err = require("util.format").options(bufnr, { quiet = true, async = true })
  if prepare_err then
    finish(false, prepare_err)
    return
  end
  local formatters, lsp = conform.list_formatters_to_run(bufnr)
  if vim.tbl_isempty(formatters) and not lsp then
    finish(false, "no formatter")
    return
  end

  local ok, attempted = pcall(vim.api.nvim_buf_call, bufnr, function()
    return conform.format(opts, function(err, did_edit)
      if err then
        finish(false, err)
        return
      end
      if not vim.api.nvim_buf_is_valid(bufnr) then
        finish(false, "buffer deleted")
        return
      end
      -- Conform rejects stale results when the buffer changes during formatting.
      -- Write only successful formatter edits, never unrelated pending edits.
      if did_edit then
        local write_ok, write_err = pcall(vim.api.nvim_buf_call, bufnr, function()
          local disabled = vim.b[bufnr].disable_autoformat
          vim.b[bufnr].disable_autoformat = true
          local saved, save_err = pcall(vim.cmd, "silent update")
          vim.b[bufnr].disable_autoformat = disabled
          if not saved then
            error(save_err)
          end
        end)
        if not write_ok then
          finish(false, write_err)
          return
        end
      end
      finish(did_edit == true, nil)
    end)
  end)
  if not ok then
    finish(false, attempted)
  elseif not attempted then
    finish(false, "no formatter")
  end
end

local function collect_files(formatters_by_ft, dir, callback)
  local fd = fd_executable()
  if not fd then
    callback(nil, "fd/fdfind executable not found")
    return
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

  local ok, spawn_err = pcall(vim.system, args, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback(nil, vim.trim(result.stderr or "fd failed"))
        return
      end
      local files = {}
      for path in vim.gsplit(result.stdout or "", "\n", { trimempty = true }) do
        path = normalize(path)
        if path and supports_formatting(formatters_by_ft, path) then
          files[#files + 1] = path
        end
      end
      table.sort(files)
      callback(files)
    end)
  end)
  if not ok then
    callback(nil, tostring(spawn_err))
  end
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

local active_run

function M.cancel()
  if active_run then
    active_run.cancelled = true
    vim.notify("FormatDir: cancellation requested; current request will finish", vim.log.levels.INFO)
  else
    vim.notify("FormatDir: no active run", vim.log.levels.INFO)
  end
end

function M.format_dir(conform, formatters_by_ft, dir)
  if active_run then
    vim.notify("FormatDir: already running; use :FormatDirCancel first", vim.log.levels.WARN)
    return
  end
  dir = normalize(dir)
  if not dir or vim.fn.isdirectory(dir) ~= 1 then
    vim.notify("FormatDir: not a directory: " .. tostring(dir), vim.log.levels.ERROR)
    return
  end

  local run = { cancelled = false, changed = 0, skipped = 0, failed = 0, processed = 0 }
  active_run = run
  local function complete()
    active_run = nil
    vim.notify(
      string.format(
        "FormatDir %s: %d changed, %d skipped, %d failed (%d/%d processed)",
        run.cancelled and "cancelled" or "complete",
        run.changed,
        run.skipped,
        run.failed,
        run.processed,
        run.total or 0
      ),
      run.failed > 0 and vim.log.levels.WARN or vim.log.levels.INFO
    )
  end

  collect_files(formatters_by_ft, dir, function(files, collect_err)
    if run.cancelled then
      complete()
      return
    end
    if collect_err then
      active_run = nil
      vim.notify("FormatDir: " .. collect_err, vim.log.levels.ERROR)
      return
    end
    run.total = #files
    if #files == 0 then
      active_run = nil
      vim.notify("FormatDir: no supported files found", vim.log.levels.INFO)
      return
    end
    if #files > confirm_large_dir_threshold then
      local choice = vim.fn.confirm(string.format("Format %d files under %s?", #files, vim.fn.fnamemodify(dir, ":~")), "&Yes\n&No", 2)
      if choice ~= 1 then
        run.cancelled = true
        complete()
        return
      end
    end

    local function process_next()
      if run.cancelled or run.processed == #files then
        complete()
        return
      end
      local path = files[run.processed + 1]
      local ok, err = pcall(format_file, conform, path, function(did_change, format_err)
        run.processed = run.processed + 1
        local skip = format_err == "no formatter" or format_err == "unreadable" or format_err == "modified buffer"
        if format_err and not skip then
          run.failed = run.failed + 1
          vim.notify("FormatDir failed: " .. path .. "\n" .. tostring(format_err), vim.log.levels.WARN)
        elseif did_change and not skip then
          run.changed = run.changed + 1
        else
          run.skipped = run.skipped + 1
        end
        if run.processed % 25 == 0 then
          vim.notify(string.format("FormatDir progress: %d/%d", run.processed, #files), vim.log.levels.INFO)
        end
        vim.schedule(process_next)
      end)
      if not ok then
        run.processed = run.processed + 1
        run.failed = run.failed + 1
        vim.notify("FormatDir failed: " .. path .. "\n" .. tostring(err), vim.log.levels.WARN)
        vim.schedule(process_next)
      end
    end
    vim.notify(string.format("FormatDir started: %d files under %s", #files, vim.fn.fnamemodify(dir, ":~")), vim.log.levels.INFO)
    vim.schedule(process_next)
  end)
end

function M.register_commands(conform, formatters_by_ft)
  vim.api.nvim_create_user_command("FormatDirCancel", M.cancel, {
    desc = "Stop directory formatting after the active request",
  })

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
