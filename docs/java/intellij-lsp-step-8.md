# IntelliJ Migration — Step 8

Implemented on 2026-10-10. Step 6 remains skipped.

## Active helpers

- `<leader>ci` pulls current IntelliJ diagnostics and applies the cursor's
  `Import class` fix through `applyModCommand`. `<leader>cI` applies missing
  imports serially, refreshing diagnostics after edits. IntelliJ's action
  picker handles ambiguous choices; a stalled/cancelled picker pauses the pass.
- `<leader>ju` / `:JavaProjectUpdate` and `:JavaBranchRefresh` reload the owning
  workspace. Java buffer entry/focus/session events compare Git HEAD and reload
  after a detected commit change. The first observation establishes a baseline.
- `:JavaRestart` restarts the buffer's workspace and reattaches its loaded buffers.
  `<leader>XC`, `<leader>XJ`, and `:JavaCleanCorruptWorkspaces[!]` clear that
  workspace's index and restart. The bang has the same scoped behavior.
- Restart allows three seconds for graceful shutdown, then forces that client
  to stop. Cache deletion waits for exit, checks path containment/ownership,
  and removes only its index directory. Other clients and cached bundles remain.
- Upstream `:IntellijLspRestart`/`:IntellijLspClearCache` retain their global
  behavior; use the Java aliases above for workspace-scoped operations.
- Java buffer/session entry reattaches or starts an owning client. Statusline
  reads that client's readiness/busy state. Changing cwd does not redirect a
  named Java buffer's workspace actions.
- Project creation and scratch storage remain: Java scratch prefers
  `src/test/java/Scratch.java`, then `src/main/java/Scratch.java`.
- JDTLS field counters/code-lens setup is retired. `<leader>uJ` reports this;
  `gR` still lists references. `spring-boot.nvim` remains disabled because its
  integrations use JDTLS commands; ordinary Spring app run/debug is Step 5.

## Verified

- Cursor import of ArrayList and bulk import of HashMap using real diagnostics.
- Explicit reload, restart, index clearing, forced-stopped client reattachment,
  cwd changes, and repeated SessionLoadPost without duplicate clients.
- Two simultaneous Maven workspaces: Git HEAD change reloads only its client;
  restart/index clearing preserve the other client's identity and activity.
- Actual scratch mapping creates the project test-source scratch. Commons Lang
  test dependency supplies completion for `StringUtils.upperCase`; launch paths
  include test classes/dependencies. Scratch run prints `SCRATCH=HELLO`, and
  scratch debugging stops at a breakpoint before successful continuation.
- `make check` passes. Fixture results are in
  [the evidence file](intellij-lsp-step-8-evidence.json).

## Limits

- Session restoration was checked through SessionLoadPost and loaded buffers,
  not a full interactive auto-session save/restore. Git checks used a real HEAD
  change and focus event, not every Git UI. Same-HEAD branch changes do not
  trigger automatic reload; use `:JavaBranchRefresh` when needed.
- Ambiguous import UI uses the existing IntelliJ chooseAction bridge; this step's
  real import fixture used unambiguous classes. Scratch checks used Maven.
- The external scratch-storage proposal remains deferred. Project creation's
  existing implementation was retained, rather than regenerated during these checks.
- Remote attach and Step 4's rearrangement/non-Java formatter gaps remain.
- Legacy helper files are retained inactive for Step 9 cleanup.
