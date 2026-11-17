# Neovim E2E anomaly audit — 2026-11-17

Sol coordinated three Terra agents. Checks used Neovim 0.12.2 and nvim-mcp
1.1.1, dedicated MCP servers, real disposable TUI instances, and scratch projects.
The configured inventory contains 96 plugins; the stale disabled Spring Boot
lock entry is excluded. Individual observations and incomplete coverage are
recorded in [the coverage ledger](2026-11-17-nvim-e2e-coverage.json).

The saved regression cases produced 18 passes, four input-parity failures and
one blocked linter prerequisite across 23 distinct cases. The four failures
and broken prerequisite correspond to the five findings below. Exact results
and evidence paths are preserved in
[the result snapshot](2026-11-17-nvim-e2e-results.json). The existing `make check`
suite also passed.

The findings below are reproducible editor-state discrepancies from injected
input. Physical keyboard delivery and rendered pixels were not tested. Existing
configuration files were not changed to fix findings.

## Confirmed anomalies

### 1. Russian line-comment input does not match English

In a Lua buffer containing `alpha`, start in Normal mode at line 1, column 0.

| Input | Expected   | Observed                  |
|-------|------------|---------------------------|
| `gcc` | `-- alpha` | `-- alpha`                |
| `псс` | `-- alpha` | `alpha` remains unchanged |

This affects the Comment.nvim workflow. The English control succeeds in the
same fixture. The discrepancy repeated in fresh editors and in the saved
`layout-comment` case. An earlier run also left operator-pending mode; the saved
assertion relies on the unchanged text rather than requiring that incidental
mode result.

### 2. Russian surround command quotes one character instead of the word

In a Lua buffer containing `hello world`, start in Normal mode at column 0.

| Input    | Expected        | Observed        |
|----------|-----------------|-----------------|
| `gsaiw"` | `"hello" world` | `"hello" world` |
| `пыфшц"` | `"hello" world` | `"h"ello world` |

This affects mini.surround's inner-word workflow. The command and motion keys
are translated to Russian; the same literal quote delimiter is supplied in both
cases to isolate the word-selection failure. This does not establish shifted
Russian delimiter-key behavior. Reproduced in fresh editors and saved as
`layout-surround`.

### 3. Russian mark navigation silently stays on the current line

Create a three-line file, set mark `a` on line 1 and `b` on line 3 using
`ggmaGmb`, and return to mark `a`.

| Input | Starting line | Expected line | Observed line |
|-------|---------------|---------------|---------------|
| `m]`  | 1             | 3             | 3             |
| `ьъ`  | 1             | 3             | 1             |
| `m[`  | 3             | 1             | 1             |
| `ьх`  | 3             | 1             | 3             |

This affects marks.nvim's next/previous mappings. Both layouts finish in Normal
mode without a reported error. Independent Terra checks reproduced both
directions. The saved `layout-marks` case checks previous-mark parity after
successful English controls.

### 4. Russian Visual inner-word input does not create a selection

In a Lua buffer containing `alpha beta`, start in Normal mode at column 0.

| Input | Expected                    | Observed                     |
|-------|-----------------------------|------------------------------|
| `viw` | Visual selection of `alpha` | Visual mode, cursor column 4 |
| `мшц` | Same selection              | Normal mode, cursor column 0 |

This is a core input/text-object discrepancy; it is not attributed specifically
to mini.ai. It was independently reproduced in separate fresh editors and is
saved as `layout-visual-word`.

The shared input adapter has recursive per-character Russian aliases, while
these workflows combine multiple keys and operator/text-object handling. That
is an investigation lead, not a proven explanation for every finding.

### 5. Installed yamllint fails before it can produce diagnostics

In the disposable editor, `vim.fn.executable("yamllint")` returns 1 and resolves
the Mason-installed command. Running `yamllint --version` through Neovim exits 1
with `ModuleNotFoundError: No module named 'yamllint'`. The installed environment
has a `python3.12` symlink pointing to the current `/usr/bin/python3`; a specific
cause of the missing module has not been established.

Opening malformed YAML or explicitly invoking `lint.try_lint("yamllint")`
produces no diagnostics in nvim-lint's yamllint namespace. The YAML language
server independently reports its syntax error. This is an installed-tool
failure, rather than evidence of a defect in nvim-lint's implementation. The
saved `core-lint` case checks the tool's exit status and reports this prerequisite
as blocked instead of waiting for diagnostics that cannot arrive.

## Reproduce and retain evidence

The reusable harness and instructions are in
[tests/e2e/README.md](../../tests/e2e/README.md). Run the saved anomaly cases:

```sh
uv run --with-requirements tests/e2e/requirements.txt python tests/e2e/run.py --suite layout
```

The runner must exit nonzero while these parity assertions fail. Every case
retains its MCP request/response log, terminal stream, fixture and private state.
The broader repeatable suite also includes startup, editing preferences,
buffer navigation, sessions, terminals, Markdown, files, Git, search replacement,
and Python/Go/Java integrations. Some exploratory checks are represented in the
ledger rather than automated in the saved suites.

## Coverage limits and excluded false positives

This is an inventory-wide workflow audit, not proof of every plugin feature,
mapping, language, or mode. The ledger explicitly distinguishes partial checks,
dependencies, blocked prerequisites and unverified behaviors. Go struct-tag
generation was blocked by missing `gomodifytags`. External account submissions,
cookie refreshes and changes to real notes/projects were not exercised.

Early notification capture replaced `vim.notify` and caused a Noice health
warning; that audit-induced warning is excluded and the preserved harness does
not replace `vim.notify`. A bare `<` was an incomplete MCP key event; Quicker
collapse worked with `<lt>`. Effective text-buffer wrap defaults and floating
notification windows also invalidated two initial assertions, which were
corrected.

The MCP server reports nonempty `v:errmsg` as a failure even when upstream Vim
ftplugins intentionally use `silent!` cleanup. Markdown's missing-map cleanup
and Java's absent SpotBugs augroup cleanup were examples. The preserved harness
records these suppressed diagnostics separately, raises actual thrown command
errors, and checks the resulting workflow state. These cleanup messages are
excluded from plugin defects.
