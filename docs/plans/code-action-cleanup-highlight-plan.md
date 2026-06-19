# Code Action Cleanup Highlight Task

Goal: highlight code ranges when available LSP code actions mention cleanup, so the buffer shows cleanup candidates before opening the action picker.

Status: planned only. No runtime implementation exists yet.

Primary file to create later: `lua/util/code_action_cleanup.lua`.

## Scope

- Treat this as an LSP-code-action signal, not a formatter/linter replacement.
- Start with Java/JDTLS, because cleanup actions are most likely there.
- Keep the highlight passive: no auto-apply and no diagnostics mutation.
- Do not change `<leader>ca` / `<A-CR>` behavior. This feature is only a visual hint layer.

## Detection Model

1. Request `textDocument/codeAction` for visible buffer ranges.
2. Filter actions whose title or kind contains cleanup terms:
    - `cleanup`
    - `clean up`
    - `source.cleanup`
    - `source.organizeImports`
3. Prefer action-provided diagnostics/ranges when present.
4. If an action has no precise range, highlight the requested line range with a weaker highlight.

## Implementation Ideas

### Idea 1: Viewport CodeAction Scanner

Request code actions for the visible viewport plus a small margin.

Pros:

- Directly answers "what cleanup actions are available here?"
- Keeps requests bounded in large files.
- Works with LSP servers that only compute context-sensitive code actions.

Cons:

- Some servers may return broad source actions without precise ranges.
- Needs debouncing and stale-result cancellation.
- Scroll-heavy editing can generate many requests if not throttled.

Implementation sketch:

1. Read the source window with `vim.fn.winsaveview()`.
2. Build an LSP range from `topline` to `botline`.
3. Call `client:request("textDocument/codeAction", params, callback, bufnr)`.
4. Filter cleanup-like titles/kinds.
5. Mark exact diagnostic ranges when available; otherwise mark the requested line span.

### Idea 2: Diagnostic-Driven Scanner

Only request code actions for diagnostics currently visible in the buffer.

Pros:

- Fewer LSP requests.
- Better chance of precise ranges.
- Natural fit for cleanup quickfixes that are tied to warnings.

Cons:

- Misses source-level cleanup actions that do not come from diagnostics.
- Import cleanup / organize imports may not have diagnostics.

Implementation sketch:

1. Get diagnostics with `vim.diagnostic.get(bufnr)`.
2. Keep diagnostics inside the visible viewport.
3. Request code actions with `context = { diagnostics = { diagnostic } }`.
4. Highlight the diagnostic range when a cleanup action is returned.

### Idea 3: Hybrid Scanner

Use diagnostic-driven requests first, then one low-frequency viewport request for source actions.

Pros:

- Best coverage.
- Avoids turning every cursor movement into a broad code-action request.
- Lets diagnostics provide exact highlights where possible.

Cons:

- More moving parts.
- Needs careful deduplication.

Preferred approach: start with the hybrid scanner, but keep the first version simple enough to disable source-action scans if a server is too noisy.

## UI Model

- Add a namespace such as `custom_code_action_cleanup`.
- Add highlight groups:
    - `CodeActionCleanupHint` for precise cleanup ranges.
    - `CodeActionCleanupLine` for fallback line-level hints.
- Consider using a sign-column marker only after the highlight behavior is proven useful.
- Use extmarks with `hl_mode = "combine"` so Treesitter and diagnostics remain visible.
- Clear highlights on `TextChanged`, `BufLeave`, and LSP detach.

## Refresh Strategy

1. Debounce refresh on `CursorHold`, `BufEnter`, and `DiagnosticChanged`.
2. Limit requests to the visible viewport plus a small margin.
3. Cancel stale results by tracking a per-buffer generation counter.
4. Do not request while insert mode is active.
5. Refresh on `InsertLeave` if the buffer changed while insert mode was active.

Suggested defaults:

- Debounce delay: `300ms`.
- Viewport margin: `20` lines above and below.
- Max highlighted fallback lines per refresh: `200`.
- Filetypes enabled by default: `java` first, then expand after testing.

## Commands And Toggles

- Add `:CodeActionCleanupRefresh`.
- Add `:CodeActionCleanupClear`.
- Add `<leader>uC` toggle under the existing UI group.

## Implementation Steps

1. Create `lua/util/code_action_cleanup.lua`.
2. Implement title/kind matching and range extraction.
3. Add viewport-range request plumbing with debounce.
4. Add highlights and clear/update lifecycle.
5. Wire setup from `lua/plugins/lsp.lua` after LSP setup.
6. Document behavior in `docs/core/session-context.md`, `docs/core/plugin-map.md`, and `docs/core/crash-course.md`.

## Acceptance Criteria

- Cleanup-like code actions produce visible buffer highlights.
- Non-cleanup code actions do not highlight code.
- The feature can be toggled off with `<leader>uC`.
- Highlights clear immediately after edits and repopulate after debounce.
- Opening code actions with `<leader>ca` / `<A-CR>` still behaves exactly as before.
- No visible lag while typing or scrolling Java files.

## Open Questions

- Should `source.organizeImports` count as cleanup? Current assumption: yes.
- Should command-only JDTLS cleanup actions highlight the whole visible range or only show a sign? Current assumption: weak line highlight for the requested
  range.
- Should this be Java-only until proven stable? Current assumption: yes.

## Verification

- Java buffer with cleanup action highlights expected range.
- Buffer with no cleanup actions has no marks.
- Highlights disappear after editing the marked code.
- `<leader>ca` still opens the normal action picker.
- `make check` passes.
