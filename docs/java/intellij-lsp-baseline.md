# IntelliJ Migration — Step 1 Baseline

- Captured: 2026-10-10, before changing the Java runtime configuration.
- Config commit: `e7f72df7f18c57b7c71728b2ac1f3ea29a9646fa`, plus the existing working tree.
- Branch: `intelijidea_implementation`.
- Neovim: `0.12.2`; analysis/runtime JDK: `/usr/lib/jvm/java-21-openjdk-amd64`.
- Live JDTLS probe reports `1.54.0-SNAPSHOT`; installed package directory is `1.54.0`.
- Lockfile revisions: `nvim-java` `9e8b842ea9eff3ebf25fb7360908ed4d4f87c56a`,
  `neotest-java` `78d236da986cca4dd95cb10b1250c4c6e1508240`,
  `spring-boot.nvim` `218c0c26c14d99feca778e4d13f5ec3e8b1b60f0`.
- Microsoft Java debug plugin: `0.53.2` (installed java-debug package `0.58.3`).
- JUnit Console jar available: `6.0.3`; the Maven fixture uses JUnit `5.10.2`.
- IntelliJ plugin/server: not installed by this step.

## Dependency Inventory

| Area                    | Current wiring                                                                                                                                                                  | Migration action                                                                          |
|-------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| Startup                 | `lua/plugins/nvim-java.lua` calls `java.setup`, patches JVM args, configures/enables JDTLS; owns Lombok, tests, debug, Spring tools                                             | Replace spec and eliminate JDTLS enable paths                                             |
| Java environment        | `lua/config/options.lua` resolves/prepends Java home; sets `lspconfig_jdtls_enabled=false`                                                                                      | Keep Java resolution; retire obsolete flag/comment                                        |
| General LSP             | `lua/plugins/lsp.lua` excludes JDTLS from Mason auto-enable; Java rename explicitly selects `name="jdtls"`; Java attach wires usage/code lenses                                 | Adapt rename and attach hooks; retain generic diagnostic/navigation setup                 |
| Completion              | `lua/plugins/completion.lua` uses cmp/LuaSnip/LSP/signature sources; Java spec advertises cmp capabilities                                                                      | Preserve source/snippet behavior and avoid the plugin's competing completion UI           |
| Imports                 | `lua/util/java_imports.lua` selects JDTLS and parses action titles matching `Import '<symbol>' (...)`; invoked from `lua/config/keymaps.lua`                                    | Adapt both client selection and action interpretation                                     |
| Usage/code lenses       | `lua/util/java_field_usages.lua` selects JDTLS and requests references; `java_codelens.lua` renders standard lenses                                                             | Reuse standard operations where supported; replace attach gates                           |
| Runner                  | `lua/util/java_runner.lua` waits eight seconds, can call `vim.lsp.enable("jdtls")`, then calls `java.runner.built_in`                                                           | Replace run, stop, output and startup retry                                               |
| Main/remote debug       | `lua/util/java_debug.lua` uses `java-dap`, `dap.configurations.java`, and adapter type `java`; remote attach uses `hostName`/`port`                                             | Replace launch provider and adapter-specific attach fields                                |
| DAP UI                  | `lua/plugins/dap.lua` owns generic controls/UI/source-window routing                                                                                                            | Preserve generic controls; verify library-source routing with new URI schemes             |
| Runtime patches         | `java_jdtls.lua` sets `-Xms2G/-Xmx8G`; `java_patches.lua` prefers current-buffer JDTLS and guards Spring command errors                                                         | Retire JDTLS patches; preserve correct workspace selection in new backend                 |
| Project refresh         | `java_project_config.lua` sends `java.projectConfiguration.update`                                                                                                              | Replace `<leader>ju` / command with supported IntelliJ reload                             |
| Branch lifecycle        | `java_branch_refresh.lua`, registered by `lua/config/autocmds.lua`, stops clients and invokes `LspStart jdtls` after HEAD changes                                               | Replace before this path can start JDTLS again                                            |
| Cache/cleanup           | `java_jdtls_cache.lua` uses Eclipse log signatures and JDTLS workspace paths; keymaps also call `java.build.clean_workspace`                                                    | Retire Eclipse-specific cleanup; add IntelliJ equivalents separately                      |
| Statusline              | `lua/plugins/ui.lua` tests current-buffer JDTLS and global LSP progress                                                                                                         | Change client identification; retain minimal status indicator                             |
| File operations         | `lua/plugins/editor.lua` installs `nvim-lsp-file-operations`; Java spec advertises its capabilities                                                                             | Verify IntelliJ will/did-rename support and Neo-tree integration                          |
| Library navigation      | `lua/plugins/glance.lua` disables winbar for percent-encoded `jdt://` paths; DAP handles decompiled buffers                                                                     | Verify `jar:`/`jrt:` navigation before removing existing guards                           |
| Scratch                 | `lua/plugins/scratch.lua` prefers `src/test/java/Scratch.java`, then main sources, based on build roots                                                                         | Keep path policy; verify new server resolves test dependencies                            |
| Project creation        | `java_project_init.lua` generates Maven/Gradle Java 21 templates                                                                                                                | Backend-independent; retain                                                               |
| Formatting              | `lua/plugins/formatting.lua` invokes the daemon jar through Conform; `format_dir.lua` loads target buffers and registers `FormatterInfo`                                        | Migrate six routes; update directory/client readiness and status reporting                |
| Neotest                 | `lua/plugins/neotest.lua` constructs `neotest-java`; upstream client provider explicitly selects JDTLS                                                                          | Replace adapter coupling, not just plugin startup                                         |
| Neotest LSP commands    | Upstream compiler calls `java/buildWorkspace`; classpath provider calls `java.project.getClasspaths` for runtime/test; local binaries override calls `java.project.getSettings` | Need supported compiler/classpath/JDK replacements                                        |
| Neotest local overrides | `lua/neotest-java/` contains binaries, file checker, root finder, result builder, attach spec normalization                                                                     | Preserve behavior when changing adapter; attach wrapper currently targets DAP type `java` |
| Neotest UI/scope        | `lua/util/neotest_*` captures original source/cursor, filters roots, limits output, reruns failures, supports sequential execution                                              | Mostly backend-independent; regression checks remain necessary                            |
| Session restore         | `lua/plugins/sessions.lua` stops LSP clients on restore; Java setup can start from restored buffers                                                                             | Verify new server attaches after restore and does not duplicate workspaces                |

## Selected Project Matrix

| Role                                | Local project                                      | Baseline coverage                                                                                         |
|-------------------------------------|----------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| Small Maven / JUnit                 | `/home/konkov/Desktop/2aug/demo`                   | Temporary copy: offline Maven tests, main execution and live JDTLS protocol checks                        |
| Pure Gradle                         | `/home/konkov/Desktop/JNLR/DMDEV/spring-starter`   | Build inspected: Java plugin, JUnit 5.8.1, wrapper declaration 7.3; interactive import/run not checked    |
| Mixed Maven/Gradle / Spring Boot    | `/home/konkov/Desktop/playground/spring-petclinic` | Both build files present; Maven Java 17; current config explicitly prefers Maven; runtime checks deferred |
| Multi-module / Spring Boot / Lombok | `/home/konkov/Desktop/tmp/cloud-platform`          | Parent lists ten modules, Java 21, Lombok 1.18.40; runtime/service tests deferred                         |
| Formatting                          | Disposable six-language snippets                   | Comparison findings recorded below; raw fixtures removed during cleanup                                   |

- System Gradle is `4.4.1`, running under JDK 21. Do not use it as a modern
  Gradle project baseline: use a suitable project wrapper and record its version.
- Existing service projects may need credentials, repositories, databases or
  containers. Their successful import or execution is not established here.
- Project discovery is read-only. Builds and source-changing probes use a
  temporary Maven copy; original project sources are not edited.

## Recorded Behavior

| Feature                     | Evidence / result                                                                                                                                                     | Limit                                                                                                             |
|-----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| Attachment                  | JDTLS initializes on the temporary Maven root, reports 1.54.0-SNAPSHOT                                                                                                | One workspace tested                                                                                              |
| Completion                  | Protocol response includes `System` members such as `out`, `err`, `in`                                                                                                | Completion UI/snippet acceptance not exercised                                                                    |
| Hover/symbols               | `Main` hover resolves; document symbols include package, class and main method                                                                                        | Dependency navigation not exercised                                                                               |
| Rename                      | Response renames `Main` to `BaselineMain` and includes the `.java` file rename                                                                                        | Edits requested but deliberately not applied; Neo-tree move not tested                                            |
| Main discovery              | `vscode.java.resolveMainClass` resolves `com.example.demo.Main`, project `demo`                                                                                       | Not a Spring launch check                                                                                         |
| Classpath                   | `java.project.getClasspaths` resolves main/test output and JUnit dependency jars                                                                                      | Uses JSON-encoded options, as adapter expects                                                                     |
| Clean diagnostics           | Original `Main.java` has no diagnostics in the live probe                                                                                                             | Error/import diagnostic probe recorded separately below                                                           |
| Error diagnostics / imports | Unsaved `ArrayList` references produce two unresolved-type errors; action response offers organize imports and add-all-missing-imports                                | Actions requested with empty diagnostic context; smart-import title matching/application not exercised            |
| Main execution              | `java -cp target/classes com.example.demo.Main` exits 0 with `Hello from Java`                                                                                        | CLI check, not `<leader>jr` runner/UI verification                                                                |
| Main DAP launch             | Generated `demo -> com.example.demo.Main` config launches with `stopOnEntry=true`; DAP receives stopped event and has an active session; session terminated afterward | Headless protocol check, not breakpoint/stepping/variables/UI or Spring workflow verification                     |
| JUnit                       | `mvn -o test` exits 0: 2 tests, 0 failures/errors/skips                                                                                                               | Maven results are distinct from Neotest results                                                                   |
| Neotest attempt             | Headless run reports `No tests found`, no cached results within 20 seconds                                                                                            | Discovery/consumer initialization needs investigation; this does not establish that interactive Neotest is broken |
| Remote attach               | Config currently prompts for host/port and uses Java adapter attach                                                                                                   | No external JVM attached during baseline; runtime coverage remains open                                           |
| Formatting                  | Six jar routes attempted twice; Java/XML/Markdown changed; all outputs stable on the second call                                                                      | Python/YAML/shell returned 0 without changing malformed samples                                                   |

- Headless probe imports the repo plugin specs and options/keymaps/autocmds,
  disables auto-session to avoid altering saved sessions, disables automatic
  formatting, uses `-i NONE`, and sends requests directly to the attached client.
- The first probe used an incorrectly shaped classpath options argument and
  timed out before collecting its result. That error is a probe mistake, not a
  configuration regression. The corrected probe JSON-encodes options and passes.
- The first extended probe used an unavailable `neotest.state.results` API.
  The corrected attempt reads results from Neotest's internal client, as our
  failed-test helper does; it completes and records the discovery gap above.
- UI interactions, source navigation, project lifecycle, parameterized/failing
  test mapping and external remote JVM attach still need targeted checks during
  migration; documented support is not counted as a runtime pass.

## Formatter Comparison Artifacts

- Invocation matches the configured flags: `java -jar <formatter-cli-full.jar>
  --format --optimize-imports --rearrange --editorconfig <repo>/.editorconfig <file>`.
- Java sample: removes unused `Map`, sorts imports, reformats, and moves the
  field and constructor before methods. This establishes all three requested
  operations on this fixture, not arbitrary code-style parity.
- Jar SHA-256: `f3660e5b052019acded62d2e5f41f9c2b554d0100653d33676d27f96f59e183b`.
- `.editorconfig` SHA-256: `1f6940861a913db4a6304a1976dd8ad667ec1819f6b0cb5b1547b7e4fd36cbe7`.
- Formatter submodule HEAD observed: `085e2565fe3c9f1c171850f54ec1b92faf7487f5`.
- A route's presence and exit code are not proof of language formatting support.
  Step 4 must demonstrate meaningful edits for Python, YAML and shell as well.

## Implementation Priority

- Step 2 must handle plugin startup, Java-specific rename selection, runner
  re-enable, branch refresh and unconditional command registration together.
  Unimplemented actions should report their status without loading JDTLS.
- Preserve generic completion, file operations, DAP UI, Neotest scope/output,
  project creation and scratch path helpers where possible.
- Formatting coverage and test classpath/compile support are independent gaps;
  Java editing success does not close either of them.
