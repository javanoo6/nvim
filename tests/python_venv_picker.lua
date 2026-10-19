local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo)
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/venv-selector.nvim")

local function run()
  local fixture = vim.fn.tempname()
  vim.fn.mkdir(fixture, "p")
  local python = fixture .. "/python"
  vim.fn.writefile({}, python)
  local function buffer(name)
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, fixture .. "/" .. name .. ".py")
    vim.bo[buf].filetype = "python"
    return buf
  end
  local other = buffer("other")
  local origin = buffer("origin")
  vim.api.nvim_set_current_buf(origin)
  vim.b[origin].venv_selector_last_python = "old-python"

  -- Exercise real upstream activation, including its already-active early return.
  local config = require("venv-selector.config")
  config.user_settings = {
    hooks = {},
    options = {},
  }
  local venv = require("venv-selector.venv")
  venv.update_paths = function() end
  local saves = {}
  require("venv-selector.cached_venv").save = function(path, _, buf)
    saves[#saves + 1] = { path, buf }
  end
  local search_buf
  package.loaded["venv-selector.gui"] = {
    open = function(opts)
      search_buf = opts.bufnr
    end,
  }
  require("util.python_venv_picker").install()
  local gui = require("venv-selector.gui")
  local confirm = require("venv-selector.gui.utils").select
  gui.open()
  assert(search_buf == origin, "Search must use originating buffer")
  -- Popup activity changes current/alternate buffer before confirmation.
  vim.api.nvim_set_current_buf(other)
  confirm({ path = python, type = "venv", source = "workspace" })
  assert(vim.b[origin].venv_selector_last_python == python, "Selection must update origin")
  assert(vim.b[other].venv_selector_last_python == nil, "Selection must preserve other buffer")
  assert(saves[#saves][2] == origin, "Cache must use originating project")
  assert(vim.api.nvim_get_current_buf() == other, "Activation must restore picker context")

  -- Selecting an interpreter active in another buffer must still save the choice.
  vim.api.nvim_set_current_buf(other)
  gui.open()
  confirm({ path = python, type = "venv", source = "workspace" })
  assert(vim.b[other].venv_selector_last_python == python, "Already-active selection must update memory")
  assert(saves[#saves][2] == other, "Already-active selection must update cache")

  local count = #saves
  vim.api.nvim_buf_delete(other, { force = true })
  confirm({ path = python, type = "venv", source = "workspace" })
  assert(#saves == count, "Deleted origin must not redirect selection")
  vim.fn.delete(fixture, "rf")
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit 1")
end
print("Python venv picker regression checks passed")
vim.cmd("qa!")
