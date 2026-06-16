local M = {}

local api = vim.api

local namespace = api.nvim_create_namespace("custom_java_field_usages")
local pending = {}
local attached = {}
local generations = {}

local query = vim.treesitter.query.parse(
  "java",
  [[
    (field_declaration
      declarator: (variable_declarator
        name: (identifier) @field.name))
  ]]
)

vim.g.java_field_usages_enabled = vim.g.java_field_usages_enabled ~= false

local function is_enabled()
  return vim.g.java_field_usages_enabled ~= false
end

local function clear(bufnr)
  if api.nvim_buf_is_valid(bufnr) then
    api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  end
end

local function line_length(bufnr, row)
  local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  return #line
end

local function usage_label(count)
  if count == 0 then
    return "no usages"
  end
  if count == 1 then
    return "1 usage"
  end
  return count .. " usages"
end

local function location_key(location)
  local range = location.range or location.targetSelectionRange
  if not range or not range.start then
    return nil
  end
  return table.concat({
    location.uri or location.targetUri or "",
    range.start.line,
    range.start.character,
    range["end"] and range["end"].line or "",
    range["end"] and range["end"].character or "",
  }, ":")
end

local function count_references(result)
  local seen = {}
  local count = 0

  for _, location in ipairs(result or {}) do
    local key = location_key(location)
    if key and not seen[key] then
      seen[key] = true
      count = count + 1
    end
  end

  return count
end

local function collect_fields(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "java")
  if not ok or not parser then
    return {}
  end

  local trees = parser:parse()
  local tree = trees and trees[1]
  if not tree then
    return {}
  end

  local fields = {}
  for _, node in query:iter_captures(tree:root(), bufnr, 0, -1) do
    local start_row, start_col, end_row, end_col = node:range()
    fields[#fields + 1] = {
      row = start_row,
      col = start_col,
      end_row = end_row,
      end_col = end_col,
    }
  end

  table.sort(fields, function(left, right)
    if left.row == right.row then
      return left.col < right.col
    end
    return left.row < right.row
  end)

  return fields
end

local function render(bufnr, fields)
  clear(bufnr)

  for _, field in ipairs(fields) do
    api.nvim_buf_set_extmark(bufnr, namespace, field.row, line_length(bufnr, field.row), {
      virt_text = { { "  " .. usage_label(field.references), "LspCodeLens" } },
      virt_text_pos = "inline",
      hl_mode = "combine",
    })
  end
end

local function cancel_timer(bufnr)
  if pending[bufnr] then
    pending[bufnr]:stop()
    pending[bufnr]:close()
    pending[bufnr] = nil
  end
end

local function next_generation(bufnr)
  generations[bufnr] = (generations[bufnr] or 0) + 1
  return generations[bufnr]
end

local function request_field(client, bufnr, field, done)
  client:request("textDocument/references", {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = {
      line = field.row,
      character = field.col,
    },
    context = {
      includeDeclaration = false,
    },
  }, function(_, result)
    field.references = count_references(result)
    done()
  end, bufnr)
end

local function request_all(client, bufnr, fields, generation)
  local index = 1

  local function step()
    if not api.nvim_buf_is_valid(bufnr) or not client or client:is_stopped() or generations[bufnr] ~= generation then
      return
    end

    if index > #fields then
      render(bufnr, fields)
      return
    end

    local field = fields[index]
    index = index + 1
    request_field(client, bufnr, field, function()
      vim.schedule(step)
    end)
  end

  step()
end

function M.refresh(bufnr, client)
  bufnr = bufnr or api.nvim_get_current_buf()
  client = client or vim.lsp.get_clients({ bufnr = bufnr, name = "jdtls" })[1]

  cancel_timer(bufnr)
  next_generation(bufnr)

  if not is_enabled() or not api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= "java" or not client or client:is_stopped() then
    clear(bufnr)
    return
  end

  local timer = vim.uv.new_timer()
  pending[bufnr] = timer
  timer:start(
    500,
    0,
    vim.schedule_wrap(function()
      if pending[bufnr] == timer then
        pending[bufnr] = nil
      end
      if not timer:is_closing() then
        timer:stop()
        timer:close()
      end

      if not is_enabled() or not api.nvim_buf_is_valid(bufnr) or not client or client:is_stopped() then
        clear(bufnr)
        return
      end

      local fields = collect_fields(bufnr)
      local generation = next_generation(bufnr)
      if #fields == 0 then
        clear(bufnr)
        return
      end

      request_all(client, bufnr, fields, generation)
    end)
  )
end

function M.set_enabled(enabled)
  vim.g.java_field_usages_enabled = enabled
  vim.notify("Java field usages: " .. (enabled and "on" or "off"))

  for bufnr, client in pairs(attached) do
    if enabled then
      M.refresh(bufnr, client)
    else
      cancel_timer(bufnr)
      next_generation(bufnr)
      clear(bufnr)
    end
  end
end

function M.toggle()
  M.set_enabled(not is_enabled())
end

function M.attach(bufnr, client)
  if attached[bufnr] then
    return
  end

  attached[bufnr] = client

  local group = require("util").augroup("java_field_usages_" .. bufnr)

  api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      M.refresh(bufnr, client)
    end,
  })

  api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      cancel_timer(bufnr)
      next_generation(bufnr)
      clear(bufnr)
    end,
  })

  api.nvim_create_autocmd({ "BufHidden", "BufWipeout", "LspDetach" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      attached[bufnr] = nil
      cancel_timer(bufnr)
      next_generation(bufnr)
      clear(bufnr)
    end,
  })

  vim.schedule(function()
    M.refresh(bufnr, client)
  end)
end

function M.setup()
  vim.g.java_field_usages_enabled = vim.g.java_field_usages_enabled ~= false

  api.nvim_create_user_command("JavaFieldUsagesRefresh", function()
    M.refresh(0)
  end, { desc = "Refresh Java field usage counters for the current buffer", force = true })

  api.nvim_create_user_command("JavaFieldUsagesToggle", function()
    M.toggle()
  end, { desc = "Toggle Java field usage counters", force = true })
end

return M
