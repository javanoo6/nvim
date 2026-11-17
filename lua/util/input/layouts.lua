local M = {}

---@class InputLayout
---@field keys string[] Noncanonical characters, including shifted characters.
---@field normalize fun(char: string): string Canonical US key, or unchanged input.

---@type InputLayout
M.english = {
  keys = {},
  normalize = function(char)
    return char
  end,
}

local russian = "ё й ц у к е н г ш щ з х ъ ф ы в а п р о л д ж э я ч с м и т ь б ю"
local english = "` q w e r t y u i o p [ ] a s d f g h j k l ; ' z x c v b n m , ."
local shifted_punctuation = { ["`"] = "~", ["["] = "{", ["]"] = "}", [";"] = ":", ["'"] = '"', [","] = "<", ["."] = ">" }
local translations, keys = {}, {}
local targets = vim.split(english, " ", { plain = true })
for index, char in ipairs(vim.split(russian, " ", { plain = true })) do
  local target = targets[index]
  local shifted_char = vim.fn.toupper(char)
  translations[char] = target
  translations[shifted_char] = shifted_punctuation[target] or vim.fn.toupper(target)
  keys[#keys + 1], keys[#keys + 2] = char, shifted_char
end

---@type InputLayout
M.russian = {
  keys = keys,
  normalize = function(char)
    return translations[char] or char
  end,
}

return M
