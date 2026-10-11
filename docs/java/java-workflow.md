# Java Workflow

IntelliJ LSP owns Java editing, project import, navigation, and launch metadata.
The active spec is `lua/plugins/intellij-lsp.lua`, pinned to
`9cfad18005470e4187090013e08f92ec9e437219`. The configured server bundle is
`263.6379.0`; agreement acceptance is recorded in the spec. JDTLS and nvim-java
are not used. neotest-java supplies discovery and XML result reading through the
local IntelliJ bridge.

## Setup and health

Use `:JavaInfo` for the owning client, root, JDK, bundle, import progress, and
readiness. `:checkhealth intellij-lsp` checks the installed server.
`NVIM_JAVA_HOME` takes precedence over `JAVA_HOME` for the project JDK; the
server uses its bundled JBR. See [prerequisites](../core/prepequisites.md) and
[macOS setup](../core/macos-setup.md) for platform setup.

Maven and Gradle projects are supported. Roots with both build systems prefer
Maven unless explicitly configured otherwise. Workspace actions target the
client owning the source or build-file buffer, even after changing cwd.

## Editing and navigation

| Key / command                          | Action                                                         |
|----------------------------------------|----------------------------------------------------------------|
| `<leader>ci`                           | Import the symbol at the cursor using current diagnostic fixes |
| `<leader>cI`                           | Apply missing imports serially; prompt for ambiguous choices   |
| `<leader>ca` / `<A-CR>`                | Code actions through actions-preview                           |
| `<leader>cr`                           | Rename a symbol through the owning IntelliJ client             |
| `gR`                                   | References through Glance                                      |
| `gt`                                   | IntelliJ subtype hierarchy in attached Java buffers            |
| `:IntellijLspTypeHierarchy supertypes` | Supertype hierarchy                                            |
| `<leader>uh`                           | Toggle inlay hints                                             |

Command-only actions may have no diff preview. Completion uses nvim-cmp and
LuaSnip; IntelliJ SnippetTextEdit templates use Neovim's native snippet engine.
The plugin's built-in completion and global keymaps are disabled. Generic type
arguments remain visible in inlay hints.

New empty Java files offer Class, Interface, Record, Enum, Annotation, or
Exception templates. The project path determines package and name.
`:IntellijLspFileTemplate` opens the picker manually for an empty attached
buffer. Neo-tree `a` then `o` supports this through `util.java_file_templates`;
existing populated files and cancelled prompts do not trigger another picker.
Use symbol rename for class/method/variable changes and Neo-tree for file moves.
Upstream `:IntellijLspRename` is a separate file-rename feature and is disabled
by the current configuration.

## Projects and scratch files

`:JavaInitProject [dir]` / `<leader>ji` creates a Java 21 Maven or Gradle project,
opens `Main.java`, and changes cwd to the project root. Java scratch files stay
inside that project, preferring `src/test/java/Scratch.java`, then
`src/main/java/Scratch.java`. Outside a recognized project they fall back to the
global scratch directory. `:ScratchInfo` reports the selected paths.

`<leader>ju` / `:JavaProjectUpdate` reloads the owning workspace, including from
its Maven/Gradle build file. `:JavaBranchRefresh` explicitly reloads it after a
branch change. Java buffer/focus events reload after a detected Git HEAD change;
same-HEAD changes require explicit refresh.

`:JavaRestart` restarts only the owning workspace. `<leader>XC`, `<leader>XJ`,
and `:JavaCleanCorruptWorkspaces[!]` clear its index and restart it after checking
ownership and waiting for client exit. Other workspaces and installed bundles
remain. Upstream restart/cache commands have broader scope.

## Formatting

`<leader>cf`, format-on-save, and directory formatting use the standalone
IntelliJ formatter jar through Conform. Full-file Java requests optimize imports
and rearrange members; range requests omit those cleanup flags. The style file
is this Neovim config's `.editorconfig`. Formatting does not wait for LSP import.
Markdown, Python, XML, YAML, and shell also use the jar. `:FormatterInfo` reports
dependencies. Directory formatting is asynchronous and sequential;
`:FormatDirCancel` stops after its current request finishes.

## Run, tests, and limits

See [Java debugging](java-debugging.md), [Java tests](java-test-workflow.md),
and [LeetCode harnesses](java-leetcode-debugging.md).

Remote JVM attach is unavailable. Spring applications use ordinary JVM
launching; Spring-specific tooling is not configured. Field-usage counters are
not available; use references instead. Binary navigation can return an API stub
without method bodies when attached dependency sources are absent.

The pinned server's diagnostic selection has limits: unused declarations are
disabled, and several other inspections are disabled or informational. Project
inspection-profile overrides did not change the observed diagnostic selection.
Neovim display settings cannot add checks the server does not emit. No separate
Java Checkstyle/PMD/SpotBugs integration is configured. Use `<leader>xb` for buffer
diagnostics and `<leader>xx` for root diagnostics.

The local test bridge targets conventional Maven/Gradle JUnit projects. Custom
source sets and larger project-specific workflows require separate validation;
see the test guide for its specific limits. Local compatibility contracts live
in [compatibility patches](../core/compatibility-patches.md).
