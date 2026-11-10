# Configuration architecture and quality audit

Date: 2026-11-10. Status: independently reviewed; targeted corrections implemented, broader work deferred.

## Scope and evidence

This records the initial audit and provides a tracker for its recommendations.
It is not a completed line-by-line review of the entire repository. Inspected
areas include initialization, options/autocommands, LSP, completion, formatting,
linting, Treesitter, dependency declarations, the lockfile, and compatibility
documentation. Custom helpers and interactive workflows remain partly unverified.

Checks performed during the audit:

- Installed Neovim reported 0.12.2.
- `make check-format` passed.
- `make check-lint` failed on `tests/markdown_images.lua:70`:
  Selene rejects `io.stderr:write` under the configured standard library.
- Repository status was unchanged; an existing untracked `doc/` directory remained.
- No full regression run, real LSP/debugger session, startup benchmark, formatter
  benchmark, or clean installation was performed.

Line references below describe the audit baseline and may drift after changes.
Implementation status is recorded in the Open work and Completed sections.

## Tracking rules

- Check a fix only after implementation and its verification checkpoints pass.
- Check an investigation once evidence and a decision are recorded; a decision
  to retain current behavior can close an investigation.
- Preserve item IDs in commits or follow-up notes for traceability.
- Record completion date, commit, validation, and any remaining limitations in
  the change log at the end of this document.
- If an item is rejected or deferred, record the reason instead of silently
  deleting it. Checkbox completion alone does not mean code was changed.
- Priorities: P0 correctness/reliability, P1 high-impact simplification,
  P2 maintainability, P3 optional measurement or enhancement.
- Confidence: Confirmed means observed code behavior or executed evidence;
  Likely and Needs verification are not established runtime defects.

## Overall assessment

The top-level architecture is appropriate. Startup is explicit:
`init.lua → config.options → config.lazy → config.keymaps → config.autocmds`.
Lazy imports feature-oriented specifications from `lua/plugins/`.

The largest maintenance burden is the custom integration layer: Java, Neotest,
sessions, and UI recovery depend on private APIs, closure upvalues, shadowed
modules, or replaced consumers. The compatibility registry and regression
coverage are strong safeguards, but do not make those contracts stable.

Keep the existing structure. Prefer small corrections and retiring individual
patches over a rewrite, generic language framework, or indiscriminate lazy loading.

## Open work and verification

Implemented portions are recorded under Completed at the bottom. These unchecked
items retain only the remaining work; they do not request reimplementation.

### P0 — Correctness and reliability

- [ ] **AUD-01:** Force a Markdown image test failure and verify its error output
  and nonzero exit. The lint fix and passing suite are complete.
- [ ] **AUD-02:** Verify Neovim API completion in a live LuaLS session. Flat library
  paths and project-local settings precedence already have regression coverage.
- [ ] **AUD-03:** Verify live server attachment: IntelliJ alone for Java even with
  JDTLS installed, Python selection/refactoring, and other intended languages.
  JDTLS exclusion is implemented; an activation allowlist was rejected.

### P1 — Formatting policy verification

- [ ] **AUD-04:** Verify manual save/autosave with LSP-only and linter-only errors,
  plus explicit manual formatting. Preserve the existing all-diagnostics rule;
  only its description and warning were corrected.

### P2 — Maintainability and observability

- [ ] **AUD-07:** Complete the regression entrypoint inventory. Every test should
  have an invocation or reason for exclusion. Markdown image checks are now in
  `make check-config`; the resulting standard targets pass.
- [ ] **AUD-09:** Force actions-preview setup/invocation failure and verify that
  warnings retain the cause and native code actions still work.

## Deferred investigations

- **AUD-06 — Compatibility patches:** retain current patches. No supported
  replacement or upstream update was established. During upgrades, use the
  [patch registry](../core/compatibility-patches.md), reproduce failures without
  each patch, and retire only proven unnecessary fixes. Complete applicable
  interactive smoke checks before accepting replacements.
- **AUD-08 — RuboCop availability cache:** cached failures survive environment
  repair. Restarting is the current recovery path. Defer invalidation machinery
  or repeated synchronous probes until this causes practical workflow trouble.
- **AUD-11 — Save latency:** ten-second formatter budgets and autosave on buffer
  leave/focus loss are confirmed paths, not measured performance defects. Measure
  warm/cold formatting and navigation before changing automatic-save budgets.
- **AUD-12 — Startup/runtime profiling:** measure repeated empty/project startup,
  first and many-buffer completion, large-file highlighting, and filesystem root
  lookup costs before adding caches, cutoffs, or loading mechanisms.

Suggested profiling commands (output outside the repository):

```sh
nvim --startuptime /tmp/nvim-empty-startup.log
nvim --startuptime /tmp/nvim-project-startup.log path/to/representative/file
```

Use `:Lazy profile` too. Separate first launches from warm runs and session
restoration from ordinary startup. No performance problem was measured here.

## Rejected changes and retained behavior

- **AUD-03, broader allowlist:** reject changing activation for unrelated installed
  servers without evidence. The narrow JDTLS exclusion addresses Java ownership.
- **AUD-05, remove bundled Node fallback:** reject for this environment. Session
  context documents that system Node 18 lacks regex support required by the
  installed Markdown linter. Removing the fallback would regress functionality;
  a supported Node upgrade can justify revisiting this coupling later.
- **AUD-10, utility-module extraction:** reject for this change. Moving root and
  explorer state adds import churn without a demonstrated practical benefit.
- **AUD-13, plugin removals/presentation changes:** reject changes based solely on
  apparent overlap. Usage evidence is unavailable; preserve current workflows.

## Plugin disposition baseline

These are initial recommendations, not usage measurements or completed plugin
validation. Related plugins share rows; all audit lockfile entries are represented.
Use AUD-13 for discretionary removals and AUD-06 for private-contract changes.

| Plugins                                                                                                    | Purpose / concern                                                             | Action                               |
|------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------|--------------------------------------|
| lazy.nvim                                                                                                  | Plugin loading; custom event uses internals                                   | Keep                                 |
| mason.nvim, mason-lspconfig.nvim, mason-tool-installer.nvim                                                | Tool installation and activation; overlapping declarations                    | Simplify configuration               |
| nvim-lspconfig                                                                                             | Maintained server definitions                                                 | Keep                                 |
| intellij-lsp.nvim                                                                                          | Java; substantial integration coupling                                        | Keep                                 |
| spring-boot.nvim                                                                                           | Spring dependency/integration; usage requires verification                    | Keep provisionally                   |
| nvim-lsp-file-operations, fidget.nvim                                                                      | File operations and progress                                                  | Keep                                 |
| nvim-cmp                                                                                                   | Completion owner                                                              | Keep                                 |
| cmp-nvim-lsp, cmp-path, cmp-cmdline, cmp_luasnip                                                           | Distinct completion sources                                                   | Keep                                 |
| cmp-buffer                                                                                                 | Buffer words; indexing patch and broad buffer scope                           | Simplify configuration               |
| cmp-nvim-lsp-signature-help                                                                                | Signature completion                                                          | Keep                                 |
| LuaSnip, friendly-snippets, lspkind.nvim                                                                   | Snippets and completion presentation                                          | Keep                                 |
| conform.nvim                                                                                               | Formatting owner                                                              | Keep                                 |
| nvim-lint                                                                                                  | Additional diagnostics; Node coupling                                         | Simplify configuration               |
| nvim-treesitter, nvim-treesitter-textobjects, rainbow-delimiters.nvim                                      | Parsing, objects, delimiter display                                           | Keep                                 |
| Comment.nvim, nvim-ts-context-commentstring                                                                | Context-aware commenting                                                      | Keep                                 |
| mini.ai, mini.surround, nvim-autopairs, better-escape.nvim                                                 | Editing conveniences                                                          | Keep                                 |
| telescope.nvim, telescope-fzf-native.nvim                                                                  | Shared picker/search stack                                                    | Keep                                 |
| neo-tree.nvim, nvim-window-picker                                                                          | Tree navigation; custom cwd/preview behavior                                  | Simplify configuration               |
| oil.nvim                                                                                                   | Editable directory workflow                                                   | Keep                                 |
| harpoon, project.nvim                                                                                      | Frequent files and project history                                            | Keep                                 |
| flash.nvim, nvim-spider, nvim-treehopper                                                                   | Different navigation models                                                   | Keep                                 |
| aerial.nvim, glance.nvim                                                                                   | Outline and navigation preview; Glance fork                                   | Keep                                 |
| actions-preview.nvim                                                                                       | Code-action diffs; elaborate custom presentation                              | Simplify configuration               |
| trouble.nvim, quicker.nvim, tiny-inline-diagnostic.nvim                                                    | Lists, editable quickfix, wrapped diagnostics                                 | Keep                                 |
| gitsigns.nvim, diffview.nvim, lazygit.nvim, git-conflict.nvim                                              | Complementary Git workflows                                                   | Keep                                 |
| nvim-dap, nvim-dap-ui, nvim-dap-virtual-text                                                               | Shared debugging stack                                                        | Keep                                 |
| nvim-dap-go, nvim-dap-python                                                                               | Language debugging adapters                                                   | Keep                                 |
| neotest                                                                                                    | Test orchestration; private consumers/client integration                      | Simplify configuration incrementally |
| neotest-java, neotest-golang, neotest-python                                                               | Test adapters; preserve scope behavior                                        | Keep                                 |
| nvim-nio, FixCursorHold.nvim                                                                               | Dependency roles; verify graph before removal                                 | Keep                                 |
| gopher.nvim, venv-selector.nvim                                                                            | Go helpers and Python environment selection                                   | Keep                                 |
| auto-session, persist-toggle.nvim                                                                          | Sessions and durable preferences                                              | Keep                                 |
| auto-save.nvim                                                                                             | Saving policy interacts with synchronous formatting                           | Simplify configuration               |
| bufferline.nvim, lualine.nvim, which-key.nvim                                                              | Navigation/status/discovery; private patches and root work                    | Keep                                 |
| noice.nvim, nvim-notify, dressing.nvim                                                                     | Different message/prompt responsibilities                                     | Keep                                 |
| indent-blankline.nvim, vim-illuminate                                                                      | Visual context; measure large files                                           | Keep                                 |
| toggleterm.nvim, yanky.nvim, marks.nvim, undotree                                                          | Terminal/history/navigation conveniences                                      | Keep                                 |
| grug-far.nvim, todo-comments.nvim, scratch.nvim                                                            | Replacement, TODOs, scratch workflows                                         | Keep                                 |
| obsidian.nvim, md-render.nvim, leetcode.nvim                                                               | Specialized workflows and external dependencies                               | Keep                                 |
| plenary.nvim, nui.nvim, nvim-web-devicons                                                                  | Reused dependencies                                                           | Keep                                 |
| themery.nvim, tokyonight.nvim                                                                              | Theme persistence and default theme                                           | Keep                                 |
| evergarden, jb.nvim, kanagawa.nvim, nordic.nvim, onenord.nvim, oxocarbon.nvim, poimandres.nvim, vague.nvim | Optional alternative themes; lazy themes are not a demonstrated startup issue | Consider removing unused choices     |

## Leave as is — preservation checkpoints

These checked items record audit recommendations to preserve existing design;
they are not claims of new implementation or exhaustive runtime validation.

- [x] **KEEP-01:** Keep the short, explicit initialization sequence.
- [x] **KEEP-02:** Keep feature-oriented plugin specifications and current top-level
  directories; no wholesale restructuring.
- [x] **KEEP-03:** Keep Conform as the single formatting owner, including autosave.
- [x] **KEEP-04:** Keep central persistent preference ownership.
- [x] **KEEP-05:** Keep compatibility reproductions, revision tracking, and explicit
  patch-removal criteria.
- [x] **KEEP-06:** Preserve project/cwd policy and session workspace boundaries.
- [x] **KEEP-07:** Preserve distinct Oil and Neo-tree workflows unless actual usage
  demonstrates one is unnecessary.
- [x] **KEEP-08:** Keep modern native LSP configuration APIs and maintained server
  definitions; do not hand-copy every server configuration.
- [x] **KEEP-09:** Keep narrow helpers where they isolate real workflows; do not
  merge them solely to reduce file count.
- [x] **KEEP-10:** Preserve Java requirements and read `docs/java/java-workflow.md`
  before modifying Java LSP, scratch, or Neotest integration.
- [x] **KEEP-11:** Preserve standard `h/j/k/l` directions and aligned plugin mappings.
- [x] **KEEP-12:** Keep the distinction between structural tests and interactive
  LSP/debugger acceptance checks.

## Remaining audit coverage

- [ ] **COVER-01:** Read remaining custom helpers and scripts in full; inspect
  interactions beyond the initial sampled paths.
- [ ] **COVER-03:** Validate Java, Python, Go, and Ruby interactive workflows,
  including attachment/detachment and project switching.
- [ ] **COVER-04:** Verify clean installation, missing external dependencies,
  session restoration, and supported upgrade paths.
- [ ] **COVER-05:** Complete keymap conflict, cleanup/reload, and plugin usage review.
- [ ] **COVER-06:** Measure startup/runtime performance before making speed claims.

## References

- [Compatibility patch registry](../core/compatibility-patches.md)
- [Prerequisites](../core/prerequisites.md)
- [Plugin map](../core/plugin-map.md)
- [LuaLS settings](https://github.com/LuaLS/lua-language-server/wiki/Settings):
  workspace library path types.
- [Mason LSP configuration](https://github.com/mason-org/mason-lspconfig.nvim):
  automatic enablement of installed servers and restriction options.

## Change log

| Date       | Item     | Decision / implementation                                  | Commit | Validation / limitations                                                   |
|------------|----------|------------------------------------------------------------|--------|----------------------------------------------------------------------------|
| 2026-11-10 | Baseline | Recorded initial audit; no configuration fixes implemented | —      | Static review and checks listed above; comprehensive coverage remains open |

## Completed — 2026-11-10

These entries record completed implementation or validation, not completion of
all interactive acceptance checks. Pending checks remain in Open work above.
Changes are uncommitted; no commit was requested.

| Item             | Completed change                                                                                             | Validation                                                                        |
|------------------|--------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| AUD-01           | Replaced `io.stderr:write` with the established `nvim_err_writeln` convention in `tests/markdown_images.lua` | Lint passes; 8 Markdown image checks pass                                         |
| AUD-02           | Flattened LuaLS runtime library paths; removed redundant nested lspconfig path                               | String-path and project-settings precedence assertions pass                       |
| AUD-03           | Added JDTLS to Mason activation exclusions, preserving other server activation                               | Exclusion assertion passes; documentation matches policy                          |
| AUD-04           | Corrected notifications/comments/docs to say diagnostic errors; preserved suppression across all namespaces  | Full configuration checks pass; save policy unchanged                             |
| AUD-07 (partial) | Added Markdown image suite to `make check-config`                                                            | Full standard targets pass                                                        |
| AUD-09           | Included caught setup/invocation errors in code-action fallback warnings                                     | Formatting/lint and full regression suite pass; forced-failure check remains open |
| COVER-02         | Ran full applicable standard regression suite after restoring quality gate                                   | `make check` passes                                                               |

Explicit separate test invocations remain:

- `nvim --headless -u NONE -i NONE -l tests/format_cli.lua`: real formatter
  subprocesses; requires built external formatters.
- `python3 tests/markdown_scroll.py`: disposable Neovim TUI scrolling checks.

Validation after each implementation group:

- Group 1: repository formatter, `make check-format check-lint`, Markdown image
  checks (8), and configuration refinement checks (142) passed. Inspected diff.
- Group 2: repository formatter and full `make check` passed, including installed
  compatibility contracts (151), session workspace checks (32), and all other
  standard targets. Inspected final diff; `git diff --check` passed.
- Live completion, live Java attachment, forced code-action failure, and Ruby
  environment repair were not exercised. The original comprehensive audit still
  has the coverage gaps listed above.
