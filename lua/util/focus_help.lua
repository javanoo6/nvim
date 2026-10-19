local M = {}
local win, buf
local profiles = {}

function M.close()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  win = nil
end

function M.refresh()
  local current = vim.api.nvim_get_current_win()
  local profile
  for _, candidate in pairs(profiles) do
    if candidate.matches(vim.bo.filetype) then
      profile = candidate
      break
    end
  end
  if
    not profile
    or profile.enabled == false
    or vim.fn.mode() ~= "n"
    or (vim.api.nvim_win_get_config(current).relative ~= "" and not profile.allow_float)
  then
    M.close()
    return
  end

  local lines = profile.lines(vim.bo.filetype)
  local width = math.min(40, vim.o.columns - 4)
  local height = math.min(#lines, vim.o.lines - vim.o.cmdheight - 4)
  if width < 20 or height < 4 then
    M.close()
    return
  end
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "hide"
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local config = {
    relative = "editor",
    anchor = "NE",
    row = 1,
    col = vim.o.columns - 2,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " " .. profile.title .. " ",
    title_pos = "center",
    focusable = false,
    zindex = profile.zindex or 40,
  }
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_config(win, config)
  else
    win = vim.api.nvim_open_win(buf, false, config)
    vim.wo[win].winblend = 10
    vim.wo[win].wrap = false
  end
end

function M.toggle(name)
  local profile = assert(profiles[name], "Unknown shortcut popup: " .. name)
  profile.enabled = profile.enabled == false
  M.refresh()
end

function M.register(name, profile)
  local first = next(profiles) == nil
  profiles[name] = profile
  if profile.filetypes then
    local function attach(buffer)
      vim.keymap.set("n", "gH", function()
        M.toggle(name)
      end, { buffer = buffer, silent = true, desc = "Toggle " .. profile.title .. " popup" })
    end
    local group = vim.api.nvim_create_augroup("FocusShortcutHelp_" .. name, { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = profile.filetypes,
      callback = function(event)
        attach(event.buf)
      end,
    })
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
      if vim.tbl_contains(profile.filetypes, vim.bo[buffer].filetype) then
        attach(buffer)
      end
    end
  end
  if first then
    local group = vim.api.nvim_create_augroup("FocusShortcutHelp", { clear = true })
    vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "FileType", "ModeChanged", "VimResized", "WinClosed" }, {
      group = group,
      callback = function()
        vim.schedule(M.refresh)
      end,
      desc = "Show shortcut help for the focused tool in Normal mode",
    })
  end
end

return M
