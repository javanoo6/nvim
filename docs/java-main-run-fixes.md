# Java Main Run Fixes

Incident note for the Spring Petclinic `<leader>jr` failure investigated on
2026-06-08.

## Current Resolution

The durable local fixes are:

- `nvim-java` JDTLS client lookup is patched to prefer the `jdtls` client
  attached to the current buffer instead of the first global `jdtls` client.
- Mixed Maven/Gradle roots force Maven import on and Gradle import off.
- Those mixed-build import settings are injected into
  `initializationOptions.settings` before JDTLS startup, not only sent later via
  `workspace/didChangeConfiguration`.

Relevant code:

- [lua/plugins/nvim-java.lua](/home/konkov/.config/nvim/lua/plugins/nvim-java.lua:1)
- [lua/util/java_patches.lua](/home/konkov/.config/nvim/lua/util/java_patches.lua:1)
- [lua/util/java_runner.lua](/home/konkov/.config/nvim/lua/util/java_runner.lua:1)

## Original Symptom

In Spring Petclinic:

```text
/home/konkov/Desktop/playground/spring-petclinic/src/main/java/org/springframework/samples/petclinic/PetClinicApplication.java
```

Pressing `<leader>jr` appeared to do nothing.

The failure had two layers:

- With multiple Java workspaces open, `nvim-java` could pick a `jdtls` client
  from another workspace and show main classes from that project.
- In the Petclinic workspace, JDTLS initially imported the dual-build root as
  Gradle-first, so Java main-class discovery did not behave like the Maven
  project expected by this config.

## Root Cause

`nvim-java` used a global lookup equivalent to:

```lua
vim.lsp.get_clients({ name = "jdtls" })[1]
```

That is wrong when the current buffer has its own attached `jdtls` client.

For Spring Petclinic specifically, the root contains both `pom.xml` and
`build.gradle`. JDTLS chooses importers during initialization from
`initializationOptions.settings`. Settings sent later through
`workspace/didChangeConfiguration` are too late for the first import decision.

## Confirmed Behavior After Fix

- Petclinic imports as Maven-first.
- `vscode.java.resolveMainClass` resolves successfully.
- `<leader>jr` works through the normal `nvim-java` runner.
- Temporary fallback runners and debug instrumentation were removed.

## Upstream Notes

Useful upstream issue framing:

- `nvim-java` should prefer the current buffer's `jdtls` client for Java
  run/debug/test/profile/refactor flows.
- `nvim-java` should mirror startup-sensitive JDTLS settings into
  `initializationOptions.settings`, especially import preferences.
- JDTLS mixed-build import behavior is sensitive to whether settings are
  available during initialization.

## Historical Repro

Wrong workspace picker:

1. Open two Java workspaces in one Neovim session.
2. Edit a Spring Petclinic Java buffer.
3. Press `<leader>jr`.
4. Before the local patch, main classes from the other workspace could appear.

Mixed-build import issue:

1. Open Spring Petclinic from a clean JDTLS workspace.
2. Let JDTLS initialize with default mixed-build import ordering.
3. Main-class discovery could fail or hang before Maven-first import settings
   were delivered early enough.

## Local Maven Fallback

During investigation, this proved the app itself was runnable:

```bash
./mvnw -q -DskipTests -Dspring-javaformat.skip=true spring-boot:run
```

The fallback is not part of the final Neovim workflow.
