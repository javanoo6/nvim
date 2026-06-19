local M = {}

local ns = vim.api.nvim_create_namespace("live_hunks")
local group = vim.api.nvim_create_augroup("custom_live_hunks", { clear = true })
local states = {}
local timers = {}

local width = 55

local function is_valid_buf(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

local function is_valid_win(winid)
  return winid and vim.api.nvim_win_is_valid(winid)
end

local function is_live_hunks_buf(bufnr)
  return is_valid_buf(bufnr) and vim.b[bufnr].live_hunks_source_buf ~= nil
end

local function is_source_buf(bufnr)
  if not is_valid_buf(bufnr) or is_live_hunks_buf(bufnr) then
    return false
  end
  if vim.bo[bufnr].buftype ~= "" then
    return false
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name ~= "" and vim.uv.fs_stat(name) ~= nil
end

local function cleanup_state(source_buf)
  local state = states[source_buf]
  if not state then
    return
  end

  if timers[source_buf] then
    timers[source_buf]:stop()
    timers[source_buf]:close()
    timers[source_buf] = nil
  end

  states[source_buf] = nil
end

local function close_state(source_buf)
  local state = states[source_buf]
  if not state then
    return
  end

  if is_valid_win(state.view_win) then
    pcall(vim.api.nvim_win_close, state.view_win, true)
  elseif is_valid_buf(state.view_buf) then
    pcall(vim.api.nvim_buf_delete, state.view_buf, { force = true })
  end

  cleanup_state(source_buf)
end

local function relpath(root, path)
  if vim.fs.relpath then
    return vim.fs.relpath(root, path) or path
  end
  local prefix = root:sub(-1) == "/" and root or (root .. "/")
  if path:sub(1, #prefix) == prefix then
    return path:sub(#prefix + 1)
  end
  return path
end

local function fallback_hunks(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local root = vim.fs.root(file, ".git")
  if not root then
    return nil
  end

  local output = vim.fn.systemlist({
    "git",
    "-C",
    root,
    "diff",
    "--no-ext-diff",
    "--unified=0",
    "--",
    relpath(root, file),
  })
  if vim.v.shell_error ~= 0 then
    return nil
  end

  local hunks = {}
  local current
  for _, line in ipairs(output) do
    local old_start, old_count, new_start, new_count = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
    if old_start then
      old_count = old_count == "" and "1" or old_count
      new_count = new_count == "" and "1" or new_count
      current = {
        head = line,
        lines = {},
        removed = { start = tonumber(old_start), count = tonumber(old_count) },
        added = { start = tonumber(new_start), count = tonumber(new_count) },
      }
      if current.added.count == 0 then
        current.type = "delete"
      elseif current.removed.count == 0 then
        current.type = "add"
      else
        current.type = "change"
      end
      hunks[#hunks + 1] = current
    elseif current and (line:sub(1, 1) == "+" or line:sub(1, 1) == "-") then
      if not line:match("^%+%+%+") and not line:match("^%-%-%-") then
        current.lines[#current.lines + 1] = line
      end
    end
  end

  return hunks
end

local function get_hunks(bufnr)
  local ok, gs = pcall(require, "gitsigns")
  if ok and gs.get_hunks then
    local ok_hunks, hunks = pcall(gs.get_hunks, bufnr)
    if ok_hunks and hunks then
      return hunks
    end
  end
  return fallback_hunks(bufnr) or {}
end

local function status_label(hunk)
  if hunk.type == "add" then
    return "added"
  elseif hunk.type == "delete" then
    return "deleted"
  end
  return "changed"
end

local function hunk_row(hunk)
  local start = hunk.added and hunk.added.start or 1
  if start == 0 then
    return 1
  end
  return start
end

local function render_lines(source_buf, hunks)
  local line_count = math.max(vim.api.nvim_buf_line_count(source_buf), 1)
  local lines = {}
  local highlights = {}

  for _ = 1, line_count do
    lines[#lines + 1] = ""
  end

  for _, hunk in ipairs(hunks) do
    local row = math.min(math.max(hunk_row(hunk), 1), #lines)
    local block = { ("%s  %s"):format(hunk.head or "@@ @@", status_label(hunk)) }
    vim.list_extend(block, hunk.lines or {})

    for index, text in ipairs(block) do
      local target = row + index - 1
      while target > #lines do
        lines[#lines + 1] = ""
      end
      if lines[target] ~= "" then
        lines[target] = lines[target] .. "  |  " .. text
      else
        lines[target] = text
      end
      highlights[target] = highlights[target] or {}
      highlights[target][#highlights[target] + 1] = text
    end
  end

  if #hunks == 0 then
    lines[1] = "No unstaged hunks"
  end

  return lines, highlights
end

local function apply_highlights(bufnr, highlights)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for lnum, chunks in pairs(highlights) do
    local offset = 0
    for _, text in ipairs(chunks) do
      local hl = "DiffText"
      if text:sub(1, 1) == "+" then
        hl = "DiffAdd"
      elseif text:sub(1, 1) == "-" then
        hl = "DiffDelete"
      elseif text:sub(1, 2) == "@@" then
        hl = "DiffChange"
      end
      vim.api.nvim_buf_add_highlight(bufnr, ns, hl, lnum - 1, offset, offset + #text)
      offset = offset + #text + 5
    end
  end
end

local function sync_view(state)
  if not is_valid_win(state.source_win) or not is_valid_win(state.view_win) then
    return
  end
  local view = vim.api.nvim_win_call(state.source_win, vim.fn.winsaveview)
  pcall(vim.api.nvim_win_call, state.view_win, function()
    vim.fn.winrestview({
      topline = view.topline,
      lnum = math.max(view.topline, 1),
      col = 0,
      leftcol = 0,
    })
  end)
end

function M.refresh(source_buf)
  source_buf = source_buf or vim.api.nvim_get_current_buf()
  local state = states[source_buf]
  if not state then
    return
  end
  if not is_source_buf(source_buf) or not is_valid_buf(state.view_buf) then
    close_state(source_buf)
    return
  end

  local hunks = get_hunks(source_buf)
  local lines, highlights = render_lines(source_buf, hunks)

  vim.bo[state.view_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.view_buf, 0, -1, false, lines)
  vim.bo[state.view_buf].modifiable = false
  apply_highlights(state.view_buf, highlights)
  sync_view(state)
end

function M.schedule_refresh(source_buf, delay)
  source_buf = source_buf or vim.api.nvim_get_current_buf()
  if not states[source_buf] then
    return
  end

  delay = delay or 120
  if timers[source_buf] then
    timers[source_buf]:stop()
  else
    timers[source_buf] = vim.uv.new_timer()
  end

  timers[source_buf]:start(delay, 0, function()
    vim.schedule(function()
      if states[source_buf] then
        M.refresh(source_buf)
      end
    end)
  end)
end

local function configure_view_window(winid)
  vim.wo[winid].number = false
  vim.wo[winid].relativenumber = false
  vim.wo[winid].signcolumn = "no"
  vim.wo[winid].foldcolumn = "0"
  vim.wo[winid].wrap = false
  vim.wo[winid].cursorline = false
  vim.wo[winid].spell = false
  vim.wo[winid].list = false
  vim.wo[winid].winfixwidth = true
end

local function create_view(source_buf, source_win)
  local view_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[view_buf].buftype = "nofile"
  vim.bo[view_buf].bufhidden = "wipe"
  vim.bo[view_buf].swapfile = false
  vim.bo[view_buf].modifiable = false
  vim.bo[view_buf].filetype = "diff"
  vim.b[view_buf].live_hunks_source_buf = source_buf
  pcall(vim.diagnostic.enable, false, { bufnr = view_buf })

  local view_win
  vim.api.nvim_win_call(source_win, function()
    vim.cmd(("botright vertical %dnew"):format(width))
    view_win = vim.api.nvim_get_current_win()
  end)

  vim.api.nvim_win_set_buf(view_win, view_buf)
  vim.api.nvim_win_set_width(view_win, width)
  configure_view_window(view_win)
  vim.api.nvim_set_current_win(source_win)

  states[source_buf] = {
    source_buf = source_buf,
    source_win = source_win,
    view_buf = view_buf,
    view_win = view_win,
  }

  M.refresh(source_buf)
end

function M.open()
  local source_buf = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()

  if is_live_hunks_buf(source_buf) then
    source_buf = vim.b[source_buf].live_hunks_source_buf
    local state = states[source_buf]
    if state and is_valid_win(state.source_win) then
      source_win = state.source_win
    end
  end

  if not is_source_buf(source_buf) then
    vim.notify("Live hunks needs a file-backed git buffer", vim.log.levels.WARN)
    return
  end

  local state = states[source_buf]
  if state and is_valid_win(state.view_win) then
    state.source_win = source_win
    sync_view(state)
    return
  end

  create_view(source_buf, source_win)
end

function M.close()
  local bufnr = vim.api.nvim_get_current_buf()
  if is_live_hunks_buf(bufnr) then
    close_state(vim.b[bufnr].live_hunks_source_buf)
  else
    close_state(bufnr)
  end
end

function M.toggle()
  local bufnr = vim.api.nvim_get_current_buf()
  local source_buf = is_live_hunks_buf(bufnr) and vim.b[bufnr].live_hunks_source_buf or bufnr
  local state = states[source_buf]
  if state and is_valid_win(state.view_win) then
    close_state(source_buf)
  else
    M.open()
  end
end

local function state_for_win(winid)
  for _, state in pairs(states) do
    if state.source_win == winid or state.view_win == winid then
      return state
    end
  end
end

function M.setup()
  vim.api.nvim_create_user_command("LiveHunksToggle", function()
    M.toggle()
  end, { desc = "Toggle live git hunks view" })

  vim.api.nvim_create_user_command("LiveHunksClose", function()
    M.close()
  end, { desc = "Close live git hunks view" })

  vim.api.nvim_create_user_command("LiveHunksRefresh", function()
    local bufnr = vim.api.nvim_get_current_buf()
    if is_live_hunks_buf(bufnr) then
      bufnr = vim.b[bufnr].live_hunks_source_buf
    end
    M.refresh(bufnr)
  end, { desc = "Refresh live git hunks view" })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
    group = group,
    callback = function(args)
      M.schedule_refresh(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "GitsignsUpdate",
    callback = function(args)
      M.schedule_refresh(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("WinScrolled", {
    group = group,
    callback = function(args)
      local winid = tonumber(args.match)
      local state = winid and state_for_win(winid)
      if state then
        sync_view(state)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    group = group,
    callback = function(args)
      if states[args.buf] then
        close_state(args.buf)
      elseif is_live_hunks_buf(args.buf) then
        cleanup_state(vim.b[args.buf].live_hunks_source_buf)
      end
    end,
  })
end

return M
