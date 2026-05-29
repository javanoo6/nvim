local M = {}

local api = vim.api

local namespace = api.nvim_create_namespace("custom_java_codelens")
local pending = {}

local function clear(bufnr)
  api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
end

local function line_length(bufnr, row)
  local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  return #line
end

local function render(bufnr, lenses)
  if not api.nvim_buf_is_valid(bufnr) then
    return
  end

  clear(bufnr)

  local by_row = {}
  for _, lens in ipairs(lenses or {}) do
    local title = lens.command and lens.command.title
    if title and title ~= "" then
      local row = lens.range.start.line
      by_row[row] = by_row[row] or {}
      table.insert(by_row[row], title)
    end
  end

  for row, titles in pairs(by_row) do
    api.nvim_buf_set_extmark(bufnr, namespace, row, line_length(bufnr, row), {
      virt_text = { { "  " .. table.concat(titles, " | "), "LspCodeLens" } },
      virt_text_pos = "inline",
      hl_mode = "combine",
    })
  end
end

local function resolve_and_render(client, bufnr, lenses)
  local unresolved = {}
  for i, lens in ipairs(lenses or {}) do
    if lens.command == nil then
      table.insert(unresolved, { index = i, lens = lens })
    end
  end

  if #unresolved == 0 then
    render(bufnr, lenses)
    return
  end

  local remaining = #unresolved
  for _, item in ipairs(unresolved) do
    client:request("codeLens/resolve", item.lens, function(_, resolved)
      if resolved then
        lenses[item.index] = resolved
      end
      remaining = remaining - 1
      if remaining == 0 then
        render(bufnr, lenses)
      end
    end, bufnr)
  end
end

function M.refresh(bufnr, client)
  if not api.nvim_buf_is_valid(bufnr) then
    return
  end

  if pending[bufnr] then
    pending[bufnr]:stop()
    pending[bufnr]:close()
    pending[bufnr] = nil
  end

  local timer = vim.uv.new_timer()
  pending[bufnr] = timer
  timer:start(
    150,
    0,
    vim.schedule_wrap(function()
      if pending[bufnr] == timer then
        pending[bufnr] = nil
      end
      if not timer:is_closing() then
        timer:stop()
        timer:close()
      end

      if not api.nvim_buf_is_valid(bufnr) or not client or client:is_stopped() then
        return
      end

      client:request("textDocument/codeLens", {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
      }, function(err, result, ctx)
        if err or not api.nvim_buf_is_valid(bufnr) or (ctx and ctx.bufnr and ctx.bufnr ~= bufnr) then
          return
        end
        resolve_and_render(client, bufnr, result or {})
      end, bufnr)
    end)
  )
end

function M.attach(bufnr, client)
  local group = require("util").augroup("java_codelens_" .. bufnr)

  api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      M.refresh(bufnr, client)
    end,
  })

  api.nvim_create_autocmd({ "BufHidden", "BufWipeout", "LspDetach" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      clear(bufnr)
      if pending[bufnr] then
        pending[bufnr]:stop()
        pending[bufnr]:close()
        pending[bufnr] = nil
      end
    end,
  })

  vim.schedule(function()
    M.refresh(bufnr, client)
  end)
end

return M
