# Java Test Workflow

Snapshot of the Java run/debug/test workflow after the local Java helper work.

## Current Split

- `nvim-java` owns JDTLS and Java-aware run/test operations.
- `nvim-dap` owns app debugging, breakpoints, stepping, UI, and remote attach.
- `neotest` owns test tree visibility plus file/package/nearest test workflows.

This split avoids forcing every Java action through one plugin.

## Java App Workflow

| Key          | Action                     | Implementation                    |
|--------------|----------------------------|-----------------------------------|
| `<leader>jr` | Run main/Spring Boot app   | `util.java_runner.run_main()`     |
| `<leader>jd` | Debug main/Spring Boot app | `util.java_debug.debug_main()`    |
| `<leader>jc` | Stop running app           | `util.java_runner.stop_main()`    |
| `<leader>jl` | Toggle runner logs         | `util.java_runner.toggle_logs()`  |
| `<leader>ja` | Attach remote JVM          | `util.java_debug.attach_remote()` |

Relevant files:

- [lua/plugins/lsp.lua](/home/konkov/.config/nvim/lua/plugins/lsp.lua:1)
- [lua/util/java_runner.lua](/home/konkov/.config/nvim/lua/util/java_runner.lua:1)
- [lua/util/java_debug.lua](/home/konkov/.config/nvim/lua/util/java_debug.lua:1)

## Test Workflow

Java-specific test actions are provided by `nvim-java`; broader test navigation
and package/file flows are provided by `neotest`.

Primary test mappings live in:

- [lua/plugins/neotest.lua](/home/konkov/.config/nvim/lua/plugins/neotest.lua:1)

Use this rule of thumb:

- Method/class Java actions: prefer `nvim-java` when exposed.
- Tree, file, package, watch, and output workflows: prefer `neotest`.
- Breakpoints and stepping after a debug launch: use generic `<leader>d*` DAP
  mappings.

## Testcontainers QoL

Testcontainers support is planned as a manual/project test workflow, not a
save-time lint workflow.

Target commands:

- `:JavaTestcontainersInfo`: report whether the current project uses
  `org.testcontainers` dependencies/imports and whether Docker is available.
- `:JavaTestcontainersRun`: run the appropriate Maven/Gradle test task for
  Testcontainers-backed integration tests.

Rules:

- Do not run Testcontainers tests automatically on save.
- Prefer Maven/Gradle or existing Neotest Java flows instead of creating a
  parallel test runner.
- Future pre-push hooks may include Testcontainers checks, but only when
  explicitly enabled for that repository.

Detailed planning lives in
[docs/java-inspection-lint-roadmap.md](/home/konkov/.config/nvim/docs/java-inspection-lint-roadmap.md:178).

## Remote JVM Attach

`<leader>ja` prompts for host and port, defaulting to local JDWP-style attach.

Typical JVM flag:

```bash
-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
```

## Remaining Improvements

- Document one canonical Java workflow in `docs/java-debugging.md`.
- Keep `docs/crash-course.md` and `docs/plugin-map.md` aligned with the actual
  keymaps.
- Validate the full loop in a real Spring Boot project after any `nvim-java`,
  JDTLS, or Java debug bundle update:
  run app, debug app, run test, debug test, attach remote JVM.
