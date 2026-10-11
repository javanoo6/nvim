local M = {}

local standalone_filetypes = { java = true, markdown = true, xml = true, python = true, yaml = true, sh = true }

function M.options(bufnr, opts)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  opts = vim.tbl_extend("force", { bufnr = bufnr, timeout_ms = 10000, lsp_format = "fallback" }, opts or {})
  local ft = vim.bo[bufnr].filetype
  if standalone_filetypes[ft] then
    local jar = vim.fn.stdpath("config") .. "/intellij-code-formatter/formatter-cli/target/formatter-cli-full.jar"
    if vim.fn.executable("java") ~= 1 then
      return nil, "Standalone IntelliJ formatter requires java on PATH"
    end
    if vim.fn.filereadable(jar) ~= 1 then
      return nil, "Standalone IntelliJ formatter jar missing: " .. jar
    end
    opts.lsp_format = "never"
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
  return vim.api.nvim_buf_call(prepared.bufnr, function()
    return require("conform").format(prepared, callback)
  end)
end

return M
