local M = {}

local function escape_langmap(char)
  return (char:gsub('([\\;,"|])', "\\%1"))
end

local function raw_keycode(lhs)
  -- getcharstr() returns raw UTF-8, while keycode() escapes K_SPECIAL bytes
  -- for feedkeys/mappings. Russian р contains that byte (0x80).
  return (vim.keycode(lhs):gsub("\128\254X", "\128"))
end

---Compile layout data once, without installing mappings or touching plugins.
---@param layout InputLayout
function M.new(layout)
  local aliases, raw_keys, langmap = {}, {}, {}
  local function alias(lhs, rhs, kind, text)
    aliases[#aliases + 1] = { lhs = lhs, rhs = rhs, kind = kind, text = text }
    raw_keys[raw_keycode(lhs)] = raw_keycode(rhs)
  end
  for _, char in ipairs(layout.keys) do
    local target = layout.normalize(char)
    langmap[#langmap + 1] = char .. escape_langmap(target)
    alias(char, target, "plain", char)
    local shifted_char = vim.fn.toupper(char)
    alias("<S-" .. char .. ">", layout.normalize(shifted_char), "shift", shifted_char)
    for _, modifier in ipairs({ "A-", "C-", "C-A-" }) do
      alias("<" .. modifier .. char .. ">", "<" .. modifier .. target .. ">", "modified")
    end
  end
  return {
    aliases = aliases,
    langmap = table.concat(langmap, ","),
    -- Input and output use getcharstr() encoding, never feedkeys escaping.
    normalize = function(key)
      return raw_keys[key] or layout.normalize(key)
    end,
  }
end

return M
