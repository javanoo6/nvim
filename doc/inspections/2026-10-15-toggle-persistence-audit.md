# Neovim toggle and persistence inspection

Date: 2026-10-15. Baseline: `2f8f458`, including the current uncommitted
`<leader>Sa` toggle change.

## Scope and result

Reviewed runtime controls across `lua/config`, `lua/plugins`, `lua/util`,
`after/ftplugin`, the preference registry, session integration, and usage docs.
Followed relevant paths into the installed plugins and Neovim runtime. This is
an inspection of toggle behavior, persistence, scope, and discoverability, rather
than a general correctness review of every language integration.

Most durable controls already use `persist-toggle`: all 24 registered preferences
have an application path. The session auto-save key now toggles its registered
preference. The remaining problems are mostly disagreements between persisted
intent, live plugin state, and temporary local overrides.

Six issues were reproduced in isolated Neovim processes. Five additional areas
would benefit from a consistency decision; they are listed separately from bugs.
This inspection changes no runtime configuration.

## Confirmed issues

P2 means a functional inconsistency worth fixing. P3 means a smaller behavior or
clarity issue. All six findings below were reproduced, rather than inferred only
from option names.

| ID | Priority | Issue                                                 | User-visible consequence                                                              |
|----|----------|-------------------------------------------------------|---------------------------------------------------------------------------------------|
| F1 | P2       | Concurrent instances overwrite unrelated preferences  | A later toggle can erase another Neovim instance's saved changes                      |
| F2 | P2       | Diagnostics toggle reads aggregate suppression state  | A toggle intended to disable diagnostics can enable them and remove local suppression |
| F3 | P2       | Oil persists a rejected visibility change             | Saved and displayed hidden-file settings disagree                                     |
| F4 | P3       | Session auto-save toggle ignores temporary suspension | First press after suspension can leave auto-save off                                  |
| F5 | P3       | Window-option toggles read special-window state       | A global toggle can appear ineffective from a plugin window                           |
| F6 | P2       | Treesitter attachment ignores its local disable flag  | A FileType event re-enables highlighting while the flag still says disabled           |

### F1. Multiple Neovim instances can lose saved changes

Sources:
[persist-toggle load/save](/home/konkov/.local/share/nvim/lazy/persist-toggle.nvim/lua/persist-toggle/init.lua:122),
[set](/home/konkov/.local/share/nvim/lazy/persist-toggle.nvim/lua/persist-toggle/init.lua:168),
[registry setup](/home/konkov/.config/nvim/lua/util/preferences.lua:243).

Each instance loads its own copy of the shared JSON file. Every change writes
that instance's entire cached `values` table, without merging newer disk state.
This affects all registered preferences, not just session auto-save.

Reproduction with two real Neovim processes sharing a disposable state file:

1. A starts and loads an empty registry state.
2. B saves `wrap=true`.
3. A saves `mouse=true` without reloading B's update.

Observed disk contents:

```json
{"version":1,"values":{"wrap":true}}
{"version":1,"values":{"mouse":true}}
```

The second write loses the wrap preference. This does not require simultaneous
writes: one long-running instance with an old cache is enough.

Suggested fix: make individual mutations merge against current disk state, with
locking around read/modify/write and atomic replacement. Preserve explicit reset
and deletion operations; a simple table merge would accidentally resurrect them.
Live synchronization of already-running instances is a separate decision.

### F2. Global diagnostics toggle conflates preference and local suppression

Sources:
[diagnostics registration](/home/konkov/.config/nvim/lua/util/preferences.lua:160),
[conflict suppression](/home/konkov/.config/nvim/lua/plugins/git.lua:15),
[live-hunk suppression](/home/konkov/.config/nvim/lua/util/live_hunks.lua:221).

The registry's getter is `vim.diagnostic.is_enabled()` with no buffer filter.
In the installed Neovim runtime, this returns false when any buffer has a
diagnostic suppression. Conflict buffers and the live-hunk scratch view create
such suppressions intentionally.

Reproduction:

1. Set the durable `diagnostics` preference to true.
2. Disable diagnostics for one scratch buffer.
3. Invoke the same registry toggle used by `<leader>uD`.

Observed: the preference remains true, diagnostics are enabled globally, and the
scratch buffer's suppression is cleared. The first keypress enables everything
instead of switching the user's enabled preference off.

Suggested fix: toggle the durable preference independently of per-buffer
suppression. Preserve or reapply plugin-owned suppressions when globally enabling
diagnostics. Merely changing the getter fixes the first press but does not by
itself preserve suppressions after an off/on cycle.

Checked a related suspicion: resolving a Git conflict after globally disabling
diagnostics did **not** re-enable diagnostics in the current runtime. That is not
reported as a separate bug.

### F3. Oil's registry path saves visibility changes before Oil accepts them

Sources:
[Oil preference setter](/home/konkov/.config/nvim/lua/util/preferences.lua:224),
[Oil keymap](/home/konkov/.config/nvim/lua/plugins/editor.lua:553),
[Oil unsaved-edit guard](/home/konkov/.local/share/nvim/lazy/oil.nvim/lua/oil/view.lua:78).

The `g.` mapping first asks Oil to toggle, then persists the resulting state.
That path respects Oil's refusal to change visibility with unsaved directory
edits. The registry command takes the opposite path: persist-toggle saves first,
then invokes the setter, which calls Oil's guarded toggle.

Reproduction: edit an Oil directory buffer without saving, then run
`:PersistToggleSet oil_hidden true` from an initially hidden-files-off state.

Observed:

```text
Cannot toggle hidden files when you have unsaved changes
persisted/effective oil_hidden = true
Oil show_hidden = false
```

The rejected request becomes durable and will apply on a later restart. There
is no queued retry when the directory edits are saved.

Suggested fix: validate/apply the Oil change before committing its preference,
or provide a registry mutation contract that can reject or roll back a setter.
Keep the existing unsaved-edit guard.

### F4. Session auto-save's temporary suspension is invisible to its toggle

Sources:
[session preference registration](/home/konkov/.config/nvim/lua/util/preferences.lua:199),
[session keymap](/home/konkov/.config/nvim/lua/plugins/sessions.lua:79).

Unlike the window and Oil registrations, session preferences have no live getter.
The toggle therefore reads saved intent even when auto-session has temporarily
disabled saving after a cancelled or failed restore.

Observed through the actual `<leader>Sa` callback:

| Stage                                    | Saved preference | Runtime auto-save |
|------------------------------------------|------------------|-------------------|
| Before safety suspension                 | true             | true              |
| After `auto-session.disable_auto_save()` | true             | false             |
| First `<leader>Sa`                       | false            | false             |
| Second `<leader>Sa`                      | true             | true              |

The preference is toggled correctly, but the live feature needs two presses to
resume. `:PersistToggleInfo` also reports its fallback `current=true` before the
first press, even though runtime auto-save is false.

Suggested fix: expose saved intent and temporary suspension separately. Decide
whether `<leader>Sa` should toggle intent or effective runtime state; add a live
getter or explicit resume action accordingly. Keep automatic safety suspensions
temporary instead of silently persisting them.

### F5. Durable window-option toggles depend on the focused plugin window

Sources:
[window getters](/home/konkov/.config/nvim/lua/util/preferences.lua:147),
[window application policy](/home/konkov/.config/nvim/lua/util/preferences.lua:62).

The getters read `vim.wo[id]` from the focused window. Setters deliberately skip
special buffers, so a plugin's local settings can disagree with the durable
normal-file preference.

Reproduction: save `number=true`, focus a `nofile` buffer with local
`number=false`, then toggle `number` through the registry.

Observed: the saved preference remains true and the focused window remains
false. The global preference did not switch off, and the focused window did not
change. Similar ambiguity affects wrap, spell, relative numbers, and folding.

Suggested fix: use durable intent when toggling from special buffers, while
retaining an intentional policy for normal-file local/prose overrides. Continue
to leave plugin window layout options alone.

### F6. A FileType event overrides the buffer-local Treesitter disable

Sources:
[manual toggle](/home/konkov/.config/nvim/lua/util/ui_debug.lua:101),
[automatic start](/home/konkov/.config/nvim/lua/plugins/treesitter.lua:52).

`UiToggleTreesitter` sets `b:treesitter_disabled` and stops highlighting. The
FileType attachment callback never consults that flag.

Reproduction with the installed Lua parser:

1. Open a Lua buffer and verify its highlighter is active.
2. Run `:UiToggleTreesitter`.
3. Run `:doautocmd FileType lua` (or otherwise retrigger filetype setup).

Observed:

```text
after disable:   treesitter_disabled=true, highlighter active=false
after FileType:  treesitter_disabled=true, highlighter active=true
```

Suggested fix: make automatic attachment honor the buffer-local disable flag.
Also update that flag only after a requested manual start succeeds. This remains
a buffer-local control; it does not need a global persist-toggle preference.

## Additional consistency decisions

These are opportunities, not confirmed requirements to change behavior.

| Area                                 | Current behavior                                                                                                                                                                      | Suggested decision                                                                                                                                         |
|--------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Neo-tree hidden files                | Native `H` changes tree state; no preference registry bridge. Oil's analogous `g.` is persistent.                                                                                     | Decide whether Neo-tree visibility should persist too, under its own ID; the filters differ from Oil's.                                                    |
| Tiny inline diagnostic display modes | `TinyInlineDiag toggle_cursor_only` and `toggle_all_diags_on_cursorline` mutate plugin options directly. Enable/disable/toggle persist, but these modes do not.                       | Persist these two modes if they are intended user preferences, or document their temporary scope. Keep `reset` semantics explicit.                         |
| Native Oil/Flash APIs                | Custom keymaps persist, but direct `require('oil').toggle_hidden()` and `require('flash').toggle()` bypass the registry. Gitsigns and tiny-inline-diagnostic have native API bridges. | Decide whether supported native entry points should behave consistently; otherwise document that only the mapped/registry paths persist.                   |
| Autoformat controls                  | Global enable/disable commands persist, but there is no dedicated autoformat toggle mapping. `FormatDisable!` is intentionally buffer-local.                                          | A persistent toggle mapping would improve consistency if frequently used. Retain the local override.                                                       |
| Registry discoverability             | `session_autorestore` and `test_summary_on_run` have registry commands but no dedicated mappings.                                                                                     | Make all registered preferences easy to discover through a common picker or clearer which-key entries; separate preference changes from opening UI panels. |

## Documentation discrepancies

- [Neo-tree behavior guide](/home/konkov/.config/nvim/docs/core/neo-tree-cwd-behavior.md:19)
  calls `<leader>ue` a current-session control.
- [Plugin map](/home/konkov/.config/nvim/docs/core/plugin-map.md:301)
  also calls that behavior session-local. It is actually the durable
  `neotree_reveal_on_open` preference.
- [Crash course](/home/konkov/.config/nvim/docs/core/crash-course.md:1268)
  describes inline diagnostics as enabled on LSP attach. The accurate behavior is
  that attach reapplies the saved preference, including false.

These descriptions can cause the same uncertainty as the session auto-save
mapping that prompted this inspection.

## Controls whose existing scope is appropriate

The audit did not treat every use of “toggle” as a missing durable preference.

| Controls                                                                          | Existing scope / owner                                                                                                                |
|-----------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| Spell, wrap, numbers, folding, mouse                                              | Registered preferences, with normal-window and prose rules                                                                            |
| Diagnostic visibility, inline diagnostic enablement, inlay hints, reference style | Registered preferences; F2 concerns interaction with local suppression                                                                |
| File auto-save, autoformat, session auto-save/restore                             | Registered preferences; local formatting overrides and session safety suspension are intentional                                      |
| Debug panel keep-open and automatic test summary opening                          | Registered preferences, independent of explicitly opening/closing the panels                                                          |
| Gitsigns blame, word diff, line highlight, deleted-line display                   | Registered preferences, including native command bridges                                                                              |
| Theme                                                                             | Themery owns persistence; no duplicate boolean registry entry needed                                                                  |
| Buffer pins and order                                                             | Per-session metadata, not a single global boolean                                                                                     |
| Terminal, Trouble, Aerial, quickfix, debug panels, REPL, live-hunk views          | Opening and closing a UI or process, rather than changing a durable global policy                                                     |
| Breakpoints, watch targets, local Illuminate/Treesitter controls                  | Context-specific state; F6 concerns honoring the local choice                                                                         |
| Python LSP backend                                                                | Explicitly session-wide; resets to Pyright at startup. A durable backend selection would be a separate non-boolean preference design. |
| Java scratch placement and global scratch directory                               | Code-level workflow policy, not currently runtime toggles. No change proposed without a workflow requirement.                         |

## Validation and limits

- Used disposable state paths and temporary directories; no real saved sessions
  or preference JSON were rewritten by the inspection checks.
- Reproduced F1 with two real processes sharing a temporary registry file.
- Reproduced F2–F5 against the installed registry and configured plugin paths.
  Oil used an actual modified directory buffer; no directory edits were saved.
- Reproduced F6 using the installed Lua parser and actual FileType callback.
  Parser installation was disabled in that isolated check.
- Reviewed source for the additional consistency decisions and documentation
  discrepancies. Those suggestions were not treated as proven failures.
- Existing preference and compatibility suites were run separately as a baseline;
  passing them does not cover the six edge cases above.
- No external Git checkout, language-server startup, package installation, or
  runtime configuration changes were needed.

Suggested implementation order: F1 and F2 first, F3 and F6 next, then settle the
intent-versus-runtime semantics behind F4/F5 and update the misleading docs.
