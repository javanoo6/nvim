local M = {}

local russian = "ё й ц у к е н г ш щ з х ъ ф ы в а п р о л д ж э я ч с м и т ь б ю"
local english = "` q w e r t y u i o p [ ] a s d f g h j k l ; ' z x c v b n m , ."
local translations = {}
local modified_translations = {}
local langmap_pairs = {}
local targets = vim.split(english, " ", { plain = true })

local function escape(char)
  return (char:gsub('([\\;,"|])', "\\%1"))
end

for index, char in ipairs(vim.split(russian, " ", { plain = true })) do
  local target = targets[index]
  translations[char] = target
  langmap_pairs[#langmap_pairs + 1] = char .. escape(target)
  -- Shifted punctuation occupies the same physical keys on the US layout.
  local shifted = ({ ["`"] = "~", ["["] = "{", ["]"] = "}", [";"] = ":", ["'"] = '"', [","] = "<", ["."] = ">" })[target]
    or vim.fn.toupper(target)
  translations[vim.fn.toupper(char)] = shifted
  langmap_pairs[#langmap_pairs + 1] = vim.fn.toupper(char) .. escape(shifted)
end

function M.setup()
  vim.opt.langmap = table.concat(langmap_pairs, ",")
  vim.opt.langremap = false

  -- langmap does not translate modified keys or terminal/insert input. Forward
  -- them recursively so lazy loaders and buffer-local English mappings still
  -- own the action, including mappings installed after this early setup.
  for char, target in pairs(translations) do
    for _, modifier in ipairs({ "A-", "C-", "C-A-" }) do
      local lhs = "<" .. modifier .. char .. ">"
      local rhs = "<" .. modifier .. target .. ">"
      modified_translations[vim.keycode(lhs)] = vim.keycode(rhs)
      vim.keymap.set({ "n", "x", "s", "o", "i", "c", "t" }, lhs, rhs, {
        remap = true,
        silent = true,
        desc = "which_key_ignore",
      })
    end
  end
end

function M.setup_which_key()
  -- getcharstr() bypasses langmap while which-key owns the input loop.
  local state = require("which-key.state")
  if state._russian_layout then
    return
  end
  local getchar = state.getchar
  state.getchar = function()
    local ok, char = getchar()
    return ok, ok and (translations[char] or modified_translations[char] or char) or char
  end
  state._russian_layout = true
end

return M
