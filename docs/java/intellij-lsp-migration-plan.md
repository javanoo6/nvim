# IntelliJ LSP Migration Plan

- Goal: migrate Java from `nvim-java` / JDTLS to
  [JetBrains/intellij-lsp.nvim](https://github.com/JetBrains/intellij-lsp.nvim),
  preserving useful local workflows wherever the new backend supports them.
- Working branch: `intelijidea_implementation`.
- Status: Steps 1–3 complete; Step 4 Java formatting implemented and tested,
  with language/rearrangement coverage gaps still open; Steps 5 and 7–8 complete; Step 6 skipped by user request.
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
- Target removal of the daemon jar from those formatting routes. Verify each
  language independently: upstream advertises Java/Kotlin, and adding a filetype
  to client configuration does not establish server language/formatter support.
- Record unsupported formatting, import optimization, or member rearrangement
  as migration gaps; do not silently route them back through the jar.
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
- [x] Remove the daemon jar from migrated Conform routes and formatter status helpers.
- [ ] Acceptance: supported routes use the plugin/server and pass manual/save/
  directory checks. Record each unsupported language and missing Java cleanup
  operation with an explicit resolution; complete coverage remains open until
  those gaps are resolved or the scope is revised with the user.

- Evidence: [Step 4 implementation and gaps](intellij-lsp-step-4.md).
  Project `.editorconfig`, unused/static imports, default grouping, range behavior,
  and unchanged member order are checked. Custom `.idea` code-style/import-layout
  settings remain unverified. Five non-Java formatters and rearrangement have no
  replacement yet; this step is not marked complete.

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
- [ ] Remove obsolete JDTLS patches/dependencies after their replacements work;
  document remaining gaps without introducing a fallback selector.
- [ ] Remove obsolete daemon formatter configuration once all targeted routes
  have a working replacement; preserve unrelated formatter submodule changes.
- [ ] Update session context, crash course, plugin map, and Java workflow docs;
  reconcile the older inspection and scratch roadmaps with observed capabilities.
- [ ] Acceptance: `make check` and focused runtime checks pass, documentation
  matches the active backend, and remaining limitations are recorded.

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
- For each completed step, append the plugin/server versions, fixtures used,
  checks passed, known gaps, and the next step.
