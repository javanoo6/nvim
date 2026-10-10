local M = {}

-- These former daemon routes have no formatter in the pinned server bundle.
M.unsupported = { markdown = true, python = true, yaml = true, xml = true, sh = true }

function M.options(bufnr, opts)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  opts = vim.tbl_extend("force", { bufnr = bufnr, timeout_ms = 10000, lsp_format = "fallback" }, opts or {})
  local ft = vim.bo[bufnr].filetype
  if M.unsupported[ft] then
    opts.lsp_format = "never"
    return opts
  end
  if ft ~= "java" then
    return opts
  end

  local factory = require("intellij-lsp.client")
  local client = factory.find_ancestor_client(vim.api.nvim_buf_get_name(bufnr))
  if not client then
    local root = factory.find_root(bufnr)
    local cfg = vim.deepcopy(require("intellij-lsp").config)
    if not cfg.accept_eula then
      return nil, "IntelliJ formatting requires EULA acceptance"
    end
    if not root then
      root = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
      if not root or root == "." then
        return nil, "Save the Java file before formatting"
      end
      cfg.build_tool = "" -- Explicit formatting of a standalone file: no build import.
    end
    local id = vim.lsp.start(factory.config(root, cfg), { bufnr = bufnr })
    client = id and vim.lsp.get_client_by_id(id)
  elseif not vim.lsp.buf_is_attached(bufnr, client.id) then
    vim.lsp.buf_attach_client(bufnr, client.id)
  end
  if not client then
    return nil, "Could not start IntelliJ formatting; see :JavaInfo"
  end
  if
    not vim.wait(opts.timeout_ms, function()
      return client.initialized and require("intellij-lsp.progress").is_ready(client.id)
    end, 100)
  then
    return nil, "IntelliJ is importing/indexing; retry formatting after :JavaInfo reports ready"
  end

  opts.name = "intellij"
  opts.id = client.id
  opts.lsp_format = "prefer"
  if vim.b[bufnr].intellij_format_client ~= client.id then
    -- Require a real formatting response before cleanup of a newly prepared
    -- buffer. An empty edits array is valid; a null response is not readiness.
    -- Poll without applying these preliminary edits.
    local deadline = vim.uv.hrtime() + opts.timeout_ms * 1000000
    local registered = false
    repeat
      local remaining = math.max(1, math.floor((deadline - vim.uv.hrtime()) / 1000000))
      local response = client:request_sync("textDocument/formatting", {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
        options = { tabSize = vim.bo[bufnr].shiftwidth, insertSpaces = vim.bo[bufnr].expandtab },
      }, remaining, bufnr)
      registered = response and type(response.result) == "table"
      if not registered then
        vim.wait(100, function()
          return false
        end)
      end
    until registered or vim.uv.hrtime() >= deadline
    if not registered then
      return nil, "IntelliJ has not registered this Java file; retry formatting after indexing"
    end
    vim.b[bufnr].intellij_format_client = client.id
  end
  -- Range formatting must not change imports outside the selected range.
  local mode = vim.fn.mode():sub(1, 1)
  if not opts.range and mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    local response, err = client:request_sync("workspace/executeCommand", {
      command = "java.organize.imports",
      arguments = { vim.uri_from_bufnr(bufnr) },
    }, opts.timeout_ms, bufnr)
    if not response or response.err or response.result ~= true then
      return nil, "IntelliJ import optimization failed: " .. vim.inspect(err or (response and response.err) or response)
    end
  end
  return opts
end

function M.format(bufnr, opts, callback)
  local prepared, err = M.options(bufnr, opts)
  if not prepared then
    if callback then
      callback(err)
    else
      vim.notify(err, vim.log.levels.WARN, { title = "Formatting" })
    end
    return false
  end
  -- Conform's LSP parameters read the current buffer's URI and indentation.
  return vim.api.nvim_buf_call(prepared.bufnr, function()
    return require("conform").format(prepared, callback)
  end)
end

return M
