-- Run: nvim --headless -u NONE -i NONE -l tests/yank_history.lua
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(repo)
for _, name in ipairs({ "plenary.nvim", "telescope.nvim", "yanky.nvim" }) do
  vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/" .. name)
end
vim.o.lines = 45
vim.o.columns = 140
require("telescope").setup({ defaults = { initial_mode = "normal" } })
local opts
for _, spec in ipairs(require("plugins.coding")) do
  if spec[1] == "gbprod/yanky.nvim" then
    opts = vim.deepcopy(spec.opts)
  end
end
opts.system_clipboard = { sync_with_ring = false }
local history = require("yanky.history")
local state = require("telescope.actions.state")
local actions = require("telescope.actions")
local checks = 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. "\n" .. vim.inspect(actual))
  checks = checks + 1
end
local function contents()
  return vim.tbl_map(function(entry)
    return entry.regcontents
  end, history.all())
end
local completed, settled = 0, 0
local function settle(picker)
  assert(
    vim.wait(1000, function()
      return completed > settled and picker.manager ~= nil
    end),
    "Picker did not settle"
  )
  settled = completed
end
local function run()
  for _, storage in ipairs({ "memory", "shada" }) do
    opts.ring.storage = storage
    require("yanky.config").setup(opts)
    history.setup()
    history.clear()
    for _, text in ipairs({ "keep tail", "target two", "keep middle", "target one", "keep head" }) do
      history.push({ regcontents = text, regtype = "v" })
    end
    require("yanky.telescope.yank_history").yank_history({
      _completion_callbacks = {
        function()
          completed = completed + 1
        end,
      },
    })
    local prompt = vim.api.nvim_get_current_buf()
    local picker = state.get_current_picker(prompt)
    settle(picker)
    local function select_entry(text)
      for index = 1, picker.manager:num_results() do
        if picker.manager:get_entry(index).value.regcontents == text then
          picker:set_selection(picker:get_row(index))
          return
        end
      end
      error("Missing result: " .. text)
    end
    local mappings = opts.picker.telescope.mappings
    -- Filtered deletion must also repair indexes of hidden entries.
    picker:set_prompt("target")
    settle(picker)
    select_entry("target one")
    mappings.i["<c-x>"](prompt)
    settle(picker)
    equal(contents(), { "keep head", "keep middle", "target two", "keep tail" }, storage .. " first deletion")
    select_entry("target two")
    mappings.i["<c-ч>"](prompt)
    settle(picker)
    equal(contents(), { "keep head", "keep middle", "keep tail" }, storage .. " repeated deletion")
    picker:set_prompt("")
    settle(picker)
    -- Select nonadjacent entries; Telescope deletes in reverse result order.
    select_entry("keep head")
    picker:add_selection(picker:get_selection_row())
    select_entry("keep tail")
    picker:add_selection(picker:get_selection_row())
    mappings.n.d(prompt)
    settle(picker)
    equal(contents(), { "keep middle" }, storage .. " multiple deletion")
    select_entry("keep middle")
    mappings.n["в"](prompt)
    settle(picker)
    equal(contents(), {}, storage .. " final deletion")
    equal(#picker.finder.results, 0, storage .. " empty picker")
    actions.close(prompt)
  end
end
local ok, err = pcall(run)
if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
end
print("PASS: " .. checks .. " yank history checks")
vim.cmd("qa!")
