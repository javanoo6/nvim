local M = {}

local function command_exists(name)
  return vim.fn.executable(name) == 1
end

local function exepath(name)
  local path = vim.fn.exepath(name)
  if path == "" then
    return nil
  end
  return path
end

local function env_set(name)
  local value = vim.env[name]
  return value ~= nil and value ~= ""
end

local function provider(name, copy, paste)
  return {
    name = name,
    copy = {
      ["+"] = copy.plus,
      ["*"] = copy.star or copy.plus,
    },
    paste = {
      ["+"] = paste.plus,
      ["*"] = paste.star or paste.plus,
    },
    cache_enabled = 1,
  }
end

local function detect_provider()
  local wl_copy = exepath("wl-copy")
  local wl_paste = exepath("wl-paste")
  if env_set("WAYLAND_DISPLAY") and wl_copy and wl_paste then
    return provider("wl-clipboard", {
      plus = { wl_copy, "--type", "text/plain" },
      star = { wl_copy, "--primary", "--type", "text/plain" },
    }, {
      plus = { wl_paste, "--no-newline" },
      star = { wl_paste, "--no-newline", "--primary" },
    })
  end

  local xclip = exepath("xclip")
  if env_set("DISPLAY") and xclip then
    return provider("xclip-absolute", {
      plus = { xclip, "-quiet", "-i", "-selection", "clipboard" },
      star = { xclip, "-quiet", "-i", "-selection", "primary" },
    }, {
      plus = { xclip, "-o", "-selection", "clipboard" },
      star = { xclip, "-o", "-selection", "primary" },
    })
  end

  local xsel = exepath("xsel")
  if env_set("DISPLAY") and xsel then
    return provider("xsel-absolute", {
      plus = { xsel, "--nodetach", "-i", "-b" },
      star = { xsel, "--nodetach", "-i", "-p" },
    }, {
      plus = { xsel, "-o", "-b" },
      star = { xsel, "-o", "-p" },
    })
  end

  if command_exists("tmux") and env_set("TMUX") then
    local tmux = exepath("tmux") or "tmux"
    return provider("tmux-absolute", {
      plus = { tmux, "load-buffer", "-w", "-" },
    }, {
      plus = { "sh", "-c", tmux .. " refresh-client -l && sleep 0.05 && " .. tmux .. " save-buffer -" },
    })
  end

  return nil
end

function M.setup()
  local clipboard = detect_provider()
  if clipboard then
    vim.g.clipboard = clipboard
    vim.opt.clipboard = "unnamedplus"
  else
    vim.opt.clipboard = ""
  end
end

function M.set_text(text)
  local ok, err = pcall(vim.fn.setreg, "+", text)
  if ok then
    return "+", nil
  end

  vim.fn.setreg('"', text)
  return '"', err
end

return M
