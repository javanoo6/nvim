local M = {}

function M.install()
  local gui = require("venv-selector.gui")
  if M.installed then
    return
  end
  M.installed = true
  local target
  local open = gui.open
  local function is_python(buf)
    return buf and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" and vim.bo[buf].filetype == "python"
  end
  gui.open = function(opts)
    opts = vim.tbl_extend("force", {}, opts or {})
    local buf = opts.bufnr or vim.api.nvim_get_current_buf()
    if not is_python(buf) then
      buf = vim.fn.bufnr("#")
    end
    target = is_python(buf) and buf or nil
    if not target then
      vim.notify("Open a Python file before selecting its venv", vim.log.levels.WARN)
      return
    end
    opts.bufnr = target
    return open(opts)
  end
  require("venv-selector.gui.utils").select = function(entry)
    if not entry or not is_python(target) then
      return
    end
    local buf = target
    vim.api.nvim_buf_call(buf, function()
      local venv = require("venv-selector.venv")
      local same = require("venv-selector").python() == entry.path
      venv.set_source(entry.source)
      if not venv.activate_for_buffer(entry.path, entry.type, buf, { save_cache = true }) then
        return
      end
      -- Upstream skips buffer memory and cache writes when already active.
      vim.b[buf].venv_selector_last_python = entry.path
      vim.b[buf].venv_selector_last_type = entry.type or "venv"
      if same then
        require("venv-selector.cached_venv").save(entry.path, entry.type or "venv", buf)
      end
    end)
  end
end

return M
