# Live Hunks View Plan

Goal: toggle a right-side live hunk view that lines up changed hunks beside the buffer being edited.

## Desired Experience

- Work in the normal file buffer on the left.
- Toggle a right-side companion buffer from `<leader>u?`.
- The companion shows every changed hunk for the current file.
- Hunk blocks stay visually aligned near their source lines as the edit buffer scrolls.
- Updates happen while editing without opening full Diffview.

## Proposed Key

- `<leader>ug`: toggle live git hunks view.

This stays under the UI toggle group and avoids the existing `<leader>Gh*` hunk-action group.

## Data Source

Use Gitsigns as the first source:

- It already owns signs, hunk parsing, and live refresh.
- It tracks the current buffer and git base.
- It avoids duplicating git diff parsing in the first version.

If Gitsigns does not expose enough structured data for alignment, add a narrow fallback around `git diff --unified=0 -- <file>` and parse with a real
hunk-header parser.

## Buffer Layout

1. Create a scratch buffer with:
    - `buftype=nofile`
    - `bufhidden=wipe`
    - `swapfile=false`
    - `modifiable=false` except during render
2. Open it in a right vertical split.
3. Set fixed width around 45-60 columns.
4. Disable diagnostics, spell, fold, and signcolumn in the hunk view.
5. Use extmarks/virtual lines for spacing instead of inserting huge blank ranges when possible.

## Alignment Model

1. Track source window top line with `winsaveview()`.
2. Render hunk summaries relative to source line numbers.
3. On `WinScrolled`, rerender or adjust extmarks so hunks appear near the matching source code.
4. Show compact headers:
    - `@@ old_start,old_count new_start,new_count @@`
    - status label: added, changed, deleted
5. Use diff syntax or custom highlights for added/removed lines.

## Refresh Strategy

- Debounce on:
    - `TextChanged`
    - `TextChangedI`
    - `BufWritePost`
    - `User GitsignsUpdate` if available
    - `WinScrolled`
- Keep a per-source-buffer state table:
    - source buffer
    - source window
    - view buffer
    - view window
    - last rendered changedtick

## Commands And API

- `:LiveHunksToggle`
- `:LiveHunksClose`
- `:LiveHunksRefresh`
- `require("util.live_hunks").toggle()`

## Implementation Steps

1. Create `lua/util/live_hunks.lua`.
2. Prototype static render from Gitsigns hunks for the current file.
3. Add right-side scratch window lifecycle.
4. Add scroll-aware alignment.
5. Add debounced refresh autocmds.
6. Map `<leader>ug`.
7. Document in `docs/core/session-context.md`, `docs/core/plugin-map.md`, and `docs/core/crash-course.md`.

## Risks

- Perfect line alignment is hard when one source hunk maps to many removed lines.
- Insert-mode updates can be noisy; debounce must be conservative.
- The view must not steal focus while typing.
- Diffview and Gitsigns preview windows should not be treated as source buffers.

## Verification

- Toggle opens/closes beside a tracked file.
- Added, changed, and deleted hunks render correctly.
- Scrolling source buffer keeps nearby hunks aligned.
- Editing updates the view without focus jumps.
- Closing the source buffer closes the hunk view.
- `make check` passes.
