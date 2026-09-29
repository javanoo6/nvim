# Persistent toggle preferences

Actively use [persist-toggle.nvim](https://github.com/javanoo6/persist-toggle.nvim)
for durable preferences in this config. Register new preferences in
`lua/util/toggle_preferences.lua` and route their keymaps and commands through
`require("persist-toggle").set()` or `.toggle()`. Do not add another JSON store.

The plugin is installed through lazy.nvim and pinned in `lazy-lock.json`.
Defaults and adapters live in `lua/util/toggle_preferences.lua`. State is local
to this machine at `stdpath("state") .. "/persist-toggle/state.json"`; do not
commit this file. Missing values use the registry defaults.

| Preference | Existing control | Default |
| --- | --- | --- |
| spell | `<leader>us` | off |
| wrap | `<leader>uw` | off |
| relativenumber | `<leader>ul` | on |
| number | `<leader>un` | on |
| foldenable | `<leader>uf` | off |
| mouse | `<leader>um` | off |
| inline_diagnostics | `<leader>ud` | on |
| diagnostics | `<leader>uD` | on |
| neotree_reveal_on_open | `<leader>ue` | on |
| inlay_hints | `<leader>uh` | on |
| java_field_usages | `<leader>uJ` | off |
| reference_underline | `<leader>uu` | on |
| reference_background | `<leader>uH` | off |
| autoformat | `:FormatEnable` / `:FormatDisable` | on |
| autosave | `<leader>ua` / `:ASToggle` | on |
| dapui_keep_open_on_exit | `<leader>dU` | off |

Window options update the current window and defaults for future windows.
Saved preferences are reapplied to normal windows after session restoration.
Text, Markdown, and Git commit buffers retain automatic spelling/wrapping
unless you explicitly save an override for that option.

Plugin-backed preferences are reapplied after the relevant plugin initializes.
Inlay hints also follow the saved preference when an LSP attaches. Java field
usage counters default to off, preserving the previously effective behavior.

Use `:PersistToggleInfo` to inspect the registry, `:PersistToggleReset {name}`
to restore one default, or `:PersistToggleResetAll` to reset all preferences.
Try `:PersistToggle diagnostics`, restart Neovim, and verify diagnostics retain
the selected state.

Terminal/explorer/debugger panel visibility, live hunks, buffer-only UI debug
switches, and `:FormatDisable!` remain temporary. Changing plugin internals
directly bypasses persistence; use the registered controls above.

## Validation

Run `make check` and `make test-toggles`. The integration test uses two headless
Neovim processes and a temporary state directory to verify the existing
keymaps, restart restoration, delayed plugin setup, formatting and auto-save
commands, text file overrides, session restoration, and resets. It uses the
plugins already installed for this config.
