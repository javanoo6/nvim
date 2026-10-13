# Persistent Neovim preferences

`persist-toggle.nvim` is the durable preference registry. Defaults and setters
are declared in `lua/util/preferences.lua`; values survive restarts in
`stdpath("state") .. "/persist-toggle/state.json"`.

| ID                       | Default | Existing control                                       |
|--------------------------|---------|--------------------------------------------------------|
| `spell`                  | false   | `<leader>us`                                           |
| `wrap`                   | false   | `<leader>uw`                                           |
| `relativenumber`         | true    | `<leader>ul`                                           |
| `number`                 | true    | `<leader>un`                                           |
| `foldenable`             | false   | `<leader>uf`                                           |
| `mouse`                  | false   | `<leader>um`                                           |
| `diagnostics`            | true    | `<leader>uD`                                           |
| `inline_diagnostics`     | true    | `<leader>ud`, `:TinyInlineDiag enable/disable/toggle`  |
| `inlay_hints`            | true    | `<leader>uh`                                           |
| `reference_underline`    | true    | `<leader>uu`                                           |
| `reference_background`   | false   | `<leader>uH`                                           |
| `neotree_reveal_on_open` | true    | `<leader>ue`                                           |
| `autoformat`             | true    | `:FormatEnable`, `:FormatDisable`                      |
| `autosave`               | true    | `<leader>ua`, `:ASToggle`                              |
| `session_autosave`       | true    | `<leader>Sa` enables; registry commands toggle/disable |
| `session_autorestore`    | true    | Registry commands                                      |
| `test_summary_on_run`    | true    | Registry commands                                      |
| `debug_panel_keep_open`  | false   | `<leader>dU`                                           |
| `git_blame`              | false   | `<leader>GhB`, `:Gitsigns toggle_current_line_blame`   |
| `git_word_diff`          | false   | `<leader>Ghw`, `:Gitsigns toggle_word_diff`            |
| `git_linehl`             | false   | `<leader>Ghl`, `:Gitsigns toggle_linehl`               |
| `git_deleted`            | false   | `<leader>Ghv`, `:Gitsigns toggle_deleted`              |
| `oil_hidden`             | false   | Oil `g.`                                               |
| `flash_search`           | false   | Command-line `<C-s>`                                   |

Use `:PersistToggleInfo` to inspect saved and current values. For example:

```vim
PersistToggleSet session_autorestore false
PersistToggleSet test_summary_on_run false
PersistToggleReset inline_diagnostics
PersistToggleResetAll
```

Changing editing options updates normal file windows and future window defaults.
Special plugin windows retain their own settings. Markdown, text, and gitcommit
keep their wrap/spell defaults until you save an override; resetting it restores
filetype defaults. Session restore reapplies preferences after saved local options.

Plugin setters defer work until their plugin loads; setup then consumes or applies
the saved value. An explicit registry change does not force an unrelated plugin
to load. Native auto-save, inline-diagnostic, and Gitsigns display commands use
the registry too. Auto-session's native enable/disable and automatic safety
suspensions remain operational session state: use `<leader>Sa` or registry
commands to change the durable session preference.

Debug runs close the test summary and never auto-open it. Regular test runs,
failed-test runs, and sequential runs honor `test_summary_on_run`. You can still
open the summary manually with `<leader>ts`. DAP initialization closes an existing
summary for debug launches outside those test mappings too.

Temporary UI open/close actions, breakpoints, watch targets, buffer-local
Treesitter/Illuminate disables, and `:FormatDisable!` stay local to their current
context. Themery and bufferline retain their existing persistence. Oil retains
its protection against changing hidden-file visibility with unsaved edits.
