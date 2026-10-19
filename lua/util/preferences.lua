-- Durable user preferences. Plugin setters never trigger lazy loading.
local M = {}

local defaults = {
  spell = false,
  wrap = false,
  relativenumber = true,
  number = true,
  foldenable = false,
  mouse = false,
  diagnostics = true,
  inline_diagnostics = true,
  inlay_hints = true,
  reference_underline = true,
  reference_background = false,
  neotree_reveal_on_open = true,
  autoformat = true,
  autosave = true,
  session_autosave = true,
  session_autorestore = true,
  test_summary_on_run = true,
  debug_panel_keep_open = false,
  git_blame = false,
  git_word_diff = false,
  git_linehl = false,
  git_deleted = false,
  oil_hidden = false,
  flash_search = false,
}
local ready = false
local git_actions = {}
local inline_actions = {}
local window_options = { "spell", "wrap", "relativenumber", "number", "foldenable" }
local prose = { markdown = true, text = true, gitcommit = true }

function M.get(id)
  assert(defaults[id] ~= nil, "Unknown preference: " .. id)
  if ready then
    return require("persist-toggle").get(id)
  end
  return defaults[id]
end

function M.toggle(id)
  return require("persist-toggle").toggle(id)
end

function M.set(id, value)
  return require("persist-toggle").set(id, value)
end

-- Prose keeps its filetype defaults until the user explicitly saves an override.
function M.option_value(id, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local saved = ready and require("persist-toggle").persisted() or {}
  if (id == "spell" or id == "wrap") and saved[id] == nil and prose[vim.bo[bufnr].filetype] then
    return true
  end
  return M.get(id)
end

local function apply_window_option(id)
  vim.api.nvim_set_option_value(id, M.get(id), { scope = "global" })
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "" then
      vim.api.nvim_set_option_value(id, M.option_value(id, buf), { win = win, scope = "local" })
    end
  end
end

function M.apply(id)
  if ready then
    require("persist-toggle").apply(id)
  end
end

function M.bind_inline_diagnostics(tid)
  inline_actions.enable = inline_actions.enable or tid.enable
  inline_actions.disable = inline_actions.disable or tid.disable
  tid.enable = function()
    return M.set("inline_diagnostics", true)
  end
  tid.disable = function()
    return M.set("inline_diagnostics", false)
  end
  tid.toggle = function()
    return M.toggle("inline_diagnostics")
  end
  local actions = { "enable", "disable", "toggle", "toggle_cursor_only", "toggle_all_diags_on_cursorline", "reset" }
  vim.api.nvim_create_user_command("TinyInlineDiag", function(args)
    if vim.tbl_contains(actions, args.args) then
      tid[args.args]()
    else
      vim.notify("Invalid action: " .. args.args, vim.log.levels.ERROR)
    end
  end, {
    nargs = 1,
    complete = function()
      return actions
    end,
    force = true,
  })
end

function M.bind_gitsigns(gs)
  local methods = {
    git_blame = "toggle_current_line_blame",
    git_word_diff = "toggle_word_diff",
    git_linehl = "toggle_linehl",
    git_deleted = "toggle_deleted",
  }
  for id, method in pairs(methods) do
    local preference = id
    git_actions[method] = git_actions[method] or gs[method]
    gs[method] = function(value)
      if value == nil then
        return M.toggle(preference)
      end
      return M.set(preference, value)
    end
    require("gitsigns.actions")[method] = gs[method]
  end

  -- Gitsigns CLI captures original functions in a separate command table.
  local actions = require("gitsigns.actions")
  local original = actions._get_cmd_func
  local owned = {}
  for _, method in pairs(methods) do
    owned[method] = true
  end
  actions._get_cmd_func = function(name)
    if owned[name] then
      return function(args)
        gs[name](args[1])
      end
    end
    return original(name)
  end
end

function M.setup(opts)
  local specs = {}
  local function register(id, setter, getter)
    specs[id] = { default = defaults[id], set = setter, get = getter }
  end
  for _, name in ipairs(window_options) do
    local id = name
    register(id, function()
      apply_window_option(id)
    end, function()
      return vim.wo[id]
    end)
  end
  register("mouse", function(value)
    vim.o.mouse = value and "a" or ""
  end, function()
    return vim.o.mouse ~= ""
  end)
  register("diagnostics", vim.diagnostic.enable, vim.diagnostic.is_enabled)
  register("inline_diagnostics", function(value)
    local tid = package.loaded["tiny-inline-diagnostic"]
    if tid then
      if value then
        (inline_actions.enable or tid.enable)()
      else
        (inline_actions.disable or tid.disable)()
      end
    end
  end)
  register("inlay_hints", function(value)
    require("util.inlay_hints").set_enabled(value, { notify = false })
  end)
  for _, name in ipairs({ "underline", "background" }) do
    local attr = name
    register("reference_" .. attr, function(value)
      local util = require("util")
      util.reference_style_state[attr] = value
      util.apply_reference_style()
    end)
  end
  register("neotree_reveal_on_open", function(value)
    vim.g.neotree_reveal_on_open = value
  end)
  register("autoformat", function(value)
    vim.g.disable_autoformat = not value
  end)
  register("autosave", function(value)
    local autosave = package.loaded["auto-save"]
    if autosave and autosave.enabled() ~= value then
      if value then
        autosave.on()
      else
        autosave.off()
      end
    end
  end)
  register("test_summary_on_run")
  for id, key in pairs({ session_autosave = "auto_save", session_autorestore = "auto_restore" }) do
    local field = key
    register(id, function(value)
      if package.loaded["auto-session"] then
        require("auto-session.config")[field] = value
      end
    end)
  end
  register("debug_panel_keep_open", function(value)
    vim.g.debug_panel_keep_open = value
  end)
  for id, action in pairs({
    git_blame = "toggle_current_line_blame",
    git_word_diff = "toggle_word_diff",
    git_linehl = "toggle_linehl",
    git_deleted = "toggle_deleted",
  }) do
    local method = action
    register(id, function(value)
      local gs = package.loaded.gitsigns
      if gs then
        (git_actions[method] or gs[method])(value)
      end
    end)
  end
  register("oil_hidden", function(value)
    if package.loaded.oil then
      local config = require("oil.config")
      if config.view_options.show_hidden ~= value then
        require("oil").toggle_hidden()
      end
    end
  end, function()
    if package.loaded.oil then
      return require("oil.config").view_options.show_hidden
    end
    return M.get("oil_hidden")
  end)
  register("flash_search", function(value)
    if package.loaded.flash then
      require("flash").toggle(value)
    end
  end)

  ready = true
  require("persist-toggle").setup(vim.tbl_extend("force", opts or {}, { toggles = specs, apply_on_setup = false }))
  require("persist-toggle").apply_all()
  vim.api.nvim_create_autocmd("SessionLoadPost", {
    group = vim.api.nvim_create_augroup("persist_preferences", { clear = true }),
    callback = function()
      for _, id in ipairs(window_options) do
        apply_window_option(id)
      end
    end,
  })
end

return M
