-- Run: nvim --headless -u NONE -i NONE -l tests/input_normalizer.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)
local layouts = require("util.input.layouts")
local factory = require("util.input.normalizer")
local checks = 0
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. ": " .. vim.inspect(actual))
  checks = checks + 1
end

local function run()
  local langmap, mappings = vim.o.langmap, vim.api.nvim_get_keymap("n")
  local english, russian = factory.new(layouts.english), factory.new(layouts.russian)
  equal(vim.o.langmap, langmap, "Compiling layouts leaves options unchanged")
  equal(vim.api.nvim_get_keymap("n"), mappings, "Compiling layouts installs no mappings")
  equal(english.aliases, {}, "English identity needs no aliases")
  equal(english.langmap, "", "English identity needs no langmap")

  -- Fixtures use raw getcharstr() modifiers followed by ordinary UTF-8.
  -- In particular, р must not have feedkeys' K_SPECIAL escaping here.
  local ctrl, alt, shift, ctrl_alt = string.char(128, 252, 4), string.char(128, 252, 8), string.char(128, 252, 2), string.char(128, 252, 12)
  for _, case in ipairs({
    { "р", "h" },
    { "Р", "H" },
    { "Д", "L" },
    { "ж", ";" },
    { "Ж", ":" },
    { "Б", "<" },
    { "Ю", ">" },
    { "Ё", "~" },
    { shift .. "р", "H" },
    { shift .. "Р", "H" },
    { ctrl .. "р", vim.keycode("<C-h>") },
    { ctrl .. "о", vim.keycode("<C-j>") },
    { ctrl .. "л", vim.keycode("<C-k>") },
    { ctrl .. "д", vim.keycode("<C-l>") },
    { alt .. "п", vim.keycode("<A-g>") },
    { alt .. "Б", vim.keycode("<A-lt>") },
    { ctrl_alt .. "о", vim.keycode("<C-A-j>") },
    { "H", "H" },
    { " ", " " },
    { "€", "€" },
    { vim.keycode("<F12>"), vim.keycode("<F12>") },
  }) do
    equal(russian.normalize(case[1]), case[2], "Russian canonical key")
    equal(english.normalize(case[1]), case[1], "English identity preserves input")
  end

  -- Adapters can consume any layout implementing the same interface.
  local extra = factory.new({
    keys = { "α", "Α" },
    normalize = function(key)
      return ({ ["α"] = "x", ["Α"] = "X" })[key] or key
    end,
  })
  equal(extra.normalize(shift .. "α"), "X", "New layout shares modifier normalization")
  equal(extra.normalize(ctrl .. "α"), vim.keycode("<C-x>"), "New layout shares Ctrl normalization")
  equal(russian.normalize("α"), "α", "Layout instances remain independent")
  equal(package.loaded["which-key.state"], nil, "Normalization has no plugin dependency")
end

local ok, err = xpcall(run, debug.traceback)
assert(ok, err)
print("Input normalization: " .. checks .. " assertions passed")
