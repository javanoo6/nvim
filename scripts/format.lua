-- Formatter-only entry point: share the editor's config without loading sessions,
-- LSP clients, auto-save, or UI plugins. Paths arrive as argv, never Ex commands.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")

local function field(key, value)
  io.stdout:write(key .. ": " .. vim.json.encode(value) .. "\n")
  io.stdout:flush()
end

local function run()
  vim.opt.runtimepath:prepend(root)
  local data = vim.fn.stdpath("data")
  for _, name in ipairs({ "conform.nvim", "mason.nvim" }) do
    local path = data .. "/lazy/" .. name
    assert(vim.fn.isdirectory(path) == 1, "Missing " .. name .. "; install this repo's plugins in Neovim first")
    vim.opt.runtimepath:append(path)
  end
  -- util.format and the formatter spec use stdpath('config') for the jar/style.
  assert(vim.uv.fs_realpath(root) == vim.uv.fs_realpath(vim.fn.stdpath("config")), "Run format.sh from the installed Neovim configuration")
  require("config.options")
  vim.opt.undofile = false
  require("mason").setup({})
  local opts = vim.deepcopy(require("plugins.formatting")[1].opts)
  opts.format_on_save = nil
  opts.notify_on_error = false
  opts.notify_no_formatters = false
  local conform = require("conform")
  conform.setup(opts)

  -- Check every path and required formatter before writing any files.
  local files, seen = {}, {}
  for _, path in ipairs(arg) do
    local absolute = vim.fn.fnamemodify(path, ":p")
    local stat = vim.uv.fs_stat(absolute)
    assert(stat and stat.type == "file", "Not an existing regular file: " .. path)
    local real = vim.uv.fs_realpath(absolute)
    if not seen[real] then
      seen[real] = true
      local buf = vim.fn.bufadd(absolute)
      vim.fn.bufload(buf)
      local ft = vim.filetype.match({ buf = buf, filename = absolute })
      assert(ft, "Cannot detect filetype: " .. path)
      vim.bo[buf].filetype = ft
      local names = conform.list_formatters_for_buffer(buf)
      assert(#names > 0, "No configured formatter for " .. path .. " (" .. ft .. ")")
      for _, name in ipairs(names) do
        local info = conform.get_formatter_info(name, buf)
        assert(
          info.available,
          "Formatter " .. name .. " unavailable for " .. path .. ": " .. (info.available_msg or "check :FormatterInfo")
        )
      end
      local prepared, err = require("util.format").options(buf)
      assert(prepared, err)
      files[#files + 1] = { path = path, buf = buf }
    end
  end

  for _, file in ipairs(files) do
    local completed, format_error = false, nil
    local started = require("util.format").format(file.buf, { async = false }, function(err)
      completed, format_error = true, err
    end)
    assert(started ~= false and completed, "Formatting did not complete: " .. file.path)
    assert(not format_error, file.path .. ": " .. tostring(format_error))
    if vim.bo[file.buf].modified then
      vim.api.nvim_buf_call(file.buf, function()
        vim.cmd("silent noautocmd write")
      end)
    end
    field("formatted", file.path)
  end
end

local ok, err = pcall(run)
if not ok then
  field("error", tostring(err):gsub("^.-:%d+: ", ""))
  field("help", "Resolve the reported file or formatter problem, then rerun format.sh with the same paths")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
