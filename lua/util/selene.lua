local M = {}
local installing = false

-- Mason has no Linux ARM64 Selene asset. Build the pinned crate instead;
-- Omarchy's mise can supply Rust without changing global tool settings.
function M.source_install()
  local host = vim.uv.os_uname()
  return host.sysname == "Linux" and (host.machine == "aarch64" or host.machine == "arm64")
end

function M.install()
  if installing or vim.fn.executable("selene") == 1 then
    return
  end
  local cmd
  if vim.fn.executable("cargo") == 1 then
    cmd = { "cargo" }
  elseif vim.fn.executable("mise") == 1 then
    cmd = { "mise", "exec", "rust@stable", "--", "cargo" }
  else
    vim.notify("Selene requires Cargo or mise on Linux ARM64. Install either, then run :SeleneInstall", vim.log.levels.ERROR)
    return
  end
  vim.list_extend(cmd, { "install", "selene", "--version", "0.31.0", "--locked", "--root", vim.fn.expand("~/.local") })
  installing = true
  vim.notify("Building Selene for ARM64 (first install may take a few minutes)")
  local ok, err = pcall(vim.system, cmd, { text = true }, function(result)
    vim.schedule(function()
      installing = false
      if result.code == 0 then
        vim.notify("Selene installed")
      else
        vim.notify("Selene build failed; retry with :SeleneInstall\n" .. (result.stderr or ""), vim.log.levels.ERROR)
      end
    end)
  end)
  if not ok then
    installing = false
    vim.notify("Selene build failed; retry with :SeleneInstall\n" .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.setup()
  if not M.source_install() then
    return
  end
  local bin = vim.fn.expand("~/.local/bin")
  if not vim.tbl_contains(vim.split(vim.env.PATH or "", ":", { plain = true }), bin) then
    vim.env.PATH = bin .. ":" .. (vim.env.PATH or "")
  end
  vim.api.nvim_create_user_command("SeleneInstall", M.install, { desc = "Install Selene from source on Linux ARM64", force = true })
  vim.schedule(M.install)
end

return M
