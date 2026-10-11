-- Run: make check-config; add --profile for optional root timing measurements.
-- Fixtures and project history are disposable; no language servers are launched.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local profile = vim.tbl_contains(arg, "--profile")
vim.opt.runtimepath:prepend(repo)
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/project.nvim")
local util = require("util")
local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture, "p")
local clients = {}
local get_clients = vim.lsp.get_clients
vim.lsp.get_clients = function()
  return clients
end
local assertions = 0
local function equal(actual, expected, label)
  assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  assertions = assertions + 1
end
local function file(path)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile({}, path)
  return path
end
local function buf(path)
  local b = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(b)
  if path then
    vim.api.nvim_buf_set_name(b, path)
  end
  return b
end
local function cd(command, path)
  vim.cmd(command .. " " .. vim.fn.fnameescape(path))
end
local function bench(label)
  if not profile then
    return
  end
  local start = vim.uv.hrtime()
  util.get_root_basename()
  local first = (vim.uv.hrtime() - start) / 1e6
  local times = {}
  local searches, realpaths, lookups = 0, 0, 0
  local find, realpath, lookup = vim.fs.find, vim.uv.fs_realpath, vim.lsp.get_clients
  vim.fs.find = function(...)
    searches = searches + 1
    return find(...)
  end
  vim.uv.fs_realpath = function(...)
    realpaths = realpaths + 1
    return realpath(...)
  end
  vim.lsp.get_clients = function(...)
    lookups = lookups + 1
    return lookup(...)
  end
  for i = 1, 500 do
    start = vim.uv.hrtime()
    util.get_root_basename()
    times[i] = (vim.uv.hrtime() - start) / 1e6
  end
  vim.fs.find, vim.uv.fs_realpath = find, realpath
  vim.lsp.get_clients = lookup
  table.sort(times)
  local sum = 0
  for _, t in ipairs(times) do
    sum = sum + t
  end
  print(
    string.format(
      "%s first=%.3f mean=%.3f median=%.3f p95=%.3f max=%.3f ms; find/realpath/LSP per call=%g/%g/%g",
      label,
      first,
      sum / 500,
      times[250],
      times[475],
      times[500],
      searches / 500,
      realpaths / 500,
      lookups / 500
    )
  )
end
local function run()
  cd("cd", fixture)
  local small = fixture .. "/small"
  file(small .. "/.git")
  local smallfile = file(small .. "/src/example.lua")
  buf(smallfile)
  equal(util.get_root(), small, "small marker")
  bench("small, no LSP")
  local large = fixture .. "/large"
  file(large .. "/.git")
  if profile then
    for i = 1, 2000 do
      file(large .. "/siblings/file" .. i .. ".lua")
    end
  end
  local deep = large
  for i = 1, 18 do
    deep = deep .. "/level" .. i
  end
  local deepfile = file(deep .. "/Example.java")
  buf(deepfile)
  equal(util.get_root(), large, "deep marker")
  bench("2000 siblings, 18 ancestor levels, no LSP")
  clients = {
    { config = { root_dir = large }, workspace_folders = { { name = large, uri = vim.uri_from_fname(large) } } },
    { config = { root_dir = fixture } },
  }
  bench("deep tree, two LSP clients")
  file(large .. "/level1/pom.xml")
  equal(util.get_root(), large .. "/level1", "nested marker rejects broader LSP")
  clients = { { config = { root_dir = deep } } }
  equal(util.get_root(), deep, "narrower attached LSP")
  clients = {}
  equal(util.get_root(), large .. "/level1", "detached LSP")
  for _, command in ipairs({ "cd", "lcd", "tcd" }) do
    cd("cd", fixture)
    cd(command, deep)
    equal(util.get_root(), deep, command .. " explicit scope")
  end
  cd("cd", fixture)
  vim.api.nvim_buf_set_name(0, smallfile .. ".renamed")
  equal(util.get_root(), small, "file renamed into different root")
  buf()
  equal(util.get_root(), fixture, "unnamed cwd fallback")
  bench("unnamed")
  buf("jdt://contents/java.base/java/lang/String.class")
  equal(util.get_root(), fixture, "decompiled URI cwd fallback")
  bench("decompiled URI")
  buf(repo .. "/lua/util/init.lua")
  cd("cd", "/tmp")
  vim.lsp.get_clients = get_clients
  bench("actual nvim config, native client lookup")
  vim.lsp.get_clients = function()
    return clients
  end
  -- Effective installed project.nvim options and manual directory selection.
  local opts = dofile(repo .. "/lua/plugins/projects.lua")[1].opts()
  opts.datapath = fixture .. "/project-data"
  require("project_nvim").setup(opts)
  local config = require("project_nvim.config").options
  equal(config.manual_mode, true, "project manual mode")
  equal(table.concat(config.patterns, ","), ".git,_darcs,.hg,.bzr,.svn,Makefile,package.json", "upstream patterns")
  equal(table.concat(config.detection_methods, ","), "lsp,pattern", "upstream detection order")
  equal(#vim.api.nvim_get_autocmds({ group = "project_nvim", event = "BufEnter" }), 0, "no automatic cwd hook")
  buf(smallfile .. ".project")
  equal(vim.fn.getcwd(), "/tmp", "opening file leaves cwd alone")
  require("project_nvim.project").set_pwd(small, "manual fixture")
  equal(vim.fn.getcwd(), small, "explicit project selection changes cwd")
  equal(util.get_root(), small, "shared root respects explicit selection")
  print("Root policy: " .. assertions .. " checks passed")
end
local ok, err = xpcall(run, debug.traceback)
vim.lsp.get_clients = get_clients
pcall(vim.api.nvim_clear_autocmds, { group = "project_nvim" })
cd("cd", repo)
vim.fn.delete(fixture, "rf")
assert(ok, err)
