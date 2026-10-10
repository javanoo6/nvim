# IntelliJ LSP Migration Plan

- Goal: migrate Java from `nvim-java` / JDTLS to
  [JetBrains/intellij-lsp.nvim](https://github.com/JetBrains/intellij-lsp.nvim),
  preserving useful local workflows wherever the new backend supports them.
- Working branch: `intelijidea_implementation`.
- Status: Steps 1–3 complete; Step 4 Java formatting implemented and tested,
  with Python/YAML/shell formatter coverage gaps still open; Steps 5 and 7–8 complete; Step 6 skipped by user request.
- Execute one step at a time. Mark a step complete after its acceptance checks
  pass, and record gaps before advancing. Keep each step independently reviewable.
- The upstream plugin is pre-alpha. Pin the trial revision and record the server
  bundle version; recheck upstream APIs when implementing each step.
- Reference: [plugin manual](https://github.com/JetBrains/intellij-lsp.nvim/blob/main/doc/intellij-lsp.txt).

## Migration Rules

- Replace JDTLS directly on this Git branch; do not build a backend selector.
  Use Git to review or roll back migration changes.
- Disable JDTLS startup and retire or adapt JDTLS-only helpers, including paths
  that could re-enable JDTLS.
- Preserve standard Vim directions and existing leader namespaces.
- Keep Conform as the formatting entry point and trial the plugin/server formatter
  for every filetype currently routed through the daemon jar: Java, Markdown,
  Python, YAML, XML, and shell. Ruby currently uses RuboCop, despite appearing
  in the bridge timeout table; inventory any additional daemon-supported types.
- Formatting policy revised by the user after the LSP trial: use the standalone
  jar for Java, Markdown, and XML because it demonstrated broader formatting and
  Java member rearrangement. Java editing remains on IntelliJ LSP.
- Verify each language independently; Python/YAML/shell remain unsupported until
  a formatter demonstrates meaningful edits. Do not infer support from exit code.
- Review the downloaded server's EULA and obtain explicit acceptance before
  enabling `accept_eula`; do not assume acceptance from the migration request.
- Preserve unrelated working-tree changes and the formatter submodule's changes.
- Use `make check` for Lua configuration changes, plus focused runtime checks.
  Use disposable fixtures for rename, formatting, and build experiments.
- Update session context and relevant usage docs as behavior changes. Record
  observed results separately from advertised or unverified capabilities.

## Step 1 — Inventory and Baseline

- [x] Map JDTLS coupling in plugin specs, LSP attach hooks, completion, Java
  helpers, statusline, scratch, file operations, Spring tools, and Neotest.
- [x] Select representative projects: small Maven, Gradle, multi-module,
  mixed Maven/Gradle, and Spring Boot/Lombok where available.
- [x] Record current completion, diagnostics, imports, rename, formatter output,
  main run/debug, remote attach, and JUnit results on these projects.
- [x] Acceptance: baseline and dependency list are recorded; identify any
  unavailable fixtures or pre-existing failures rather than treating them as regressions.
- Evidence: [Step 1 baseline](intellij-lsp-baseline.md). Runtime passes and
  unverified workflows are listed separately; unchecked UI/service workflows
  remain explicit migration checks rather than assumed baseline passes.

## Step 2 — Replace the Java Backend

- [x] Disable `nvim-java` / JDTLS setup and guard or retire JDTLS-only call sites.
- [x] Add a pinned IntelliJ plugin spec, loaded at startup as upstream recommends.
- [x] Prepare the bundle/EULA review and record the version and acceptance state.
- [x] Set the analysis JDK using our existing Java-home resolution policy.
- [x] Disable overlapping plugin defaults for completion triggers, Enter,
  signature help, keymaps, theme, Git, formatting on save, and debug panels as
  needed; inspect each option's actual scope before relying on it.
- [x] Expose backend/server/root information through `:JavaInfo` or equivalent.
- [x] Acceptance: a Java file attaches to IntelliJ with no JDTLS client or
  accidental JDTLS startup; `:checkhealth intellij-lsp` succeeds.

- Evidence: [Step 2 implementation and checks](intellij-lsp-step-2.md).

## Step 3 — Editing, Project Import, and Navigation

- [x] Integrate `nvim-cmp` capabilities and snippets without duplicate completion UI.
- [x] Verify project/dependency completion, completion-added imports, hover,
  diagnostics, inlay hints, definitions, references, and decompiled navigation.
- [x] Verify quick fixes and refactoring through our action UI, including
  IntelliJ extension prompts, variants, and follow-up rename/live templates.
- [x] Verify symbol rename and Neo-tree file moves update references correctly.
- [x] Preserve Maven preference for mixed-build projects using supported config.
- [x] Adapt `<leader>ju` project refresh to the supported IntelliJ reload operation;
  document whether it reloads one workspace or all clients.
- [x] Acceptance: Maven and Gradle editing work, dependencies resolve, and
  multi-module navigation/refactoring checks pass; Spring/Lombok gaps are recorded.

- Evidence and explicit fixture/UI limits: [Step 3 results](intellij-lsp-step-3.md).

## Step 4 — Migrate Daemon Formatting to the Plugin

- [x] Inventory the jar's supported languages and active Conform routes;
  include Java, Markdown, Python, YAML, XML, and shell in the first trial.
- [x] Probe server formatting for each language, both in Java projects and
  standalone/non-Java projects. Check bundled language support, source handling,
  project roots, and server capabilities before wiring a route.
- [x] Route supported languages through the plugin/server while preserving
  `<leader>cf`, directory formatting, save-time error checks, and other LSPs.
- [x] Ensure directory formatting can obtain edits for its target buffers;
  do not assume every file already has an attached IntelliJ client.
- [x] Keep the plugin's independent format-on-save disabled to avoid double formatting.
- [x] On fixtures, compare baseline bridge output with server document/range
  formatting for every trial language, including repeated-format stability.
- [x] Probe supported import optimization and member rearrangement actions;
  do not infer these from ordinary LSP formatting support.
- [ ] Verify `.editorconfig`, project code style, unused/static imports,
  import grouping, and field/constructor/method arrangement.
- [x] Trial removal of the daemon jar; user subsequently chose to restore verified
  standalone Java/Markdown/XML routes and jar status reporting.
- [ ] Acceptance: supported routes use the plugin/server and pass manual/save/
  directory checks. Record each unsupported language and missing Java cleanup
  operation with an explicit resolution; complete coverage remains open until
  those gaps are resolved or the scope is revised with the user.

- Evidence: [Step 4 implementation and gaps](intellij-lsp-step-4.md).
  Project `.editorconfig`, unused/static imports, default grouping, range behavior,
  and unchanged member order are checked. Custom `.idea` code-style/import-layout
  settings remain unverified. Standalone Java rearrangement and Markdown/XML
  formatting have since been restored by user request; Python/YAML/shell remain
  unresolved, so full language coverage is not marked complete.

## Step 5 — Main Run and Debug

- [x] Adapt `<leader>jr`, `jd`, `jc`, and `jl` to IntelliJ run/debug/stop/output.
- [x] Use IntelliJ’s panel as the default DAP UI for all languages (user preference);
  preserve breakpoint/stepping keys and source-window behavior.
- [x] Verify Maven/Gradle compilation before launch, build failure output,
  working directory, resources, VM arguments, and main-class selection.
- [x] Ensure launch resolution and adapter startup use the client owning the
  source buffer; audit upstream first-global-client selection.
- [x] Check whether plain JVM launches cover our Spring Boot workflows and
  whether any build-tool-specific launch behavior needs separate integration.
- [x] Acceptance: breakpoints, stepping, variables, expression evaluation,
  dependency sources, stop/relaunch, and two-project routing work on fixtures.

- Evidence and fixture limits: [Step 5 results](intellij-lsp-step-5.md).
  Maven/Gradle, two-workspace routing, dependency sources, and a minimal Maven
  Spring Boot application pass. Custom `bootRun`/IDE run configurations and live
  Go UI interaction remain unverified; remote attach remains Step 6.

## Step 6 — Remote JVM Attach

- Skipped at the user’s request on 2026-10-10. Remote attach remains unavailable.

- [ ] Inspect the IntelliJ adapter's actual attach protocol and supported fields.
- [ ] Adapt `<leader>ja` host/port prompts if attach is supported.
- [ ] Verify remote breakpoints, source mapping, variables, and disconnect behavior.
- [ ] Acceptance: remote attach works, or the limitation and an explicitly
  isolated fallback are documented without silently enabling JDTLS.

## Step 7 — Tests and Test Debugging

- [x] Audit `neotest-java` dependencies on JDTLS project/settings/classpath commands.
- [x] Investigate IntelliJ JUnit/test launch support and build-tool execution.
- [x] Choose a supported adapter, a small compatibility layer, or Maven/Gradle
  execution with result parsing based on demonstrated capabilities.
- [x] Preserve nearest/file/package runs, summary/output, failed-test reruns,
  parameterized result mapping, and sequential runs where supported.
- [x] Integrate test debugging only after ordinary test execution is reliable.
- [x] Acceptance: passing/failing/parameterized JUnit fixtures produce correct
  results and output; test breakpoints work or their unsupported status is explicit.

- Evidence: [Step 7 results and limits](intellij-lsp-step-7.md).

## Step 8 — Local Helpers and Workspace Lifecycle

- [x] Adapt `<leader>ci` / `cI` import helpers to actual IntelliJ actions.
- [x] Adapt or retire field usage counters and Java code-lens glue based on capabilities.
- [x] Adapt Java statusline, refresh/restart, and cache commands to IntelliJ.
- [x] Keep project creation and project-local scratch paths; verify completion,
  dependencies, run/debug, and test-source handling before changing scratch storage.
- [x] Audit `spring-boot.nvim` separately; keep it in IntelliJ mode only if its
  integration works without JDTLS-specific commands.
- [x] Verify session restore, Git branch restore, cwd changes, two workspaces,
  and stopped-client reattachment without stale indexing or duplicate clients.
- [x] Acceptance: every exposed Java action works or reports a clear unsupported
  state; switching projects/sessions routes actions to the correct workspace.

- Evidence: [Step 8 results and limits](intellij-lsp-step-8.md).

## Step 9 — Final Validation and Cleanup

- [ ] Review the completed checks and unresolved gaps against daily workflows.
- [ ] Confirm IntelliJ is the sole configured Java backend and the required
  editing/run/debug/test checks pass.
- [x] Remove obsolete JDTLS patches/dependencies after their replacements work;
  document remaining gaps without introducing a fallback selector.
- [x] Retain the standalone daemon formatter for verified Java/Markdown/XML routes
  by user request; preserve formatter submodule changes.
- [ ] Update session context, crash course, plugin map, and Java workflow docs;
  reconcile the older inspection and scratch roadmaps with observed capabilities.
- [ ] Acceptance: `make check` and focused runtime checks pass, documentation
  matches the active backend, and remaining limitations are recorded.

## Current Templates, Rename, and Command Keys

- File templates are enabled in `lua/plugins/intellij-lsp.lua`. A new empty Java
  file offers Class, Interface, Record, Enum, Annotation, or Exception. IntelliJ
  derives the package and name from its project path. Selecting a template writes
  the empty file before interpolation; cancelling leaves the new buffer unsaved.
  `:IntellijLspFileTemplate` opens the picker manually for an empty attached buffer.
- `<leader>cr` uses LSP symbol rename for variables, methods, and classes. The
  migration fixtures verified method rename, including cross-module references.
  Neo-tree file operations use LSP will/did-rename integration; package moves and
  updated imports were verified during migration.
- `:IntellijLspRename {path}` is file rename only. It updates references before
  moving the file and requires `rename_files = true`, currently disabled. The
  pinned implementation selects the first global IntelliJ client, so it does
  not provide our owning-workspace routing guarantee for multiple projects.
- `gt` opens `:IntellijLspTypeHierarchy subtypes` in IntelliJ-attached Java
  buffers. Elsewhere it keeps Vim's next-tab behavior. Use
  `:IntellijLspTypeHierarchy supertypes` for the other direction.
- Upstream `keymaps = false` remains intentional: its `<leader>ci` conflicts
  with our Java import helper and `<leader>ts` with our test summary.
- Java hints override `hints.collapse complex types` to false. Parameter names,
  local-variable types, lambda-parameter types, and call-chain types retain the
  upstream defaults. Normal/insert mode transitions do not toggle hints;
  `<leader>uh` controls enablement.

The 32 commands below are audited against the local configuration. Keys usually
call repo helpers or existing Glance/Trouble/Conform/DAP actions rather than the
literal IntelliJ commands. Twenty command entries have dedicated source-buffer
equivalents after adding `gt`, counting Output/Log and RunStop/DebugStop separately.
Call hierarchy uses Trouble's browser, not the same upstream UI.

| Upstream command                 | Local key or status                                                                                                      |
|----------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| `IntellijLspRestart`             | `:JavaRestart` restarts the owning workspace; no dedicated Java restart key. `<leader>lr` invokes generic `:LspRestart`. |
| `IntellijLspClearCache`          | `<leader>XC` / `<leader>XJ`, scoped to the owning workspace                                                              |
| `IntellijLspOutput`              | `<leader>jl`, toggle build/program output                                                                                |
| `IntellijLspLog`                 | Same output toggle, `<leader>jl`                                                                                         |
| `IntellijLspReferences`          | `gR` (Glance), `<leader>cu` (Trouble usages)                                                                             |
| `IntellijLspReload`              | `<leader>ju`, reload the owning workspace                                                                                |
| `IntellijLspTypeHierarchy`       | `gt`, subtypes; supertypes via the command                                                                               |
| `IntellijLspCallHierarchy`       | `<leader>cl`, Trouble call hierarchy                                                                                     |
| `IntellijLspFormat`              | `<leader>cf`, Conform standalone jar; full-file Java formatting optimizes imports and rearranges members                 |
| `IntellijLspSymbols`             | `<leader>sS`, Telescope workspace symbols                                                                                |
| `IntellijLspCompilationErrors`   | Command only                                                                                                             |
| `IntellijLspExportWorkspace`     | Command only                                                                                                             |
| `IntellijLspFileTemplate`        | Automatic picker for new empty Java files; command for manual use                                                        |
| `IntellijLspRename`              | Disabled; use Neo-tree file operations                                                                                   |
| `IntellijGitStatus`              | IntelliJ Git integration disabled                                                                                        |
| `IntellijGitDiff`                | IntelliJ Git integration disabled                                                                                        |
| `IntellijGitLog`                 | IntelliJ Git integration disabled                                                                                        |
| `IntellijGitBranches`            | IntelliJ Git integration disabled                                                                                        |
| `IntellijLspRun`                 | `<leader>jr`, scoped build/run helper                                                                                    |
| `IntellijLspRunStop`             | `<leader>jc`, stop the Java build/program                                                                                |
| `IntellijLspDebug`               | `<leader>jd`, scoped build/debug helper                                                                                  |
| `IntellijLspDebugStop`           | `<leader>jc`; `<leader>dt` terminates the current DAP session                                                            |
| `IntellijLspBreakpointToggle`    | `<leader>db`                                                                                                             |
| `IntellijLspBreakpointCondition` | `<leader>dB`                                                                                                             |
| `IntellijLspBreakpointClearAll`  | No dedicated key                                                                                                         |
| `IntellijLspBreakpointList`      | No dedicated key                                                                                                         |
| `IntellijLspDebugContinue`       | `<leader>dc`                                                                                                             |
| `IntellijLspDebugStepOver`       | `<leader>dO`                                                                                                             |
| `IntellijLspDebugStepInto`       | `<leader>di`                                                                                                             |
| `IntellijLspDebugStepOut`        | `<leader>do`                                                                                                             |
| `IntellijLspDebugEvaluate`       | `<leader>de`, expression or selection                                                                                    |
| `IntellijLspDebugWatch`          | `w` inside the debug panel adds a watch; no source-buffer watch key. `<leader>dw` opens DAP hover widgets.               |

## Standalone Formatter Decision

The user chose to restore the standalone formatter after the pinned LSP trial.
`<leader>cf`, format-on-save, and `:FormatDir` now use `idea_formatter` for Java,
Markdown, and XML, with LSP fallback disabled. Full-file requests pass `--format`,
`--optimize-imports`, and `--rearrange`; range requests only pass `--format` and
Conform filters the resulting edits. The explicit EditorConfig path is this
Neovim config's `.editorconfig`, as in the previous standalone route.

| Capability                | Standalone jar   | Pinned LSP route      |
|---------------------------|------------------|-----------------------|
| Java formatting           | Yes              | Yes                   |
| Optimize Java imports     | Yes              | Yes, separate command |
| Rearrange Java members    | Yes              | Unavailable           |
| Markdown / XML formatting | Demonstrated     | Unavailable           |
| Python / YAML / shell     | Not demonstrated | Unavailable           |

Follow-up disposable-file checks passed: manual Java cleanup, member order,
repeated-format stability, range formatting without import/member cleanup,
save-time Java cleanup, and `FormatDir` across two
Java files plus Markdown/XML (4 changed, 0 failed). No LSP client was started.
The code comment in `lua/plugins/formatting.lua` records the same comparison.

### Python and YAML Follow-Up

The user explicitly requested standalone IntelliJ formatting for `.md`, `.py`,
`.xml`, `.yaml`, and `.yml`. Markdown/XML were already routed to the jar; Python
and YAML now also use `idea_formatter` with LSP fallback disabled. Both YAML
extensions resolve to Neovim's `yaml` filetype. Earlier unchanged baseline samples
remain historical findings, rather than a reason to block these requested routes.
A subsequent user request also routes shell (`sh`) files through the same jar;
the unsupported-formatter stub has been removed.

## Java Inspection Diagnostics Audit

The requested Eclipse/JDTLS warning policy cannot currently be reproduced through
supported configuration of server `263.6379.0`. A live disposable Maven fixture
was queried with `textDocument/diagnostic`, then a second fresh workspace was
queried with a selected `.idea/inspectionProfiles` profile. Both returned the
same 19 diagnostics, all at LSP warning severity (2). The profile explicitly
turned off `AssignmentUsedAsCondition`, but that warning still appeared.

| Requested checks | Observed pinned-server behavior |
| --- | --- |
| Unused imports | Warnings returned (`UNUSED_IMPORT`) |
| Raw types / unchecked operations | Warnings returned (`rawtypes`, `unchecked`) |
| No-effect assignment / identical comparison | Warnings returned (`SillyAssignment`, `DataFlowIssue`, `ConstantValue`) |
| Boolean assignment in conditions | Warning returned (`AssignmentUsedAsCondition`) |
| Empty statement | Warning returned (`UnnecessarySemicolon`) |
| Redundant explicit constructor type arguments | Warning returned (`Convert2Diamond`) |
| Unused private field/method, local, parameter | No warning on the fixture; Java server explicitly disables `UnusedDeclarationInspection` |
| Missing `@Override`, missing enum cases/default | No warning on fixture; inspection extension defaults have `INFORMATION` level |
| Parameter reassignment, local hiding, switch fallthrough, ignored object allocation | No warning on fixture; corresponding inspection extensions are disabled by default |
| Potentially-static method checks | Disabled by default, consistent with the requested quiet policy |

Read-only inspection of the installed bundle's class bytecode explains the
results: `LSInspectionsKt` chooses inspection extensions from their built-in
`enabledByDefault`/display-level attributes, and
`LSJavaDiagnosticsCustomizerKt` explicitly disables unused declarations (reason
`LSP-1114`). `AnalyzerInspectionProjectProfileManager` returns its stored
application profile and rejects `setRootProfile`. The selected project profile
was not honored in the live diagnostic test. Ordinary IDEA profile documentation
therefore does not establish support for this standalone language server.

Neovim already enables signs, underlines, and severity sorting, with
`tiny-inline-diagnostic.nvim` for inline messages. `<leader>xb` opens current-buffer
diagnostics and `<leader>xx` opens project-root diagnostics in Trouble. These
views cannot produce checks absent from the server response. No ineffective
profile/settings keys or substitute diagnostics provider were added. Full parity
requires a server build with configurable inspections and working unused-code
support; compiler-only diagnostics do not replace these inspections.

## Cleanup Record

- Removed the disabled nvim-java plugin spec and lock entry, JDTLS JVM/client/
  cache/branch helpers, retired field/codelens helpers, Eclipse compiler prefs,
  and obsolete Neotest JDTLS execution/debug/binary overrides.
- Kept the active IntelliJ test bridge and neotest-java file detection, root
  detection, and parameterized-result overrides. The bridge replaces build_spec;
  upstream construction does not execute the retired JDTLS paths.
- Removed raw migration evidence JSON, formatter input/output fixtures, and
  obsolete JDTLS patch/run/fast-event notes. Readable step findings and their
  known limits remain as the migration record; historical baseline source paths
  describe the pre-migration state and are not active configuration references.
- Preserved the formatter submodule and unrelated files. Step 4's Python/YAML/shell
  formatting gaps and Step 6's skipped remote attach remain open.

## Progress Log

- Planning: migration checklist created; runtime configuration unchanged.
- Plan revised: direct replacement on the migration branch, no backend switch;
  trial plugin/server formatting across all daemon-jar formatting routes.
- Step 1 (2026-10-10): dependency inventory, representative project selection,
  Maven/JDTLS baseline and six-language formatter comparisons recorded in
  [intellij-lsp-baseline.md](intellij-lsp-baseline.md). No runtime config changes.
  Python/YAML/shell samples produced no edits despite successful formatter exits.
  Next: Step 2, replace Java backend and prevent JDTLS-only startup paths.
- Step 2 (2026-10-10): pinned plugin and verified server installed, EULA accepted
  explicitly by the user, JDTLS/legacy actions disabled, JavaInfo added; live
  IntelliJ initialization/symbol request and health checks pass. Next: Step 3.
- Step 3 (2026-10-10): scoped project reload and mixed-build Maven policy added;
  editing/navigation/import/action/file-move and multi-module checks pass.
  Spring/Lombok fixture resolves annotations/generated methods; extension UI
  bridges are checked separately with synthetic payloads. Next: Step 4.
- Step 4 (2026-10-10, partial): Java Conform formatting/import optimization,
  standalone startup, and target-buffer directory requests implemented and tested.
  Removed all six daemon routes. Markdown/Python/YAML/XML/shell now report explicit
  unsupported errors; Java rearrangement and custom `.idea` style checks remain open.
  Evidence: [Step 4 results](intellij-lsp-step-4.md).
- Step 5 (2026-10-10): scoped Java build/run/debug/stop/output implemented;
  IntelliJ's stack/locals/watches panel replaces nvim-dap-ui globally. Maven,
  Gradle, two-workspace stop/relaunch, dependency sources, Python UI, real process
  cancellation with a synthetic build resolution, and minimal Spring Boot checks
  pass. Step 4 coverage gaps remain open. Next: Step 6.
- Steps 7–8 (2026-10-10): Step 6 skipped by request. IntelliJ-backed Neotest
  compile/classpath/console/debug bridge implemented, with passing Maven/Gradle
  file/package/nearest/failed/sequential and parameterized checks. Import fixes,
  scoped restart/cache/HEAD reload, status, and reattachment adapted; field lenses
  retired and spring-boot.nvim remains disabled. Project scratch storage retained.
  Step 4 coverage gaps remain. Next: Step 9 final audit/cleanup.
- Follow-up cleanup: enabled Java templates and full generic inlay types, removed
  mode-transition hint toggles, added Java-buffer `gt` type hierarchy, documented
  command equivalents/rename scope, and removed 34 obsolete files. `make check`,
  adapter-construction smoke checks, and synthetic LSP-attach mapping checks pass.
  These follow-up checks do not repeat the earlier live server/build fixtures.
- For each completed step, append the plugin/server versions, fixtures used,
  checks passed, known gaps, and the next step.
