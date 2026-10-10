# Step 2 — IntelliJ Java Backend

- Completed: 2026-10-10 on `intelijidea_implementation`.
- Plugin pinned in its spec and `lazy-lock.json`:
  `9cfad18005470e4187090013e08f92ec9e437219`.
- Server bundle: `263.6379.0`, Linux x86_64. The upstream downloader verified
  SHA-256 `7529cc733d4a020e1c1369183b2f60e135c85b8f074bbf27d1476a5a7b3839c3`.
- Installation: `~/.local/share/nvim/intellij-lsp/server/263.6379.0/`.
- Analysis JDK: `NVIM_JAVA_HOME`, then `JAVA_HOME`, then
  `/usr/lib/jvm/java-21-openjdk-amd64`. The server runs on its bundled JBR.
- The user explicitly accepted the downloaded EAP agreement before
  `accept_eula=true` was enabled. EULA hash prefix: `34d850193ee04897`.
- [Downloaded agreement](/home/konkov/.local/share/nvim/intellij-lsp/server/263.6379.0/EULA.txt:1):
  internal evaluation, EAP term of 30 days from build release, subject to its
  termination provisions. An expired build may require a newer bundle.
- Upstream additionally documents the trial/subscription requirement in its
  [README](https://github.com/JetBrains/intellij-lsp.nvim#readme).

## Active Wiring

- The plugin loads at startup; Java is the only enabled source filetype for now.
- `nvim-java` and `neotest-java` are disabled. Generic Go/Python Neotest adapters remain.
- Startup explicitly disables JDTLS; legacy branch autocommands and runner
  re-enable paths are disconnected.
- `JavaInfo` reports backend, EULA state, bundle/path, JDK and attached client/root.
- Java rename and statusline client lookup target `intellij`.
- The repo wraps upstream's client factory to merge cmp/file-operation
  capabilities while preserving its IntelliJ extension capabilities.
- Upstream enables built-in completion even when `autotrigger=false`; the
  wrapper disables that client in Neovim's completion system after attach.
- Theme, Git, leader mappings, Enter, completion triggers, signature popup,
  folding, file templates, inlay-hint enablement, run/debug and format-on-save
  defaults are turned off where existing repo behavior or later steps own them.
- No backend selector or implicit JDTLS fallback is introduced.

## Temporary Workflow Gaps

- Main run/debug/stop/log actions: Step 5 pending.
- Remote attach: Step 6 pending.
- Java test adapter: Step 7 pending; scoped Java mappings report this before
  opening test UI. Direct Neotest commands have no Java adapter for now.
- Smart imports, field counters, branch/cache refresh: Step 8 pending.
- Project update was pending at this checkpoint; now implemented in [Step 3](intellij-lsp-step-3.md).
- These mappings/commands remain discoverable and report their pending state.
- Project creation, generic LSP navigation/actions, and existing formatting
  remain available. Full IntelliJ editing/import parity has not been tested yet.
- The daemon formatter is still configured; switching its routes is Step 4.
- Inactive JDTLS helper files/spec configuration remain as migration references
  until Step 9 cleanup; they are not registered or loaded by the new backend.

## Validation

- `make check`: StyLua and Selene pass with zero errors/warnings.
- Headless startup guard check: old runner/debug/remote/project/branch actions
  report pending steps; JDTLS remains disabled and Java/Java-DAP modules unloaded.
- Live server probe uses a disposable copy of the Step 1 Maven project, with
  session restore/save disabled and no ShaDa file writes.
- IntelliJ client initializes, reports `IntelliJ Language Server by JetBrains`,
  version `ILS-263.6379.0`, and resolves `Main` and `main` document symbols.
- Zero JDTLS clients; `vim.lsp.is_enabled("jdtls") == false`; `java` and
  `java-dap` modules are not loaded.
- `checkhealth intellij-lsp`: bundle, executable, JBR, version, EULA, Maven root
  and running server checks all pass. Import/indexing is still in progress at
  this checkpoint; complete workspace readiness is a Step 3 check.
- Restart Neovim to load this configuration into an existing editing session.
- Next: Step 3, editing/project-import/navigation checks and project refresh.
