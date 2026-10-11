local M = {}
local restarting = {}
local heads = {}
local polling = {}

function M.client(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  return require("intellij-lsp.client").find_ancestor_client(path ~= "" and path or vim.fn.getcwd())
end

function M.restart(clear_cache)
  local client = M.client()
  if not client then
    vim.notify("No IntelliJ workspace for this buffer", vim.log.levels.WARN)
    return
  end
  local root = client.config.root_dir
  if restarting[root] then
    return
  end
  restarting[root] = true
  local buffers = {}
  for bufnr in pairs(client.attached_buffers) do
    buffers[#buffers + 1] = bufnr
  end
  client:stop()
  local started = vim.uv.hrtime()
  local forced = false
  local function resume()
    if vim.lsp.get_client_by_id(client.id) then
      if not forced and vim.uv.hrtime() - started > 3000000000 then
        forced = true
        client:stop(true)
      end
      if vim.uv.hrtime() - started > 10000000000 then
        restarting[root] = nil
        vim.notify("IntelliJ did not stop; cache kept intact", vim.log.levels.ERROR)
        return
      end
      vim.defer_fn(resume, 100)
      return
    end
    if clear_cache then
      local path = client.config.index_dir
      local base = client.config.system_path
      local owner = base and require("intellij-lsp.launch").system_path_owner(base)
      if owner and owner ~= vim.uv.os_getpid() then
        restarting[root] = nil
        vim.notify("IntelliJ cache is now owned by another Neovim; no cache deleted", vim.log.levels.ERROR)
        return
      end
      if not path or not base or not vim.startswith(vim.fs.normalize(path), vim.fs.normalize(base) .. "/") then
        restarting[root] = nil
        vim.notify("IntelliJ index path missing/outside workspace cache; no cache deleted", vim.log.levels.ERROR)
        return
      end
      if vim.fn.delete(path, "rf") ~= 0 then
        restarting[root] = nil
        vim.notify("Could not delete IntelliJ index: " .. path, vim.log.levels.ERROR)
        return
      end
    end
    local opts = require("util.java_intellij").project_options(root, require("intellij-lsp").config)
    local config = require("intellij-lsp.client").config(root, opts)
    local id = vim.lsp.start_client(config)
    for _, bufnr in ipairs(buffers) do
      if id and vim.api.nvim_buf_is_loaded(bufnr) then
        vim.lsp.buf_attach_client(bufnr, id)
      end
    end
    restarting[root] = nil
  end
  resume()
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufEnter", "SessionLoadPost", "FocusGained", "LspAttach" }, {
    group = vim.api.nvim_create_augroup("IntellijWorkspaceAttach", { clear = true }),
    callback = function(event)
      local bufnr = event.event == "LspAttach" and event.buf or vim.api.nvim_get_current_buf()
      if vim.bo[bufnr].filetype ~= "java" then
        return
      end
      local factory = require("intellij-lsp.client")
      local existing = factory.find_ancestor_client(vim.api.nvim_buf_get_name(bufnr))
      if existing then
        vim.lsp.buf_attach_client(bufnr, existing.id)
        local root = existing.config.root_dir
        if existing.initialized and not polling[root] then
          polling[root] = true
          vim.system(
            { "git", "-C", root, "rev-parse", "HEAD" },
            { text = true },
            vim.schedule_wrap(function(result)
              polling[root] = nil
              if result.code ~= 0 then
                return
              end
              local head = vim.trim(result.stdout)
              local changed = heads[root] and heads[root] ~= head
              heads[root] = head
              if changed and vim.api.nvim_buf_is_loaded(bufnr) and not existing:is_stopped() then
                require("util.java_project_config").update(bufnr)
              end
            end)
          )
        end
        return
      end
      local root = factory.find_root(bufnr)
      if not root or restarting[root] then
        return
      end
      vim.lsp.start(factory.config(root, require("intellij-lsp").config), { bufnr = bufnr })
    end,
  })
end

function M.register_commands()
  vim.api.nvim_create_user_command("JavaRestart", function()
    M.restart(false)
  end, { desc = "Restart current IntelliJ workspace" })
  vim.api.nvim_create_user_command("JavaCleanCorruptWorkspaces", function()
    M.restart(true)
  end, { bang = true, desc = "Clear current IntelliJ index and restart" })
  vim.api.nvim_create_user_command("JavaBranchRefresh", function()
    require("util.java_project_config").update()
  end, { desc = "Reload current IntelliJ workspace after branch changes" })
end

return M
