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
No recommendation should be interpreted as an already implemented behavior.

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

## P0 — Correctness and reliability

- [ ] **AUD-01 — Restore the lint quality gate.**
    - Severity/category/confidence: High / quality gate / Confirmed by execution.
    - Location: `tests/markdown_images.lua:70`, `vim.yml`, `Makefile`.
    - Problem: the standard lint target fails on `io.stderr:write`. This is a
      lint-model mismatch, not evidence that Lua cannot execute that expression.
    - Fix: correct the local standard-library definition or use the established
      test error-reporting idiom. Avoid suppressing unrelated diagnostics.
    - Benefit: a usable quality gate. Effort: small. Risk/trade-off: low; preserve
      failure reporting and nonzero exit behavior.
    - [x] `make check-lint` passes.
    - [ ] The affected test still reports failures correctly.

- [ ] **AUD-02 — Flatten LuaLS workspace library paths.**
    - Severity/category/confidence: Medium / LSP correctness / Confirmed malformed
      configuration; actual server reaction was not tested.
    - Location: `lua/plugins/lsp.lua:248`.
    - Problem: `nvim_get_runtime_file("lua", true)` is inserted as a nested table
      in `workspace.library`, which expects a list of paths.
    - Fix: extend the path list with the returned paths; keep library scope explicit.
    - Benefit: valid settings. Effort: small. Risk/trade-off: low, but expanding
      libraries can increase indexing work.
    - [x] Every library entry sent to LuaLS is a string path.
    - [ ] Neovim API completion works in this repository.
    - [x] Project-local LuaLS configuration retains its intended precedence.

- [ ] **AUD-03 — Make Mason server activation explicit.**
    - Severity/category/confidence: High / workspace reliability / Confirmed policy
      mismatch; duplicate Java attachment needs runtime verification.
    - Location: `lua/plugins/lsp.lua:287`, `lua/config/options.lua`,
      `docs/core/session-context.md`, `docs/core/plugin-map.md`.
    - Problem: automatic activation excludes three Python servers but not JDTLS,
      despite documentation saying JDTLS is excluded. Installed tools can change
      active servers independently of configuration changes.
    - Fix: prefer an explicit automatic-enable allowlist; at minimum exclude JDTLS.
    - Benefit: predictable server ownership. Effort: small. Risk/trade-off:
      low–medium; adding a server requires updating the activation policy.
    - [ ] IntelliJ remains the sole intended Java server even with JDTLS installed.
    - [ ] Python selection and the separate refactoring server still work.
    - [ ] Intended other language servers attach normally.
    - [x] Documentation matches the actual activation policy.

## P1 — High-impact simplifications

- [ ] **AUD-04 — Clarify diagnostic-based formatting suppression.**
    - Severity/category/confidence: Medium / predictability / Confirmed.
    - Location: `lua/plugins/formatting.lua:171`, `lua/plugins/auto-save.lua`.
    - Problem: the check described as “LSP errors” reads all diagnostic namespaces,
      including linters. Unrelated or stale errors can suppress formatting.
    - Fix: explicitly choose all errors or selected LSP diagnostics, then align
      implementation, notifications, and documentation with that decision.
    - Benefit: understandable save behavior. Effort: small. Risk/trade-off: medium;
      narrowing the rule permits formatting despite lint errors.
    - [x] Record the chosen policy and rationale.
    - [ ] Verify manual save and autosave with LSP-only and linter-only errors.
    - [ ] Verify explicit manual formatting remains intentional and predictable.

- [ ] **AUD-05 — Decouple Markdown linting from BasedPyright's bundled Node.**
    - Severity/category/confidence: Medium / dependency coupling / Confirmed.
    - Location: `lua/plugins/linting.lua:51`, `docs/core/prerequisites.md`.
    - Problem: Markdown tooling reaches into another language tool's private
      Python package layout to locate Node.
    - Fix: use a supported Node executable and document the required version.
    - Benefit: independent, reproducible tooling. Effort: small. Risk/trade-off:
      low; a suitable Node runtime must be installed separately.
    - [ ] Markdown linting works without BasedPyright installed.
    - [ ] Missing/incompatible Node is diagnosable.

- [ ] **AUD-06 — Review compatibility patches individually during upgrades.**
    - Severity/category/confidence: Medium / upgrade maintenance / Confirmed risk,
      not evidence of current failure.
    - Locations: `docs/core/compatibility-patches.md` and its listed owners.
    - Problem: private contracts create significant upgrade work across completion,
      Which-key, Bufferline, Neotest, sessions, and IntelliJ.
    - Fix: use each documented reproduction to evaluate supported upstream
      replacements; retire only patches proven unnecessary.
    - Benefit: largest potential long-term maintenance reduction. Effort: ongoing.
      Risk/trade-off: medium–high; removing patches can reintroduce old failures.
    - [ ] Record a disposition for each patch reviewed: retain, replace, or remove.
    - [ ] Run its reproduction without the patch before removal.
    - [ ] Preserve required local behavior and update registry/tests.
    - [ ] Complete applicable interactive smoke checks, not only structural probes.

## P2 — Maintainability and consistency

- [ ] **AUD-07 — Inventory regression test entrypoints.**
    - Severity/category/confidence: Medium / coverage integration / Confirmed direct
      omission; indirect coverage was not exhaustively traced.
    - Location: `Makefile:17`, `tests/`.
    - Problem: `tests/markdown_images.lua` is linted but not directly invoked by
      standard regression targets; other standalone tests also lack direct entries.
    - Fix: map tests to targets; include intended suites or document separate runs.
    - Benefit: tests cannot quietly become orphaned. Effort: small. Risk/trade-off:
      low; some suites may require a terminal or external tools.
    - [ ] Every test has a documented invocation or reason for exclusion.
    - [ ] Run the resulting applicable standard targets.

- [ ] **AUD-08 — Allow RuboCop availability to recover within a session.**
    - Severity/category/confidence: Medium / recovery / Confirmed cache behavior.
    - Location: `lua/plugins/formatting.lua:44`.
    - Problem: availability results are cached indefinitely by root/Gemfile path;
      repairing gems does not invalidate a cached failure.
    - Fix: explicit invalidation or avoid indefinitely retaining negative results.
    - Benefit: recovery without restarting. Effort: small. Risk/trade-off: low;
      repeated shell probes may be expensive.
    - [ ] Failed availability followed by environment repair succeeds in one session.
    - [ ] Ordinary saves do not repeatedly run expensive availability checks.

- [ ] **AUD-09 — Preserve code-action fallback error details.**
    - Severity/category/confidence: Low / observability / Confirmed.
    - Location: `lua/plugins/lsp.lua`, actions-preview setup and invocation guards.
    - Problem: caught errors are discarded, leaving generic fallback warnings.
    - Fix: include the original error in a warning or existing diagnostic output.
    - Benefit: actionable failures. Effort: small. Risk/trade-off: low; more text.
    - [ ] A forced failure exposes its cause and still reaches native code actions.

- [ ] **AUD-10 — Revisit cohesion of the general utility module when touched.**
    - Severity/category/confidence: Low / architecture / Confirmed mixed ownership.
    - Location: `lua/util/init.lua`, its root/explorer callers.
    - Problem: mappings, highlights, root policy, explorer state, picker dispatch,
      and icons share one module with preference-derived initialization.
    - Proposal: extract root/explorer policy only when making substantive changes
      there; do not split every small helper or create a generic service layer.
    - Benefit: easier tracing. Effort: medium. Risk/trade-off: medium; more imports
      and possible load-order changes. Deferral is a valid decision.
    - [x] Record whether extraction delivers enough practical value.
    - [ ] If changed, preserve root/cwd behavior and run root/session regressions.

## P3 — Measurement and optional improvements

No performance problem was measured during the audit. The following are
investigations, not mandates to optimize.

- [ ] **AUD-11 — Measure synchronous formatting and autosave latency.**
    - Severity/category/confidence: Medium / responsiveness / Confirmed synchronous
      path; user-visible latency Needs verification.
    - Locations: `formatting.lua:64`, `auto-save.lua:12`.
    - Ten-second save-time budgets and saves on buffer leave/focus loss can make
      slow formatting affect navigation. Measure warm/cold formatter execution.
    - Effort: medium. Risk: low for measurement. Trade-off if changed: shorter
      automatic budgets may skip formatting; retain an explicit manual route.
    - [ ] Record warm/cold times and navigation behavior.
    - [ ] Decide whether automatic-save budgets need changing.

- [ ] **AUD-12 — Profile startup and everyday hot paths.**
    - Locations: `lua/plugins/ui.lua:165`, `lua/util/init.lua`,
      `lua/plugins/completion.lua:85`, `lua/plugins/treesitter.lua`.
    - Candidates: uncached filesystem root detection in the statusline, completion
      across all loaded buffers below 512 KiB each, and large-buffer highlighting.
    - Confidence: Needs verification. Effort: medium. Risk: low for measurement.
    - [ ] Compare empty and representative project startup across repeated runs.
    - [ ] Measure first completion and many-buffer completion.
    - [ ] Inspect large-file highlighting and root lookups on slow filesystems.
    - [ ] Record evidence before adding caching, cutoffs, or lazy-loading logic.

Suggested commands (create profiling output outside the repository):

```sh
nvim --startuptime /tmp/nvim-empty-startup.log
nvim --startuptime /tmp/nvim-project-startup.log path/to/representative/file
```

Also use `:Lazy profile`. Separate first launches from warm runs, and session
restoration from ordinary startup. Startup measurements do not establish editing
responsiveness.

- [ ] **AUD-13 — Review optional UI overlap and unused themes.**
    - Compare actual usage of Aerial/ Trouble symbols, notification/prompt owners,
      marks/Harpoon, and alternative themes. Overlap alone is not redundancy.
    - Consider upstream defaults for the custom actions-preview presentation if
      its extra labels/layout are not useful.
    - Benefit: less optional maintenance. Effort: small. Risk: preference-dependent.
    - [ ] Record actual usage and keep/remove/simplify decisions.
    - [ ] Preserve useful behavior; do not replace concise plugins with custom Lua.

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
- [x] **COVER-02:** Run the full applicable regression suite after restoring the gate.
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

## Independent review and implementation — 2026-11-10

The original priorities overstated some risks: AUD-02 is a settings-shape defect,
not demonstrated loss of completion; AUD-03 is a documented ownership safeguard,
not an observed duplicate Java client. No architecture rewrite is warranted.

- AUD-01 accepted and implemented using the existing `nvim_err_writeln` test
  convention. Lint and the real Markdown image suite pass.
- AUD-02 accepted and implemented with a flat list of runtime Lua directories.
  The redundant nested lspconfig directory entry was removed. Configuration
  assertions verify string paths and project-local settings precedence. Actual
  LuaLS completion remains an interactive verification item.
- AUD-03 accepted narrowly: add JDTLS to exclusions. Reject an allowlist because
  it would change activation of unrelated installed servers without evidence.
  Configuration assertions check exclusion; no live Java server was launched.
- AUD-04 accepted as a wording correction. Preserve suppression for errors from
  every diagnostic namespace; changing that policy would change existing behavior.
  Notifications and core comments/documentation now describe diagnostic errors.
- AUD-05 rejected for this environment. Session context documents that system
  Node 18 lacks required regex support. Removing the fallback would regress
  Markdown linting; requiring a runtime upgrade exceeds this focused correction.
- AUD-06 retain the documented compatibility patches. Their reproductions and
  locked contracts justify them; no upstream update or replacement was established.
  Retirement remains work for a future dependency upgrade.
- AUD-07 partially accepted: include the headless Markdown image suite in
  `make check-config`. `tests/format_cli.lua` remains an explicit invocation
  (`nvim --headless -u NONE -i NONE -l tests/format_cli.lua`) because it needs
  built external formatters. `tests/markdown_scroll.py` remains explicit
  (`python3 tests/markdown_scroll.py`) because it exercises a disposable TUI.
  A complete entrypoint inventory remains open.
- AUD-08 deferred: restarting after Ruby environment repair is currently a simple
  recovery path. Do not add timers, invalidation commands, or repeated synchronous
  probes without an actual workflow need.
- AUD-09 accepted: preserve caught setup/invocation errors in fallback warnings.
  The existing native fallback behavior remains intact.
- AUD-10 rejected for this change: extracting root/explorer state creates import
  churn without changing a demonstrated maintenance problem.
- AUD-11/AUD-12 deferred: keep timeouts, loading, roots, and highlighting unchanged
  until representative latency measurements justify changes.
- AUD-13 reject removals or presentation changes based solely on apparent overlap;
  actual usage evidence is unavailable and existing workflows must be preserved.

Unchecked verification items above remain open where interactive checks or full
coverage have not been performed. This review does not claim completion of the
original comprehensive audit. Changes are uncommitted; no commit was requested.

### Validation of implemented groups

- Group 1: repository formatter, `make check-format check-lint`, Markdown image
  checks (8), and configuration refinement checks (142) passed. Inspected diff.
- Group 2: repository formatter and full `make check` passed, including installed
  compatibility contracts (151), session workspace checks (32), and all other
  standard targets. Inspected final diff; `git diff --check` passed.
- Live completion, live Java attachment, forced code-action failure, and Ruby
  environment repair were not exercised. Remaining unchecked acceptance items
  continue to track these limits rather than claiming end-to-end validation.
