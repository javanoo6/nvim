# Java Lint Roadmap

Purpose: improve Java diagnostics in Neovim with Checkstyle, PMD, and SpotBugs
now.

Autocomplete is still primarily a JDTLS problem. These linters add style,
design, and bug diagnostics; they do not make completion smarter.

Future IntelliJ IDEA Community inspection-engine research is tracked separately
in [docs/java/java-intellij-inspection-engine-roadmap.md](/home/konkov/.config/nvim/docs/java/java-intellij-inspection-engine-roadmap.md:1).

## Current State

- JDTLS provides syntax, type, import, and project diagnostics.
- `nvim-lint` is already configured for other languages in
  `lua/plugins/linting.lua`.
- Java has no extra linter configured yet.
- Java formatting already uses the local IntelliJ formatter bridge.

## Immediate Tooling

Use these tools first:

- Checkstyle: style and convention checks.
- PMD: source-level static analysis for common bugs, complexity, and design
  smells.
- SpotBugs: bytecode-level bug detection after project compilation.
- Testcontainers: integration-test support for projects that need real
  dependencies in Docker containers.

Do not invent a global house ruleset. Prefer project-local configuration. Skip
tools quietly when config or executable support is missing.

## Automatic Diagnostics Policy

Run only lightweight current-file checks automatically.

- JDTLS remains the primary source for syntax, type, import, and classpath
  diagnostics.
- Checkstyle may run automatically on `BufWritePost` when a project config is
  found.
- PMD may run automatically on `BufWritePost` only if current-file performance
  is acceptable.
- SpotBugs stays manual because it needs compiled bytecode and can be slow.
- SonarLint can be evaluated for live diagnostics, but only after checking Java
  classpath integration with the current `nvim-java` setup.
- Testcontainers-based tests must stay manual or hook-driven; they should never
  run automatically on save.

This gives save-time diagnostics similar to IntelliJ IDEA's editor feedback,
but not identical: IntelliJ inspections are incremental and IDE-native, while
these tools run after save or by explicit command.

## Phase 1: Discovery Helpers

Create a small helper module, probably `lua/util/java_lint.lua`.

Expose:

- `:JavaLintInfo`
- `:JavaLintFile`
- `:JavaLintProject`

Discovery should report:

- current Java project root
- build tool: Maven, Gradle, or unknown
- Checkstyle config path
- PMD ruleset path
- SpotBugs task/plugin availability when detectable
- executable availability for `checkstyle`, `pmd`, and `spotbugs`

Acceptance checks:

- Missing tools/configs are reported clearly.
- Missing tools/configs do not emit noisy diagnostics during normal editing.
- The helper can be used before wiring anything into save-time linting.

## Phase 2: Checkstyle

Use Checkstyle for style and convention checks.

Config discovery:

- `checkstyle.xml`
- `config/checkstyle/checkstyle.xml`
- `src/checkstyle/checkstyle.xml`
- Maven/Gradle Checkstyle plugin config when easy to detect

Execution strategy:

- Prefer direct current-file invocation when a config exists.
- Use project root as cwd.
- Add diagnostics through `nvim-lint` if output parsing is stable.
- Otherwise put results into quickfix first, then promote to diagnostics later.

Expected command shape:

```sh
checkstyle -c <config> <file>
```

Acceptance checks:

- Runs only for Java buffers inside projects with Checkstyle config.
- Parses file, line, column, severity, and message.
- Does not duplicate JDTLS syntax/type diagnostics.

## Phase 3: PMD

Use PMD for source-level static analysis.

Config discovery:

- `pmd.xml`
- `ruleset.xml`
- `config/pmd/pmd.xml`
- `config/pmd/ruleset.xml`

Execution strategy:

- Prefer current-file lint when a ruleset exists.
- Use project root as cwd.
- Prefer a machine-readable report format when available.

Expected command shape:

```sh
pmd check --dir <file> --rulesets <ruleset> --format json
```

Acceptance checks:

- Runs only when a ruleset exists, unless an explicit default is later chosen.
- Parses diagnostics with stable locations.
- Can be triggered manually through `:JavaLintFile`.

## Phase 4: SpotBugs

Use SpotBugs for bytecode-level analysis.

Execution strategy:

- Treat SpotBugs as project lint, not live per-save lint.
- Prefer build-tool integration when configured:
  `mvn spotbugs:check`, `gradle spotbugsMain`, `gradle spotbugsTest`.
- Fall back to standalone `spotbugs` only when class/output paths are known.

Acceptance checks:

- `:JavaLintProject` can run SpotBugs after project build output exists.
- Results go to quickfix first.
- Save-time linting never runs SpotBugs.

## Phase 5: Pre-Push Hook Support

After manual SpotBugs works, add optional Git hook support so new code can be
checked before pushing.

Behavior:

- Provide a generated hook script or helper command, not an unconditional repo
  mutation.
- Run project-level checks suitable for pre-push:
  Checkstyle, PMD, tests if configured, and SpotBugs after compilation.
- Support Testcontainers-based integration tests when the project uses them and
  Docker is available.
- Prefer project build-tool tasks when available.

Acceptance checks:

- The hook is opt-in per repository.
- Hook output is readable in a terminal.
- The hook fails the push on high-confidence violations.
- Testcontainers checks are skipped clearly when Docker is unavailable.
- Slow checks are documented so they are not surprising.

## Phase 6: Testcontainers-Aware Test Commands

Add manual support for projects using `testcontainers-java`.

Why:

- Testcontainers is a Java library for JUnit tests that starts lightweight,
  throwaway Docker containers for dependencies such as databases, message
  brokers, browsers, or any Docker image.
- It is valuable for catching integration problems that linters cannot see.
- It can be slow and environment-dependent, so it should be explicit.

Detection:

- Maven dependencies containing `org.testcontainers`.
- Gradle dependencies containing `org.testcontainers`.
- Test source imports under `org.testcontainers`.

Commands:

- `:JavaTestcontainersInfo`
- `:JavaTestcontainersRun`

Behavior:

- Check Docker availability before running.
- Prefer build-tool commands over custom runners:
  Maven `test` / `verify`, Gradle `test` / `integrationTest` when configured.
- Reuse existing Neotest Java flows where possible instead of creating a
  parallel test runner.
- Keep output in terminal/test UI first; quickfix parsing can come later.

Acceptance checks:

- Projects without Testcontainers are ignored.
- Projects with Testcontainers report dependency and Docker readiness.
- Manual test command does not run on save.
- Future pre-push hook can include these tests only when explicitly enabled.

## Phase 7: SonarLint / SonarQube Plugin Evaluation

Evaluate these Neovim plugins before adding either:

- `iamkarasik/sonarqube.nvim`
- `alnav3/sonarlint.nvim`

Why evaluate:

- Both integrate with `sonarlint-language-server`.
- Java support depends on correct project/classpath information.
- This config already has a customized `nvim-java`/JDTLS setup, so SonarLint
  must not fight JDTLS or attach to the wrong project.

Evaluation criteria:

- Installs cleanly with Mason's `sonarlint-language-server` or its own installer.
- Supports Java diagnostics in Maven/Gradle projects.
- Can resolve Java classpaths through existing JDTLS / `nvim-java` state.
- Does not duplicate too much noise from JDTLS, Checkstyle, PMD, and SpotBugs.
- Does not require SonarQube server credentials for local analysis.
- Connected Mode is optional and stores credentials outside repo files.
- Exposes diagnostics through normal Neovim LSP diagnostics.

Initial preference:

- Try `sonarqube.nvim` first if we want the simpler, newer setup path.
- Try `sonarlint.nvim` if we need more direct control over analyzer jars,
  classpath wiring, or connected-mode behavior.

Acceptance checks:

- `:LspInfo` shows a separate SonarLint/SonarQube client only for supported
  filetypes.
- Java diagnostics appear for a real Maven/Gradle project.
- Diagnostics remain stable after reopening a Java buffer.
- Disabling the plugin leaves JDTLS behavior unchanged.

## Phase 8: nvim-lint Integration

Wire Checkstyle and PMD into `nvim-lint` only after command/output behavior is
stable.

Policy:

- Java save-time linting should include only fast current-file linters.
- Checkstyle can run on `BufWritePost` when config exists.
- PMD can run on `BufWritePost` only if performance is acceptable.
- SpotBugs remains explicit project lint.

Acceptance checks:

- `available_linters()` still skips missing executables.
- Java linting does not block editing in large projects.
- Diagnostics source names make it obvious whether an issue came from JDTLS,
  Checkstyle, PMD, or SpotBugs.

## Recommended Implementation Order

1. Add `lua/util/java_lint.lua` discovery helpers.
2. Add `:JavaLintInfo`.
3. Add Checkstyle manual file lint.
4. Add PMD manual file lint.
5. Add quickfix parsing for project lint output.
6. Add SpotBugs project lint through Maven/Gradle.
7. Add optional pre-push hook support.
8. Add Testcontainers-aware manual test commands.
9. Evaluate SonarLint/SonarQube Neovim plugins.
10. Wire Checkstyle and maybe PMD into `nvim-lint` save-time linting.
