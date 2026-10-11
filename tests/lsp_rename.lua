-- Exercise native rename with asynchronous client fixtures, without servers.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo)
local rename = require("util.lsp_rename")
local method = "textDocument/rename"
local global = vim.lsp.handlers[method]
local get_clients, get_client_by_id = vim.lsp.get_clients, vim.lsp.get_client_by_id
local input, notify = vim.ui.input, vim.notify
local passed, refreshed = 0, 0
local clients, pending, inputs = {}, {}, {}
local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture, "p")
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. "\n" .. vim.inspect(actual))
  passed = passed + 1
end
package.loaded["util.inlay_hints"] = {
  refresh_loaded_buffers = function()
    refreshed = refreshed + 1
  end,
}
vim.notify = function() end
vim.ui.input = function(opts, callback)
  inputs[#inputs + 1] = { opts = opts, callback = callback }
end
vim.lsp.get_clients = function(opts)
  opts = opts or {}
  return vim.tbl_filter(function(client)
    return not opts.name or opts.name == client.name
  end, clients)
end
vim.lsp.get_client_by_id = function(id)
  for _, client in ipairs(clients) do
    if client.id == id then
      return client
    end
  end
end
local function buffer(name, ft)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_name(buf, fixture .. "/" .. name)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "old" })
  vim.bo.filetype = ft or "lua"
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  return buf
end
local function client(id, name, handler, prepare)
  local c = { id = id, name = name, offset_encoding = "utf-16", handlers = { [method] = handler } }
  function c:supports_method(m)
    return m == method or (prepare and m == "textDocument/prepareRename")
  end
  function c:request(m, params, callback, buf)
    pending[#pending + 1] = { method = m, params = params, callback = callback, ctx = { client_id = self.id, bufnr = buf, method = m } }
    return true, #pending
  end
  rename.attach(c)
  return c
end
local function response(request, err, result)
  request.callback(err, result, request.ctx)
end
local function edit(buf, name)
  return {
    changes = {
      [vim.uri_from_bufnr(buf)] = {
        { range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 3 } }, newText = name },
      },
    },
  }
end
local function drain()
  vim.wait(20, function()
    return false
  end)
end
local function run()
  local b1 = buffer("first.lua")
  clients = { client(1, "lua_ls") }
  local handler = clients[1].handlers[method]
  rename.attach(clients[1])
  equal(clients[1].handlers[method], handler, "Repeated attach keeps one wrapper")
  rename.rename()
  equal(inputs[1].opts.default, "old", "Native prompt preserved")
  inputs[1].callback("one")
  local first = pending[#pending]
  equal(first.params.newName, "one", "New name passed to server")
  rename.rename()
  inputs[2].callback("two")
  local second = pending[#pending]
  equal(vim.lsp.handlers[method], global, "Global stable while requests overlap")
  response(second, nil, edit(b1, "two"))
  equal(vim.api.nvim_buf_get_lines(b1, 0, -1, false), { "two" }, "Native handler applies edits")
  equal(refreshed, 0, "Refresh follows edit handling asynchronously")
  response(first, nil, edit(b1, "one"))
  drain()
  equal(refreshed, 2, "Both overlapping requests refresh")
  equal(vim.lsp.handlers[method], global, "Global stable after replies")
  local count = #pending
  rename.rename()
  inputs[#inputs].callback(nil)
  equal(#pending, count, "Cancelled prompt sends no request")
  rename.rename()
  inputs[#inputs].callback("")
  equal(#pending, count, "Empty prompt sends no request")
  local called = 0
  local custom = function(err, result, ctx, config)
    called = called + 1
    equal(ctx.bufnr, b1, "Custom handler receives context")
    equal(config, "config", "Custom handler receives config")
    if not err and result then
      vim.lsp.util.apply_workspace_edit(result, "utf-16")
    end
    return "value", nil, 3
  end
  clients = { client(2, "custom", custom) }
  local values = vim.F.pack_len(clients[1].handlers[method](nil, edit(b1, "new"), { bufnr = b1 }, "config"))
  equal(values, { n = 3, "value", [3] = 3 }, "Custom handler return values preserved")
  equal(vim.api.nvim_buf_get_lines(b1, 0, -1, false), { "new" }, "Custom handler applies edits")
  drain()
  local before = refreshed
  clients[1].handlers[method]({ message = "failure" }, nil, { bufnr = b1 }, "config")
  clients[1].handlers[method](nil, nil, { bufnr = b1 }, "config")
  drain()
  equal(refreshed, before, "Errors and nil results do not refresh")
  equal(called, 3, "Custom handler receives all responses")
  clients[1].handlers[method] = function()
    error("handler failure")
  end
  rename.attach(clients[1])
  equal(pcall(clients[1].handlers[method], nil, {}, {}), false, "Handler failure propagates")
  equal(vim.lsp.handlers[method], global, "Handler failure leaves global unchanged")
  -- A later global replacement remains the fallback for clients without custom handlers.
  local delegated = 0
  clients = { client(3, "fallback") }
  local newer = function()
    delegated = delegated + 1
  end
  vim.lsp.handlers[method] = newer
  clients[1].handlers[method](nil, nil, {})
  equal(delegated, 1, "Latest global handler respected")
  equal(vim.lsp.handlers[method], newer, "Later global replacement preserved")
  vim.lsp.handlers[method] = global
  -- Java uses the native prepare/prompt flow, restricted to IntelliJ.
  local b2 = buffer("Example.java", "java")
  clients = { client(4, "other"), client(5, "intellij", nil, true) }
  rename.rename()
  local prepare = pending[#pending]
  equal(prepare.method, "textDocument/prepareRename", "Native prepare-rename retained")
  equal(prepare.ctx.client_id, 5, "Java restricted to IntelliJ")
  response(prepare, nil, { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 3 } })
  equal(inputs[#inputs].opts.default, "old", "Prepared symbol supplies prompt default")
  inputs[#inputs].callback("New")
  local java = pending[#pending]
  equal(java.ctx.client_id, 5, "Java rename uses IntelliJ")
  response(java, nil, edit(b2, "New"))
  equal(vim.api.nvim_buf_get_lines(b2, 0, -1, false), { "New" }, "Java fixture applies rename")
  drain()
  before = refreshed
  rename.rename()
  response(pending[#pending], { message = "cannot rename" }, nil)
  drain()
  equal(refreshed, before, "Failed prepare does not refresh")
  equal(vim.lsp.handlers[method], global, "Global stable through Java flow")
end
local ok, err = xpcall(run, debug.traceback)
vim.lsp.handlers[method] = global
vim.lsp.get_clients, vim.lsp.get_client_by_id = get_clients, get_client_by_id
vim.ui.input, vim.notify = input, notify
vim.fn.delete(fixture, "rf")
assert(ok, err)
print("LSP rename: " .. passed .. " assertions passed")
