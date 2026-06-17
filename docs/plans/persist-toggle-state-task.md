# Task: Persist Neovim Toggle State

## Goal

- [ ] Move durable runtime toggles into one local persisted state file.
- [ ] Keep every persisted toggle default declared in one place.
- [ ] If the local state file is missing, use defaults.
- [ ] If an individual value is missing from the local state file, use that toggle's default.

## Scope

- [ ] Persist user preference toggles that should survive a Neovim restart.
- [ ] Do not persist transient open/close UI state by default, unless explicitly promoted to a preference.
- [ ] Keep existing keymaps and user commands working.
- [ ] Keep buffer-local emergency/debug toggles buffer-local unless a real default preference exists.

## Proposed Files

- [ ] Add `lua/util/toggle_state.lua`.
- [ ] Store persisted values at:

  ```lua
  vim.fn.stdpath("state") .. "/toggles.json"
  ```

- [ ] Document behavior in `docs/core/session-context.md`.
- [ ] Update `docs/core/plugin-map.md` if keymaps or commands change.

## Default Source Of Truth

- [ ] Declare all persisted defaults in exactly one table inside `lua/util/toggle_state.lua`.

  ```lua
  local defaults = {
    spell = false,
    wrap = false,
    relativenumber = true,
    number = true,
    foldenable = false,
    mouse = false,
    inline_diagnostics = true,
    diagnostics = true,
    neotree_reveal_on_open = true,
    inlay_hints = true,
    reference_underline = true,
    java_field_usages = false,
    reference_background = false,
    autoformat = true,
    autosave = true,
    dapui_keep_open_on_exit = false,
  }
  ```

- [ ] Do not duplicate these defaults in `options.lua`, plugin specs, or utility modules after migration.
- [ ] Modules may read from `toggle_state`, but must not silently reassign their own independent startup defaults.

## Toggle State API

- [ ] Implement:

  ```lua
  toggle_state.get(name)
  toggle_state.set(name, value)
  toggle_state.toggle(name)
  toggle_state.reset(name)
  toggle_state.reset_all()
  toggle_state.defaults()
  toggle_state.values()
  ```

- [ ] `get(name)` returns persisted value when present, otherwise default.
- [ ] `set(name, value)` writes the local file immediately.
- [ ] `toggle(name)` flips the effective value and writes immediately.
- [ ] `reset(name)` removes the key from the local file so it falls back to default.
- [ ] `reset_all()` removes all persisted overrides.
- [ ] Unknown keys in the state file are ignored.
- [ ] Invalid JSON falls back to defaults and shows one warning.
- [ ] File write failures show a warning and keep the in-memory state.

## Startup Behavior

- [ ] Load `toggle_state` early enough that config defaults can consume it.
- [ ] Apply global/window options from `toggle_state` during startup:
    - [ ] `spell`
    - [ ] `wrap`
    - [ ] `relativenumber`
    - [ ] `number`
    - [ ] `foldenable`
    - [ ] `mouse`
    - [ ] `diagnostics`
    - [ ] `reference_underline`
    - [ ] `reference_background`
- [ ] Apply plugin-backed toggles after plugin setup or on `LspAttach` where required:
    - [ ] `inline_diagnostics`
    - [ ] `inlay_hints`
    - [ ] `java_field_usages`
    - [ ] `neotree_reveal_on_open`
    - [ ] `autoformat`
    - [ ] `autosave`
    - [ ] `dapui_keep_open_on_exit`

## Current Togglables To Inventory

### Persist By Default

- [ ] `<leader>us` / `util.toggle("spell")`
    - Current default: `false` globally.
    - Note: markdown/text autocmds may still set local `spell=true`; decide whether persisted state overrides filetype autocmds.

- [ ] `<leader>uw` / `util.toggle("wrap")`
    - Current default: `false` globally.
    - Note: markdown/text autocmds may still set local `wrap=true`; decide whether persisted state overrides filetype autocmds.

- [ ] `<leader>ul` / `util.toggle("relativenumber")`
    - Current default: `true`.

- [ ] `<leader>un` / `util.toggle("number")`
    - Current default: `true`.

- [ ] `<leader>uf` / `util.toggle("foldenable")`
    - Current default: `false`.

- [ ] `<leader>um` / `util.toggle_mouse()`
    - Current default: `mouse=""`, represented as `mouse=false`.
    - Persisted `true` should apply `mouse="a"`.

- [ ] `<leader>ud` / `tiny-inline-diagnostic.toggle()`
    - Current default: enabled on LSP attach.
    - Need wrapper because plugin state is internal.

- [ ] `<leader>uD` / `vim.diagnostic.enable(...)`
    - Current default: diagnostics enabled.
    - Need apply at startup and after any code that calls `vim.diagnostic.enable(true)`.

- [ ] `<leader>ue` / `util.toggle_neotree_reveal_on_open()`
    - Current default: `vim.g.neotree_reveal_on_open=true`.

- [ ] `<leader>uh` / `inlay_hints.toggle()`
    - Current default: `vim.g.inlay_hints_enabled=true`.

- [ ] `<leader>uJ` / `java_field_usages.toggle()`
- Current default: `vim.g.java_field_usages_enabled=true`.

- [ ] `<leader>uu` / `util.toggle_reference_underline()`
    - Current default: `true`.

- [ ] `<leader>uH` / `util.toggle_reference_background()`
    - Current default: `false`.

- [ ] `:FormatDisable` / `:FormatEnable`
    - Current default: autoformat enabled via `vim.g.disable_autoformat=false`.
    - Persist as positive `autoformat=true`, not negative `disable_autoformat`.
    - Keep `:FormatDisable!` buffer-local behavior separate and non-persisted unless explicitly added later.

- [ ] `<leader>ua` / `:ASToggle`
    - Current default: auto-save enabled.
    - Need wrapper or plugin API integration so toggles persist.

- [ ] `<leader>dU` / DAP UI keep-open-on-exit
    - Current default: `vim.g.dapui_keep_open_on_exit=false`.

### Buffer-Local Or Context-Local Preferences

- [ ] `<leader>uT` / `:UiToggleTreesitter`
    - Current behavior: toggles `vim.b[bufnr].treesitter_disabled`.
    - Default: Treesitter enabled where parser exists.
    - Decision needed: keep buffer-local only, or persist per filetype/path.

- [ ] `<leader>uI` / `:UiToggleIlluminate`
    - Current behavior: toggles `vim.b[bufnr].illuminate_disabled`.
    - Default: reference highlighting enabled by plugin behavior.
    - Decision needed: keep buffer-local only, or persist per filetype/path.

- [ ] `:FormatDisable!`
    - Current behavior: disables format-on-save for current buffer only.
    - Keep non-persisted unless adding per-path state.

### Likely Transient, Do Not Persist By Default

- [ ] `<A-a>` / `:ToggleTerm`
    - Opens/closes terminal UI.

- [ ] `<A-c>` / custom terminal hide behavior.
    - Hides terminal UI.

- [ ] Trouble toggles:
    - [ ] `<leader>xx` diagnostics root
    - [ ] `<leader>xc` diagnostics cwd
    - [ ] `<leader>xb` diagnostics buffer
    - [ ] `<leader>cs` symbols
    - [ ] `<leader>cl` call hierarchy
    - [ ] `<leader>cu` usages/references
    - [ ] `<leader>XL` location list
    - [ ] `<leader>XQ` quickfix list

- [ ] `<leader>Xq` / `quicker.toggle()`
    - Opens/closes editable quickfix UI.

- [ ] `<leader>du` / `dapui.toggle()`
    - Opens/closes DAP UI.

- [ ] DAP runtime toggles:
    - [ ] `<leader>db` toggle breakpoint
    - [ ] `<leader>dr` toggle REPL

- [ ] Java runner UI:
    - [ ] `<leader>jl` toggle runner logs

- [ ] Neotest UI/runtime toggles:
    - [ ] summary toggle
    - [ ] output panel toggle
    - [ ] watch toggle

- [ ] Gitsigns visual toggles:
    - [ ] `<leader>GhB` current line blame
    - [ ] `<leader>Ghw` word diff
    - [ ] `<leader>Ghl` line highlight
    - [ ] `<leader>Ghv` deleted lines

- [ ] Bufferline:
    - [ ] `<leader>bp` pin toggle
    - Note: pin state may already be managed by bufferline/session behavior; do not migrate without checking.

- [ ] Neo-tree/Oil local UI toggles:
    - [ ] Neo-tree directory expand/collapse
    - [ ] Oil `g.` hidden files

- [ ] Telescope/Flash/search toggles:
    - [ ] command-line `<C-s>` / `flash.toggle()`
    - [ ] Telescope preview toggles

- [ ] Harpoon quick menu toggle.
- [ ] Undotree window toggle.
- [ ] Obsidian checkbox toggle.
- [ ] Color scheme picker `<leader>ut`.

## Migration Steps

- [ ] Add `toggle_state.lua` with defaults, JSON load/save, and public API.
- [ ] Add `:ToggleStateInfo`.
- [ ] Add `:ToggleStateReset`.
- [ ] Add optional `:ToggleStateReset!` to reset all values.
- [ ] Replace `util.toggle(option)` implementation so persisted options go through `toggle_state`.
- [ ] Replace `util.toggle_mouse()` with persisted `mouse`.
- [ ] Replace `java_field_usages` global initialization with `toggle_state`.
- [ ] Replace reference style state initialization with `toggle_state`.
- [ ] Replace Neo-tree reveal-on-open initialization with `toggle_state`.
- [ ] Replace `inlay_hints` global initialization with `toggle_state`.
- [ ] Wrap inline diagnostics toggle so state persists.
- [ ] Wrap diagnostics toggle so state persists.
- [ ] Replace `formatting.lua` startup assignment of `vim.g.disable_autoformat=false` with `toggle_state.get("autoformat")`.
- [ ] Wrap `:FormatDisable` and `:FormatEnable` so global changes persist.
- [ ] Integrate auto-save startup and `<leader>ua` toggle with `toggle_state`.
- [ ] Replace DAP keep-open initialization and toggle with `toggle_state`.
- [ ] Decide and document whether buffer-local toggles stay non-persisted.
- [ ] Decide and document whether transient UI open/close toggles stay non-persisted.

## Acceptance Criteria

- [ ] Starting Neovim without `toggles.json` uses defaults.
- [ ] Toggling `<leader>uJ` persists Java field usage state.
- [ ] Restarting Neovim restores the previous `<leader>uJ` value.
- [ ] Starting Neovim with a partial `toggles.json` uses persisted values where present and defaults for missing keys.
- [ ] Invalid `toggles.json` does not break startup.
- [ ] Toggling `<leader>uh` persists inlay hint state.
- [ ] Restarting Neovim restores the previous `<leader>uh` value.
- [ ] Toggling `<leader>ue` persists Neo-tree reveal-on-open state.
- [ ] Reference underline/background state survives restart.
- [ ] Autoformat global enable/disable survives restart.
- [ ] Auto-save global enable/disable survives restart.
- [ ] `:ToggleStateInfo` shows defaults, persisted overrides, and effective values.
- [ ] `:ToggleStateReset {name}` removes only that override.
- [ ] `:ToggleStateReset!` removes all overrides.
- [ ] All persisted defaults are declared in one table.
- [ ] Existing keymaps still work.
- [ ] `make check` passes.
