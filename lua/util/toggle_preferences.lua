-- Config-specific adapters; persist-toggle.nvim owns defaults, state, and commands.
local M = {}

local window_defaults = {
  spell = false,
  wrap = false,
  relativenumber = true,
  number = true,
  foldenable = false,
}

local function global_preference(name, default)
  return {
    default = default,
    get = function()
      return vim.g[name] == true
    end,
    set = function(value)
      vim.g[name] = value
    end,
  }
end

function M.setup(opts)
  local persist = require("persist-toggle")
  local util = require("util")
  local toggles = {
    mouse = {
      default = false,
      get = function()
        return vim.o.mouse ~= ""
      end,
      set = function(value)
        vim.o.mouse = value and "a" or ""
      end,
    },
    diagnostics = {
      default = true,
      get = vim.diagnostic.is_enabled,
      set = vim.diagnostic.enable,
    },
    neotree_reveal_on_open = global_preference("neotree_reveal_on_open", true),
    dapui_keep_open_on_exit = global_preference("dapui_keep_open_on_exit", false),
    inlay_hints = {
      default = true,
      get = function()
        return require("util.inlay_hints").is_enabled()
      end,
      set = function(value)
        require("util.inlay_hints").set_enabled(value, { notify = false })
      end,
    },
    java_field_usages = {
      default = false,
      get = function()
        return vim.g.java_field_usages_enabled == true
      end,
      set = function(value)
        vim.g.java_field_usages_enabled = value
        local module = package.loaded["util.java_field_usages"]
        if module then
          module.set_enabled(value, { notify = false })
        end
      end,
    },
    inline_diagnostics = {
      default = true,
      set = function(value)
        local module = package.loaded["tiny-inline-diagnostic"]
        if module then
          if value then
            module.enable()
          else
            module.disable()
          end
        end
      end,
    },
    autoformat = {
      default = true,
      get = function()
        return vim.g.disable_autoformat ~= true
      end,
      set = function(value)
        vim.g.disable_autoformat = not value
      end,
    },
    autosave = {
      default = true,
      set = function(value)
        local module = package.loaded["auto-save"]
        if module and module.enabled() ~= value then
          if value then
            module.on()
          else
            module.off()
          end
        end
      end,
    },
  }
  for name, default in pairs(window_defaults) do
    toggles[name] = {
      default = default,
      get = function()
        return vim.wo[name]
      end,
      set = function(value)
        vim.opt[name] = value
      end,
    }
  end
  for name, default in pairs({ underline = true, background = false }) do
    toggles["reference_" .. name] = {
      default = default,
      get = function()
        return util.reference_style_state[name]
      end,
      set = function(value)
        util.reference_style_state[name] = value
        util.apply_reference_style()
      end,
    }
  end
  persist.setup(vim.tbl_extend("force", { toggles = toggles }, opts or {}))
  vim.api.nvim_create_autocmd("SessionLoadPost", {
    group = vim.api.nvim_create_augroup("persist_toggle_session", { clear = true }),
    callback = function()
      local saved = persist.persisted()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == "" then
          local text = vim.tbl_contains({ "text", "markdown", "gitcommit" }, vim.bo[buf].filetype)
          for name in pairs(window_defaults) do
            local value = persist.get(name)
            if text and (name == "spell" or name == "wrap") and saved[name] == nil then
              value = true
            end
            vim.wo[win][name] = value
          end
        end
      end
    end,
  })
end

return M
