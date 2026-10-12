-- Exercise upstream startup and local reattachment without launching a server.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo)
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/intellij-lsp.nvim")
local plugin = require("intellij-lsp")
local factory = require("intellij-lsp.client")
plugin.setup = function() end
require("util.java_file_templates").setup = function() end
require("util.java_intellij").setup({ accept_eula = true })
require("util.java_workspace").setup()

local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture .. "/src", "p")
vim.fn.writefile({ "<project/>" }, fixture .. "/pom.xml")
local cwd = vim.fn.getcwd()
vim.api.nvim_set_current_dir(fixture)
local starts, attaches = 0, 0
vim.lsp.start = function()
  starts = starts + 1
end
vim.lsp.buf_attach_client = function()
  attaches = attaches + 1
end
local passed = 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. ": " .. vim.inspect(actual))
  passed = passed + 1
end
local function buffer(name, buftype)
  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(buf, name)
  vim.bo[buf].buftype = buftype
  vim.bo[buf].filetype = "java"
  return buf
end
local function run()
  for _, case in ipairs({
    { "diffview://" .. fixture .. "/.git/HEAD/src/Main.java", "nofile" },
    { "diffview://" .. fixture .. "/.git/:0:/src/Main.java", "" },
    { "fugitive://" .. fixture .. "/.git/0/src/Main.java", "" },
    { "jrt:/java.base/java/lang/String.java", "nofile" },
    { fixture .. "/src/Scratch.java", "nofile" },
  }) do
    local buf = buffer(case[1], case[2])
    equal(factory.find_root(buf), nil, "Virtual/non-file buffer has no project root")
    plugin._start_for_buffer(buf)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_exec_autocmds("BufEnter", { buffer = buf, group = "IntellijWorkspaceAttach" })
    equal({ starts, attaches }, { 0, 0 }, "Virtual buffer neither starts nor attaches IntelliJ")
    -- Even a client lookup returning a workspace must not attach snapshots.
    local lookup = factory.find_ancestor_client
    factory.find_ancestor_client = function()
      return { id = 123 }
    end
    vim.api.nvim_exec_autocmds("BufEnter", { buffer = buf, group = "IntellijWorkspaceAttach" })
    equal(attaches, 0, "Local guard precedes workspace lookup")
    factory.find_ancestor_client = lookup
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  local real = buffer(fixture .. "/src/Main.java", "")
  equal(factory.find_root(real), fixture, "Real Java file retains absolute Maven root")
  local config = factory.config
  factory.config = function(root)
    equal(root, fixture, "Real file startup receives project root")
    return {}
  end
  plugin._start_for_buffer(real)
  equal(starts, 1, "Real Java file starts IntelliJ normally")
  factory.config = config
  vim.api.nvim_buf_delete(real, { force = true })

  local library = buffer("jrt:/java.base/java/lang/Object.java", "nofile")
  vim.b[library].intellij_lsp_library_client = 456
  vim.lsp.get_client_by_id = function(id)
    return id == 456 and { id = id } or nil
  end
  plugin._start_for_buffer(library)
  equal(attaches, 1, "Upstream still attaches decompiled buffers to their owner")
  vim.api.nvim_buf_delete(library, { force = true })
end
local ok, err = xpcall(run, debug.traceback)
vim.api.nvim_set_current_dir(cwd)
vim.fn.delete(fixture, "rf")
if not ok then
  error(err)
end
print("Java virtual-buffer checks passed: " .. passed)
