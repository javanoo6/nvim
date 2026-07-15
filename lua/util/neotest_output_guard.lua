local M = {}

local DEFAULT_MAX_BYTES = 2 * 1024 * 1024

local function max_bytes()
  local value = tonumber(vim.g.neotest_output_max_bytes)
  if value and value > 0 then
    return math.floor(value)
  end
  return DEFAULT_MAX_BYTES
end

local function human_bytes(bytes)
  if bytes >= 1024 * 1024 then
    return string.format("%.1f MiB", bytes / 1024 / 1024)
  end
  if bytes >= 1024 then
    return string.format("%.1f KiB", bytes / 1024)
  end
  return tostring(bytes) .. " B"
end

local function read_chunk(fd, size, offset)
  if size <= 0 then
    return ""
  end

  local err, data = vim.uv.fs_read(fd, size, offset)
  assert(not err, err)
  return data or ""
end

local function read_capped(path)
  local limit = max_bytes()
  local stat = vim.uv.fs_stat(path)
  if not stat or not stat.size or stat.size <= limit then
    return require("neotest.lib").files.read(path)
  end

  local open_err, fd = vim.uv.fs_open(path, "r", 438)
  assert(not open_err and fd, open_err)

  local head_size = math.floor(limit / 2)
  local tail_size = limit - head_size
  local head = read_chunk(fd, head_size, 0)
  local tail = read_chunk(fd, tail_size, math.max(stat.size - tail_size, 0))

  local close_err = vim.uv.fs_close(fd)
  assert(not close_err, close_err)

  return table.concat({
    "[neotest] Output truncated for Neovim safety.",
    "Shown: first " .. human_bytes(#head) .. " and last " .. human_bytes(#tail) .. ".",
    "Original size: " .. human_bytes(stat.size) .. ".",
    "Full output file: " .. path,
    "",
    head,
    "",
    "[neotest] ... middle omitted ...",
    "",
    tail,
  }, "\n")
end

local function guarded_output_consumer()
  local nio = require("nio")
  local lib = require("neotest.lib")
  local config = require("neotest.config")

  local win, short_opened

  local function open_output(result, opts)
    local output = opts.short and result.short or (result.output and read_capped(result.output))
    if not output then
      if not opts.quiet then
        lib.notify("Output not found for position", vim.log.levels.WARN)
      end
      return
    end
    local buf = nio.api.nvim_create_buf(false, true)

    local chan = lib.ui.open_term(buf)

    short_opened = opts.short
    local dos_newlines = string.find(output, "\r\n") ~= nil
    nio.api.nvim_chan_send(chan, dos_newlines and output or output:gsub("\n", "\r\n"))

    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    vim.api.nvim_buf_set_option(buf, "modifiable", false)

    nio.sleep(10)
    nio.api.nvim_create_autocmd("TermEnter", {
      buffer = buf,
      callback = function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), "n", false)
      end,
    })

    local lines = nio.api.nvim_buf_get_lines(buf, 0, -1, false)
    local width, height = 80, #lines
    for i, line in ipairs(lines) do
      if i > 500 then
        break
      end
      local line_length = vim.str_utfindex(line)
      if line_length > width then
        width = line_length
      end
    end

    local on_close = function()
      pcall(vim.fn.chanclose, chan)
      win = nil
    end

    opts.open_win = opts.open_win
      or function(win_opts)
        local float = lib.ui.float.open({
          width = win_opts.width,
          height = win_opts.height,
          buffer = buf,
          auto_close = opts.auto_close,
        })
        float:listen("close", on_close)
        return float.win_id
      end

    local cur_win = vim.api.nvim_get_current_win()

    win = opts.open_win({ width = width, height = height }) or vim.api.nvim_get_current_win()

    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(win),
      callback = on_close,
    })
    vim.api.nvim_win_set_buf(win, buf)

    if opts.enter then
      vim.api.nvim_set_current_win(win)
    elseif cur_win ~= vim.api.nvim_get_current_win() then
      vim.api.nvim_set_current_win(cur_win)
    end

    vim.api.nvim_buf_set_option(buf, "filetype", "neotest-output")
  end

  local neotest = {}
  neotest.output = {}

  local client

  local init = function()
    if config.output.open_on_run then
      client.listeners.results = function(_, results)
        if win then
          return
        end
        local cur_pos = nio.fn.getpos(".")
        local line = cur_pos[2] - 1
        local buf_path = vim.fn.expand("%:p")
        local positions = client:get_position(buf_path)
        if not positions then
          return
        end
        for _, node in positions:iter_nodes() do
          local pos = node:data()
          local range = node:closest_value_for("range")
          if pos.type == "test" and results[pos.id] and results[pos.id].status == "failed" and range[1] <= line and range[3] >= line then
            open_output(results[pos.id], { short = config.output.open_on_run == "short", enter = false, quiet = true })
          end
        end
      end
    end
  end

  function neotest.output.open(opts)
    opts = opts or {}
    if win then
      if opts.short ~= short_opened then
        pcall(vim.api.nvim_win_close, win, true)
      else
        if pcall(vim.api.nvim_set_current_win, win) then
          return
        end
        opts.enter = true
      end
    end
    local tree, adapter_id
    if opts.last_run then
      local position_id, last_args = require("neotest").run.get_last_run()
      if position_id and last_args then
        tree, adapter_id = client:get_position(position_id, last_args)
      end
      if not tree then
        lib.notify("Last test run no longer exists")
        return
      end
    elseif not opts.position_id then
      local file_path = vim.fn.expand("%:p")
      local row = vim.fn.getbufinfo(file_path)[1].lnum - 1
      tree, adapter_id = client:get_nearest(file_path, row, opts)
    else
      tree, adapter_id = client:get_position(opts.position_id, opts)
    end
    if not tree then
      lib.notify("No tests found in file", vim.log.levels.WARN)
      return
    end
    local result = client:get_results(adapter_id)[tree:data().id]
    if not result then
      lib.notify("No output for " .. tree:data().name)
      return
    end
    open_output(result, opts)
  end

  neotest.output.open = nio.create(neotest.output.open, 1)

  neotest.output = setmetatable(neotest.output, {
    __call = function(_, client_)
      client = client_
      init()
      return neotest.output
    end,
  })

  return neotest.output
end

local function guarded_output_panel_consumer()
  local lib = require("neotest.lib")
  local nio = require("nio")
  local OutputPanel = require("neotest.consumers.output_panel.panel")

  local panel
  local neotest = {}
  local chan

  neotest.output_panel = {}

  local channel_is_valid = function(chan_id)
    return chan_id and pcall(nio.api.nvim_chan_send, chan_id, "\n")
  end

  local init = function(client)
    panel = OutputPanel(client)

    client.listeners.results = function(adapter_id, results, partial)
      if partial then
        return
      end

      if not channel_is_valid(chan) then
        chan = lib.ui.open_term(panel.win:buffer())
        nio.api.nvim_buf_set_option(panel.win:buffer(), "modifiable", true)
        nio.api.nvim_buf_set_lines(panel.win:buffer(), 0, -1, false, {})
        nio.api.nvim_buf_set_option(panel.win:buffer(), "modifiable", false)
      end
      local files_to_read = {}

      local tree = client:get_position(nil, { adapter = adapter_id })
      assert(tree, "No tree for adapter " .. adapter_id)
      for pos_id, result in pairs(results) do
        if result.output and not files_to_read[result.output] and tree:get_key(pos_id) and tree:get_key(pos_id):data().type == "test" then
          files_to_read[result.output] = true
        end
      end

      for file, _ in pairs(files_to_read) do
        local output = read_capped(file)
        local dos_newlines = string.find(output, "\r\n") ~= nil
        if not pcall(nio.api.nvim_chan_send, chan, dos_newlines and output or output:gsub("\n", "\r\n")) then
          lib.notify(("Error sending output to term channel: %s"):format(chan), vim.log.levels.ERROR)
          chan = nil
          break
        end
      end
    end
  end

  function neotest.output_panel.open()
    panel.win:open()
  end

  function neotest.output_panel.close()
    panel.win:close()
  end

  function neotest.output_panel.toggle()
    if panel.win:is_open() then
      neotest.output_panel.close()
    else
      neotest.output_panel.open()
    end
  end

  function neotest.output_panel.clear()
    if channel_is_valid(chan) then
      vim.fn.chanclose(chan)
      chan = lib.ui.open_term(panel.win:buffer())
    end

    nio.api.nvim_buf_set_option(panel.win:buffer(), "modifiable", true)
    nio.api.nvim_buf_set_lines(panel.win:buffer(), 0, -1, false, {})
    nio.api.nvim_buf_set_option(panel.win:buffer(), "modifiable", false)
  end

  function neotest.output_panel.buffer()
    return panel.win:buffer()
  end

  neotest.output_panel = setmetatable(neotest.output_panel, {
    __call = function(_, client)
      init(client)
      return neotest.output_panel
    end,
  })

  return neotest.output_panel
end

function M.install()
  package.loaded["neotest.consumers.output"] = guarded_output_consumer()
  package.loaded["neotest.consumers.output_panel"] = guarded_output_panel_consumer()
end

return M
