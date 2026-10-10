# Step 4 — IntelliJ Formatting Trial

- Status: Java implementation passes focused checks; full Step 4 coverage remains
  open pending replacements for unsupported languages and member rearrangement.
- Checked on 2026-10-10 with plugin commit
  `9cfad18005470e4187090013e08f92ec9e437219`, server `263.6379.0`.
- Evidence: [protocol and runtime results](intellij-lsp-step-4-evidence.json).
  Disposable fixtures: `/tmp/nvim-intellij-step4-1zlrc08e`.

## Active Behavior

- `<leader>cf`, Conform format-on-save, and `FormatDir` use IntelliJ for Java.
  Full-file formatting runs `java.organize.imports`, then LSP formatting.
  Visual/explicit ranges reformat without changing imports outside the selection.
- Only the owning IntelliJ client receives Java requests. Directory targets are
  loaded, assigned a filetype, attached, and formatted in their buffer context.
  This Conform revision builds LSP formatting parameters from the current buffer;
  passing `bufnr` alone sent the wrong URI. `nvim_buf_call` fixes that routing.
- Preparation waits for initial import and checks a file's first formatting
  response without applying preliminary edits. Each preparation/request has a
  10-second bound. Initial startup/import can exceed this; retry after `JavaInfo`
  reports ready. Multiple preparation phases can exceed 10 seconds in total.
- Explicit standalone Java formatting starts the server at the file's parent
  directory with build import disabled. No backend selector or JDTLS startup.
- Project `.editorconfig` and IntelliJ project style govern formatting. The
  previous bridge forced this Neovim repo's `.editorconfig` for every project.
- Save-time LSP error checks and `FormatDisable` remain effective. Directory
  formatting is explicit cleanup and retains its existing behavior of ignoring
  that save-only error guard. Its writes disable autoformat temporarily to avoid
  duplicate cleanup. The plugin's independent format-on-save stays disabled.
- All six daemon jar routes are removed. Unsupported routes return explicit
  Conform errors and have LSP fallback disabled. Other formatter routes remain.
  `FormatterInfo` reports coverage gaps instead of jar availability.

## Observed Coverage

| Former jar route | Pinned server result in Maven and standalone fixtures |
|---|---|
| Java | Document formatting changes layout; second request returns no edits |
| Markdown | No formatting edits; bundled Markdown formatter absent |
| Python | No formatting edits; bundled Python formatter absent |
| YAML | No formatting edits; bundled YAML formatter absent |
| XML | No formatting edits; no XML LSP formatter demonstrated |
| Shell | No formatting edits; bundled shell formatter absent |

- Java formatting alone preserves imports and member order. The separate import
  command removes unused `Map`, sorts `ArrayList`/`List`, and removes unused static
  `Math.min` while retaining used static `Math.max`.
- The baseline jar reordered fields/constructors before methods. The server leaves
  the original method/field/constructor order intact. No rearrangement command or
  action was advertised for this fixture. Its exposed MCP `reformat_file` tool
  accepts file paths but exposes no optimize/rearrange options.
- Markdown/XML are losses relative to the recorded bridge fixture output.
  Python/YAML/shell were already no-ops in the baseline; a successful exit never
  established formatter support for them.

## Validation and Remaining Work

- Passed: Java manual full-file formatting and imports; range formatting with
  imports preserved; repeated-format stability; format-on-save; buffer disable;
  save skipped with an injected LSP error; directory formatting of two files,
  including an unopened file rewritten during the session (2 changed, 0 failed).
- Passed: standalone client startup without an existing client/build file;
  four-space project `.editorconfig` versus the Maven fixture's two spaces;
  unused regular/static import removal; explicit errors for all five unsupported
  routes; full plugin startup with Conform loaded; `make check` and diff checks.
- Early directory checks failed because of the current-buffer URI bug. A later
  unsupported-message check caught an incorrect Conform context field (`bufnr`
  instead of `buf`). Both are corrected; failed runs are excluded from evidence.
- Unverified: custom `.idea` code-style/import-layout rules, physical visual-mode
  keyboard interaction, and formatting the user's full cloudos workspace.
- Unresolved: select replacements for Markdown/Python/YAML/XML/shell; decide how
  to handle Java member rearrangement. No silent jar fallback is configured.
  Step 4 remains open until these gaps are resolved or the user revises its scope.
