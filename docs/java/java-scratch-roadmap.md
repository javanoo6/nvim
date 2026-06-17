# Java Scratch Roadmap

Purpose: move Java scratch behavior toward IntelliJ-like external scratch files
without losing the project-aware autocomplete that JDTLS provides today.

Primary goal: improve autocomplete and project-aware editing for scratch Java
files. JDTLS workspace/classpath correctness is the main constraint.

## Current State

- Java LSP is owned by `nvim-java` / JDTLS.
- Java scratch files currently prefer project-local source roots:
  `src/test/java/Scratch.java`, with `src/main/java/Scratch.java` as fallback.
- This gives JDTLS a normal Maven/Gradle source-root file, so completion,
  imports, diagnostics, run, and debug have real project context.
- The downside is that scratch files live inside the repository and can be
  compiled or accidentally committed.

## Target Model

- Store Java scratch files outside repositories under:

```text
stdpath("state")/scratch/java/<project-key>/<module-or-project>/...
```

- Associate each scratch directory with a real Maven/Gradle project or module.
- Use JDTLS workspace commands to attach, inspect, compile, and run scratches
  against the selected project context.
- Keep the current project-local scratch path as a fallback until external
  scratches can provide comparable autocomplete.

## Phase 1: JDTLS Capability Probe

Add a small debug/helper module, probably `lua/util/java_scratch.lua`, and expose
inspection commands before changing the default scratch behavior.

Commands:

- `:JavaScratchJdtlsInfo`
- `:JavaScratchClasspaths`
- `:JavaScratchSourcePaths`

Probe these JDTLS workspace commands:

- `java.project.getAll`
- `java.project.getClasspaths`
- `java.project.listSourcePaths`
- `java.project.addToSourcePath`
- `java.project.removeFromSourcePath`
- `vscode.java.resolveClasspath`

Acceptance checks:

- We can identify the JDTLS project/module attached to the current Java buffer.
- We can resolve runtime/test classpaths for that project/module.
- We know whether JDTLS accepts an external scratch directory via
  `java.project.addToSourcePath`.
- Failure cases are visible through `:JavaScratchJdtlsInfo`, not silent.

## Phase 2: Scratch Project State

Persist scratch associations outside repositories.

State file:

```text
stdpath("state")/java-scratch/projects.json
```

State shape:

```json
{
  "/abs/project/root": {
    "project_name": "jdtls-project-or-module",
    "scratch_dir": "/abs/state/scratch/java/project-key/project-name",
    "source_strategy": "external-source-path"
  }
}
```

Commands:

- `:JavaScratchSelectProject`
- `:JavaScratchClearProject`
- `:JavaScratchInfo`

Acceptance checks:

- Project selection survives Neovim restart.
- `:JavaScratchInfo` reports project root, JDTLS project/module, scratch dir,
  source strategy, and classpath availability.
- State writes never touch project files.

## Phase 3: External Scratch Files

Implement external Java scratch open/create.

Commands:

- `:JavaScratchOpen`
- `:JavaScratchNew [name]`
- Existing `<leader>fs` Java choice may call this once stable.

Default file:

```text
stdpath("state")/scratch/java/<project-key>/<module>/Scratch.java
```

Initial template:

```java
class Scratch {
    public static void main(String[] args) {
    }
}
```

Acceptance checks:

- Opening a scratch never creates files in the project repository.
- Scratch buffers get `filetype=java`.
- Existing `:ScratchInfo` either delegates to `:JavaScratchInfo` for Java or
  includes the same Java scratch details.

## Phase 4: Autocomplete Strategy

Try strategies in this order.

### Strategy A: External Source Path

Use `java.project.addToSourcePath` to add the external scratch directory to the
selected JDTLS project/module.

Acceptance checks:

- Completion sees project classes and dependencies.
- Organize imports works.
- Diagnostics use the selected project classpath.
- Removing/clearing the scratch project removes the source path if JDTLS allows
  it.

### Strategy B: Ignored Project Mirror

If external source paths do not give good completion, mirror or symlink external
scratch files into an ignored project directory such as:

```text
src/test/java/.nvim-scratch/
```

This is less clean, but it gives JDTLS a normal source-root path.

Acceptance checks:

- `.nvim-scratch/` is ignored via `.git/info/exclude` by default.
- External state remains the source of truth where possible.
- Completion matches normal test-source files.

### Strategy C: External Only

If source-path attachment and mirroring are both unsuitable, keep scratches
external and accept reduced LSP support. Run/compile still uses generated
classpath.

Acceptance checks:

- The degraded mode is explicit in `:JavaScratchInfo`.
- Run still works through generated classpath.

## Phase 5: Run and Debug

Add `:JavaScratchRun`.

Implementation outline:

- Resolve project classpath from JDTLS.
- Compile scratch classes into:

```text
stdpath("cache")/java-scratch/classes/<project-key>/<module>
```

- Run with:

```sh
java -cp "<project-output>:<dependencies>:<scratch-classes>" Scratch
```

Later add `:JavaScratchDebug` by generating a temporary DAP launch config.

Acceptance checks:

- Scratch can run against project dependencies.
- Compile output is outside the repo.
- Errors are shown in a quickfix-friendly form if practical.
- Debug support is added only after run behavior is reliable.

## Phase 6: Package-Aware Scratch

Add package-local scratch support for cases where package-private access matters.

Commands:

- `:JavaScratchNewPackageLocal [name]`

Behavior:

- Derive package from current Java buffer.
- Create a matching package path under the scratch strategy in use.
- Add `package ...;` to the template.

Acceptance checks:

- Package-local scratch can access package-private project types when the
  selected strategy supports it.
- Default scratch stays package-less for quick experiments.

## Recommended Implementation Order

1. JDTLS capability probe.
2. External scratch state and `:JavaScratchInfo`.
3. External scratch open/create.
4. Autocomplete strategy A, then B only if needed.
5. `:JavaScratchRun`.
6. Package-aware scratches.

