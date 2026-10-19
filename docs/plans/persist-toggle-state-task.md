# Persist Neovim Toggle State

Status: implemented with `javanoo6/persist-toggle.nvim`. The original proposal for
`lua/util/toggle_state.lua` and `ToggleState*` commands is superseded.

The registry integration and all 24 defaults live in `lua/util/preferences.lua`.
The installed plugin supplies JSON persistence, reset commands, and reporting.
Use `PersistToggle*` commands; see [the preference inventory](../core/preferences.md)
and [session context](../core/session-context.md#persistent-preferences).

Plugin setup respects saved preferences. Editing options, diagnostics, hints,
reference style, Neo-tree reveal, formatting, auto-save, session preferences,
Gitsigns display modes, Oil hidden files, Flash search, debug keep-open, and
regular-run summary opening are integrated. Transient UI and buffer-local controls
retain their scope. Debug runs close the summary without automatically opening it.

Validation: `tests/persist_preferences.lua` uses two isolated Neovim processes
and disposable state to check restore, real plugin setup/commands, prose/session
behavior, and resets. `tests/neotest_scope.lua` checks all five debug mappings and
DAP summary closure. Both are included in `make check`.
