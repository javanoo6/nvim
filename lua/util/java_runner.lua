local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "java runner" })
end

local function get_jdtls_client(bufnr)
  local clients = vim.lsp.get_clients({
    bufnr = bufnr,
    name = "jdtls",
  })

  return clients[1]
end

local function now_ms()
  return vim.uv.hrtime() / 1000000
end

local function ensure_jdtls(bufnr, on_ready)
  if get_jdtls_client(bufnr) then
    on_ready()
    return
  end

  if vim.bo[bufnr].filetype ~= "java" then
    notify("Current buffer is not a Java file", vim.log.levels.WARN)
    return
  end

  pcall(vim.lsp.enable, "jdtls")

  local deadline = now_ms() + 8000
  local announced_wait = false

  local function poll()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end

    if get_jdtls_client(bufnr) then
      on_ready()
      return
    end

    if now_ms() >= deadline then
      notify("jdtls did not attach within 8s; check :checkhealth vim.lsp", vim.log.levels.ERROR)
      return
    end

    if not announced_wait then
      announced_wait = true
      notify("Waiting for jdtls to attach before running main...")
    end

    vim.defer_fn(poll, 200)
  end

  poll()
end

function M.run_main(args)
  local bufnr = vim.api.nvim_get_current_buf()

  ensure_jdtls(bufnr, function()
    require("java").runner.built_in.run_app({ args = args or "" })
  end)
end

function M.stop_main()
  require("java").runner.built_in.stop_app()
end

function M.toggle_logs()
  require("java").runner.built_in.toggle_logs()
end

return M
