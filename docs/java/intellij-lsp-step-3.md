# Step 3 — Editing, Project Import and Navigation

- Completed: 2026-10-10. Plugin/server revisions remain those recorded in Step 2.
- Checks use disposable fixtures, with saved-session restore disabled. The
  user's `cloudos` source files were not changed.

## Changes

- `JavaProjectUpdate` and `<leader>ju` call `intellij/reloadWorkspace` on the
  client owning the source buffer or build-file path. This differs from upstream
  `IntellijLspReload`, which reloads every IntelliJ client.
- Mixed roots containing `pom.xml` and Gradle markers explicitly select Maven.
  The selection is local to that root and is reapplied during reload; it does
  not force Maven on Gradle-only projects or override an explicit build-tool option.
- Existing cmp/snippet/file-operation capabilities remain merged with the
  plugin's extension capabilities. Built-in LSP completion remains disabled.
- Server follow-up `triggerSuggest` commands use nvim-cmp; follow-up rename
  selects the IntelliJ client. Signature follow-ups keep the standard LSP popup.
- `JavaInfo` reports progress and whether the initial import/index flush finished.
  Later indexing rounds can still occur after that flag becomes true.
- Existing actions-preview and Neo-tree file-operation integration work without
  replacing their UI. Command-only intentions still have no diff preview.

## Live Checks

| Fixture / operation                   | Result                                                                                                                                        |
|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| Maven, Commons Lang 3.17.0            | Ready notification received; project/dependency completion and hover resolve                                                                  |
| Gradle 8.14 wrapper                   | Ready notification received; sibling source and dependency source navigation resolve; no source diagnostics                                   |
| Mixed Maven/Gradle                    | Init options explicitly choose Maven; dependency/source resolution passes                                                                     |
| Two-module Maven reactor              | Root widens from app to parent; app resolves sibling library source and external dependency                                                   |
| Cross-module method rename            | Renaming library `greet` to `welcome` updates declaration and app reference                                                                   |
| Spring Context 6.2.1 / Lombok 1.18.40 | `@Component` resolves to dependency source; generated `getValue()` resolves to model field; no source errors                                  |
| References / inlay hints              | Method references include caller; parameter/type hints returned                                                                               |
| Method rename in one module           | Declaration and call site update correctly                                                                                                    |
| Package move                          | Neo-tree's will/did-rename callback path updates package and caller import when Helper moves to `sample.moved`                                |
| Completion import                     | ArrayList completion and resolve include `import java.util.ArrayList`; applying those edits adds the import                                   |
| Diagnostic / quick fix                | Missing ArrayList emits unresolved-symbol diagnostics; actions-preview preview leaves text unchanged; applying `Import class` adds its import |
| Generated method                      | Applying `Create method 'unknownNumber' in 'Main'` through actions-preview inserts a valid method returning int                               |
| Source navigation                     | `jar:` attached Commons sources open as Java source (9,602 lines)                                                                             |
| Binary navigation                     | Binary StringUtils class URI opens a 572-line IntelliJ API decompiler stub                                                                    |
| Project reload                        | Source-buffer reload and `pom.xml`-buffer reload both complete without errors                                                                 |

## Additional UI/Protocol Checks

- A two-client regression probe confirms a build-file reload selects only the
  owning workspace and leaves global options unchanged.
- Representative `chooseAction` payload selects and dispatches the chosen
  command; representative conflict payload returns cancel through the plugin UI.
  These are synthetic protocol checks, not naturally occurring server conflicts.
- Follow-up rename dispatch is restricted to IntelliJ, and suggestion dispatch
  calls cmp only in insert mode.
- A representative SnippetTextEdit expands `int value = 0;` to
  `int result = 0;` and activates Neovim's native snippet session. The real
  generated-method action above inserted plain text and did not activate a
  template or request a follow-up rename.
- LSP completion snippets use the existing LuaSnip configuration. Tests cover
  advertised capabilities and returned edits; a physical keyboard completion
  acceptance cycle and every possible intention are not claimed as runtime checks.
- `make check` and `git diff --check` pass.

## Limits and Follow-Up

- The binary navigation result is an API stub: it explicitly says method
  implementations are unavailable. This is not full method-body decompilation.
- Spring/Lombok checks cover annotation/generated-member resolution, not
  Spring Boot bean navigation, application profiles or framework-specific inspections.
- Large `cloudos` import/refactoring behavior is not established by these small
  fixtures; the user has confirmed attachment to that root.
- Native UI selection and Neo-tree callback paths are checked independently of
  manually clicking through their windows. Complex refactor variants/conflicts
  should be checked on real projects when encountered.
- Initial extension-probe runs had a Lua syntax error in temporary test code;
  they are excluded from product results. The corrected probe was syntax-checked
  first and completed successfully. No server cache failure was established.
- Smart import keys (`ci` / `cI`) remain Step 8 work. Completion-added imports
  and normal code-action imports already work.
- Run/debug, remote attach and Java tests remain pending Steps 5–7.
- Formatting remains on the daemon jar; Step 4 is next.
- Restart Neovim to load the new helper/extension dispatch behavior.

## Server Agreement and Community Sources

- `accept_eula=true` passes the downloaded agreement's acceptance hash to the
  server launcher. It does not activate a subscription or disable build expiry.
- The plugin is open source; its downloaded server is a separate product with
  separate terms, as documented in the upstream README and downloaded EULA.
- The user-linked Community revision's README documents building the open-source
  IDE/platform. A standalone compatible `intellij-server` build target was not
  established from that revision. Reusing Community engines would require a
  separately verified LSP/project-import bridge, not just changing this option.
- References: [plugin README](https://github.com/JetBrains/intellij-lsp.nvim#readme),
  [launcher](https://github.com/JetBrains/intellij-lsp.nvim/blob/9cfad18005470e4187090013e08f92ec9e437219/lua/intellij-lsp/launch.lua),
  [Community revision README](https://github.com/JetBrains/intellij-community/blob/bfcc8d73f9255f476efa048f487aebfbfd615dad/README.md).
