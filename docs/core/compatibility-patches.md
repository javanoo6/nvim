# Compatibility patch registry

This registry tracks local changes that depend on plugin internals or preserve
behavior across upstream bugs/API changes. It does not imply that upstream has
fixed any recorded issue. Normal plugin options are not patches.

## Verified revisions

These are the installed/locked revisions checked on 2026-10-11, with Neovim
0.12.2. `tests/compatibility.lua` checks installed HEAD against `lazy-lock.json`,
requires each full revision to appear here, and rejects undocumented tracked Lua
edits inside these checkouts. Generated untracked `doc/tags` files are harmless.
Revision drift fails with the plugin name and a reminder to review this registry.

| Plugin              | Verified revision                          |
|---------------------|--------------------------------------------|
| `cmp-buffer`        | `b74fab3656eea9de20a9b8116afa3cfc4ec09657` |
| `which-key.nvim`    | `3aab2147e74890957785941f0c1ad87d0a44c15a` |
| `neotest`           | `fb84d87285698f7055f618083c351984449119b8` |
| `neotest-python`    | `51c453d57f8d5156671b42ea57fafa2e1c9fb641` |
| `neotest-golang`    | `542cbaf37f1233a2723ccd64ce8ed7e3acbd192b` |
| `neotest-java`      | `78d236da986cca4dd95cb10b1250c4c6e1508240` |
| `intellij-lsp.nvim` | `9cfad18005470e4187090013e08f92ec9e437219` |
| `bufferline.nvim`   | `655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3` |
| `glance.nvim`       | `e813e1230d7aba362df19e7d292f6f6766277af1` |
| `auto-session`      | `6cde3874a9283c2db55627acca5f28e4fa402320` |
| `git-conflict.nvim` | `4bbfdd92d547d2862a75b4e80afaf30e73f7bbb4` |
| `nvim-nio`          | `21f5324bfac14e22ba26553caf69ec76ae8a7662` |

The IntelliJ plugin remains explicitly pinned in `lua/plugins/intellij-lsp.lua`;
its bundled server baseline is `263.6379.0`. Plugin revision checks do not prove
compatibility with a different downloaded server or JDK.

## Upgrade workflow

1. Read the relevant entries below before updating their plugins. Read the Java
   migration docs before changing the IntelliJ or neotest-java integrations.
2. After an update, inspect changed internal APIs and the original failure.
   Update the verified revision here only after review; changing the lock alone
   intentionally does not silently approve the patch against a new revision.
3. Run `make check-compatibility` for the installed-contract and patch probes,
   then `make check` for all configuration, scope, rename, session, and hunks checks.
4. Perform the entry's interactive/language smoke checks where listed. The
   headless checks do not start language servers, debuggers, or test processes.
5. Remove a patch only when its original reproduction passes without it and its
   distinct local behavior remains supported. Update this registry and the
   session context with the evidence and replacement/removal decision.

Failures identify the plugin/contract or behavior. Do not bypass a failure by
renaming a missing function or merely accepting a new hash. Each entry below
has a check and removal condition; larger workflow limits remain explicit.

## Completion indexing

- **Owner:** `lua/plugins/completion.lua`, `patch_cmp_buffer_index_range()`.
- **Dependency:** cmp-buffer `Buffer.index_range`, `safe_buf_call`, `index_line`,
  `GET_LINES_CHUNK_SIZE`, and its `closed`/`lines_words` instance fields.
- **Failure:** async/on-lines indexing can request rows beyond a shrunken buffer
  and raise `Index out of bounds`. The replacement clamps ranges, checks buffer
  validity, and uses non-strict reads.
- **Check:** compatibility suite loads the real completion config, indexes real
  words with an oversized range, shrinks the buffer, and closes its index.
- **Manual smoke:** type/delete rapidly with buffer-word completion in insert mode.
- **Remove when:** upstream indexing survives the same shrink/close reproduction
  without this replacement and retains the required indexing behavior.

## Which-key trigger recovery

- **Owners:** `lua/plugins/ui.lua`, `lua/util/which_key_refresh.lua`.
- **Dependencies:** `which-key.triggers.suspend/attach/suspended`,
  `which-key.buf.get/clear`, `mode.buf:valid()`, and `which-key.util.mapmode()`.
- **Failure:** leader popups can stop after timeout/cancel or Diffview closes;
  session restoration can precede which-key's first buffer attachment.
- **Fixes:** same-mode deferred reattachment, explicit startup seeding, and
  rebuilding normal/visual triggers on `DiffviewViewClosed` or `:WhichKeyRefresh`.
- **Check:** compatibility suite uses real which-key setup and verifies the leader
  trigger after seeding, suspension, and a Diffview close event.
- **Manual smoke:** open/cancel/timeout the popup, enter/leave Visual mode, restore
  a session, and close a real Diffview tab; leader popups must remain usable.
- **Remove when:** all of those transitions work without the relevant local fix.
  Verify seeding, timeout, and Diffview fixes separately rather than deleting all
  three because only one upstream behavior changed.

## Neotest output limits

- **Owner:** `lua/util/neotest_output_guard.lua` replaces
  `neotest.consumers.output` and `neotest.consumers.output_panel` in `package.loaded`
  before Neotest setup.
- **Dependencies:** callable consumer tables, their public methods, client
  position/result/listener contracts, `neotest.lib.files.read`, terminal/float
  UI helpers, and the internal `output_panel.panel` constructor/window API.
- **Failure:** upstream output consumers read entire files into terminal buffers;
  very large Java output can freeze the editor.
- **Behavior:** cap content at `vim.g.neotest_output_max_bytes` or 2 MiB, retain
  beginning/end and the full file path, preserve short output and small files.
- **Check:** compatibility suite feeds actual files through both installed local
  consumers and actual Neotest terminal delivery; it checks truncation, retained
  head/tail/path, small output, and short output.
- **Discovered during this audit:** the old libuv code interpreted `fs_open` and
  `fs_read` results as error-first, and treated successful `fs_close` as an error.
  A real large-output panel probe failed at the file-open assertion. Corrected
  the result ordering and close the descriptor even if a chunk read fails.
- **Manual smoke:** open individual and aggregate output after real passing and
  failing tests, including a large log and repeated clear/open cycles.
- **Remove when:** upstream supports a bounded-output policy with the retained
  full-file pointer and equivalent consumer behavior; test without replacements.

## Neotest private client access

- **Owners:** `lua/util/neotest_scope.lua`, `neotest_failed.lua`,
  `neotest_sequential.lua`.
- **Dependency:** first upvalue of `run.get_tree_from_args` is named `client`;
  client exposes `get_adapter`, `_get_adapter`, `_update_positions`,
  `get_position`, `get_results`, and `run_tree`.
- **Reason:** discover a not-yet-cached current file, rerun failed positions, and
  coordinate sequential execution. A private layout change can disable those
  features; the helpers already warn on unexpected client layout.
- **Check:** compatibility suite binds the actual installed run consumer to the
  actual client and checks upvalue identity and methods. `make check` also runs
  `tests/neotest_scope.lua` for project isolation/discovery behavior.
- **Manual smoke:** nearest/file run on an undiscovered file, failed rerun, and
  sequential execution of several test files in the active project.
- **Remove when:** a supported public Neotest API supplies these operations;
  retain scoped rerun/sequential behavior while replacing private access.

## Python and Go test scope wrappers

- **Owners:** `lua/util/neotest_python.lua`, `lua/plugins/neotest.lua`,
  `lua/util/neotest_scope.lua`.
- **Dependencies:** Python adapter `root/build_spec`, spec `cwd/strategy.cwd`;
  Go adapter `is_test_file` and `neotest-golang.lib.goenv.should_skip(path, cwd)`.
- **Reason:** test execution must use its source project without changing editor
  cwd; Go detection must not require Go for unrelated Python files or consult
  another project's most recently activated scope.
- **Checks:** `tests/neotest_scope.lua` uses the installed Python builder, delayed
  builders, explicit cwd overrides, nested scopes, and Go SDK filtering;
  compatibility suite checks the installed Go filter API.
- **Manual smoke:** run Python tests in two projects and a Go module from an
  unrelated editor cwd; each process must resolve its own root-relative files.
- **Remove when:** upstream adapters expose equivalent per-project execution
  and discovery cwd controls without the wrappers. Keep editor cwd preservation.

## Java discovery and result overrides

- **Owners:** `lua/neotest-java/core/{file_checker,root_finder,result_builder}.lua`.
  Repo runtimepath must precede the installed neotest-java modules.
- **Dependencies:** neotest-java `Path` and `JunitResult` models,
  injectable report reader/scanner/remover contracts, Neotest Tree IDs/iteration,
  and the DAP termination event in the run context.
- **Failures:** construction-time cwd rejects legitimate test files; plain Git
  roots are treated as runnable Java projects; one parameterized invocation
  fails to map back to the discovered method node.
- **Check:** compatibility suite verifies local module ownership, valid test/main
  paths and class patterns, Git-only/Maven/Gradle roots, actual JunitResult
  objects, single/mixed parameterized outcomes, report cleanup, and abnormal exits.
- **Manual smoke:** real Maven/Gradle nearest/file/package tests and Neotest DAP,
  with passing/failing parameterized cases. See `docs/java/java-test-workflow.md`.
- **Remove when:** each upstream module independently passes the same reproduction
  without shadowing. Preserve build-root and method-result policies; do not
  remove all overrides when only one failure is corrected.

## IntelliJ client factory and editor commands

- **Owner:** `lua/util/java_intellij.lua` wraps `intellij-lsp.client.config` and
  overrides `extensions.EDITOR_COMMANDS` suggestion/rename entries.
- **Dependencies:** factory config signature/capabilities/on_attach callback,
  editor command table, readiness/status helpers, template prompt, and debug setup.
- **Reason:** preserve cmp and file-operation capabilities, let cmp own completion,
  restrict follow-up rename to IntelliJ, and select Maven for mixed build roots.
- **Check:** compatibility suite checks real installed API shapes, then uses a
  factory/setup seam to verify capability merging, upstream attach chaining,
  completion ownership, and follow-up rename routing. `tests/lsp_rename.lua`
  covers native Java rename dispatch. These probes do not launch IntelliJ.
- **Manual smoke:** real dependency completion/imports, rename, template creation,
  and mixed Maven/Gradle import; see `docs/java/java-workflow.md`.
- **Remove when:** supported upstream hooks/options supply the same behavior;
  keep cmp ownership, workspace routing, and mixed-root policy intact.

## IntelliJ Neotest and DAP bridges

- **Owners:** `lua/util/neotest_intellij.lua`, `java_launch.lua`, `debug_ui.lua`,
  `java_workspace.lua`, and `java_file_templates.lua`.
- **Dependencies:** adapter configuration/JUnit jar/results contracts; IntelliJ
  factory lookup, progress/templates/debug modules and JVM execute-command
  payloads; nvim-dap adapters/listener/panel contracts and cache-slot ownership.
- **Reason:** replace the retired JDTLS launch path while preserving existing
  Neotest discovery/results, scoped reload/restart/cache operations, and the
  shared IntelliJ debug panel.
- **Check:** compatibility suite constructs the actual Java adapter without
  launching a server, verifies adapter methods, and checks the installed helper
  APIs used by these bridges. This is structural coverage, not a compiler,
  launch-payload, cache deletion, or debugger acceptance test.
- **Manual smoke:** Maven and Gradle tests, JUnit selection, build failure,
  breakpoints/continue/results, two simultaneous workspaces, scoped restart/cache
  clearing, and remote-independent app debugging. Workflow limits are in
  `docs/java/java-workflow.md` and `java-test-workflow.md`; remote attach is unavailable.
- **Remove when:** a supported upstream integration covers the same workflows.
  Keep these user-selected features even if replacement code is shorter.

## Bufferline stale pins

- **Owner:** `lua/util/bufferline.lua`.
- **Dependencies:** group pin/removal methods, `persist_pinned_buffers` upvalue of
  `groups.add_element`, and `bufferline.ui.refresh`.
- **Failure:** persisting a pin can encounter a deleted buffer ID and throw.
- **Check:** compatibility suite checks the actual closure/method layout and
  injects a stale-buffer fault to exercise the repo helper. The deletion hook
  removes IDs before they become stale.
- **Manual smoke:** pin buffers, delete them, restore a session, and toggle pins.
- **Remove when:** upstream persists/removes stale pins safely without recovery;
  verify persistence and deletion transitions before dropping the helper.

## Glance fork and Java winbar

- **Owners:** `lua/plugins/glance.lua`; pinned fork
  `javanoo6/glance.nvim`, branch `fix/fs-read-nil-glance-list`.
- **Dependency/failure:** `glance.list` file reading must tolerate a nil
  `vim.loop.fs_read` result instead of using it as a string. Winbar is disabled
  because percent-encoded decompiled Java URIs can break statusline parsing.
- **Check:** compatibility suite checks the fork revision. The fork reader
  reproduction and disabled winbar configuration are also checked there.
- **Manual smoke:** references/definitions to unreadable files and Java dependency
  or decompiled sources; list previews must not crash with E539 or nil reads.
- **Remove when:** upstream tolerates nil reads and escapes URI content correctly.
  Returning to upstream and enabling winbar are separate decisions/reproductions.

## Session option compatibility

- **Owner:** `lua/util/session_scrub.lua`, `lua/plugins/sessions.lua`.
- **Dependencies:** auto-session `get_root_dir`, post-save lifecycle, native
  `SourcePre` and `v:this_session` path behavior.
- **Failure:** unsupported `includeformatexpr` and orphaned winmin restore lines
  break session sourcing; cleaning the whole history on every event scales badly.
- **Check:** `tests/session_scrub.lua` exercises actual installed save/restore,
  precise filenames, repaired/valid scripts, write failures, and unrelated files.
- **Remove when:** sessions generated/restored across the supported plugins/runtime
  no longer contain these invalid lines, including legacy sessions still in use.

## Git-conflict diagnostic API compatibility

- **Owner:** `lua/plugins/git.lua` sets upstream `disable_diagnostics = false`
  and handles conflict events with `vim.diagnostic.enable(false/true, {bufnr=...})`.
- **Failure:** plugin 2.1.0 calls the removed `vim.diagnostic.disable()` API on
  Neovim 0.12 when its own diagnostic toggling is enabled.
- **Check:** compatibility suite configures the actual plugin and fires detected/
  resolved events to verify the repo-owned diagnostic toggles.
- **Manual smoke:** enter and resolve a real conflict buffer, keeping mappings
  and normal diagnostics usable.
- **Remove when:** upstream uses the supported diagnostic API and its behavior
  matches the repo's buffer-local toggling policy.
