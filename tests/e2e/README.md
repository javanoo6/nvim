# Interactive Neovim regression harness

This runner starts a real Neovim TUI in a disposable PTY and controls it through
a dedicated `nvim-mcp` stdio server. Every case gets its own editor, socket,
project, XDG data/state/cache directories, and evidence directory. It does not
connect to an existing editor. Cases execute mappings and inspect editor state,
diagnostics, selections, filesystem changes, or test results.

## Run

Prerequisites: Linux, Python 3.11+, `nvim` and `nvim-mcp` on PATH, this repository
installed as the active Neovim configuration, and its plugins/tools already
installed. Language cases additionally need the corresponding installed language
servers, formatters and runners. Java needs the installed IntelliJ bundle,
existing consent, JDK, JUnit Console jar, and cached Maven dependencies.

Use an environment containing the dependency in `requirements.txt`, for example:

```sh
uv run --with-requirements tests/e2e/requirements.txt python tests/e2e/run.py
uv run --with-requirements tests/e2e/requirements.txt python tests/e2e/run.py --suite smoke
uv run --with-requirements tests/e2e/requirements.txt python tests/e2e/run.py --suite core --suite navigation
uv run --with-requirements tests/e2e/requirements.txt python tests/e2e/run.py --case core-lint
uv run --with-requirements tests/e2e/requirements.txt python tests/e2e/run.py --all --output /tmp/nvim-audit-new
```

No arguments lists suites. `--help` describes the runner. `--suite` and `--case` are repeatable;
`--all` includes language integrations and known anomaly reproductions. The
`layout` suite intentionally asserts English/Russian equivalence, so it remains
red while the documented defects exist. These failures are not marked as expected
passes. This runner is separate from `make check`, which does not start these
interactive workflows or language servers.

Exit codes: 0 when all selected cases pass, 1 when any case fails or is blocked,
and 2 for invalid arguments. A failed assertion or editor-reported MCP error is
`fail`. Missing prerequisites and unresolved waits are `blocked`; investigate
their evidence before attributing them to a plugin.

The Python test case needs an existing interpreter containing pytest. Set
`NVIM_E2E_PYTHON=/path/to/venv/bin/python` when it is not installed in the runner's
environment. Cases never install Python packages. Java uses Maven offline mode.

## Evidence and isolation

The runner prints concise case results and the evidence directory. It writes
`results.json` and retains each case's `mcp.jsonl`, raw `terminal.log`, bootstrap,
disposable project, and private state. Startup inventory also writes
`plugins.json`. An explicitly supplied output directory must be empty; default
output uses a unique temporary directory. Keep evidence outside the repository
or archive it deliberately. Raw logs can include fixture text and local paths.

Installed `lazy`, `mason` and `site` directories are shared through symlinks.
Automatic Lazy installation and Mason startup installation/update are disabled.
The installed Java server and JUnit jars are reused; small Java metadata files
are copied. Session, preference, Harpoon, theme and plugin cache files remain
private. Editors and MCP processes are closed after a case, including startup
failure. The harness records the embedded editor PID to handle Neovim wrappers.

This is isolation for cooperative tests, not a filesystem sandbox. Do not run
plugin update/install commands, submissions, cookie refreshes, or operations on
the user's real notes/projects. Plugins and tools can access the network and the
normal home/config directories. New cases must write only inside `audit.project`
or the private evidence directories. Existing credentials are not copied into
the evidence deliberately.

## Add a case

Register an async function in a suite's `CASES` dictionary. The runner supplies
an active `Audit` and starts a fresh editor for each function. `cmd`, `keys`,
`raw` and `state` return decoded MCP payloads; `lua` returns the decoded JSON
value of a Lua expression. Errors are raised and the original response is saved.
`cmd()` distinguishes thrown command errors from `silent!` cleanup diagnostics:
the latter are retained as `suppressed_error` in its captured response. This
avoids nvim-mcp 1.1.1 reporting ordinary Java/Markdown ftplugin cleanup as broken.

```python
async def my_case(audit):
    (audit.project / "example.txt").write_text("one\ntwo\n")
    await audit.reset("example.txt")
    await audit.keys("j")
    assert await audit.lua('vim.fn.line(".")') == 2
```

Use `wait_for(expression, timeout=10, interval=0.1)` for asynchronous readiness
instead of assuming a fixed delay proves completion. Capture before/after state
and assert the actual effect. Loading a module or opening a panel alone does not
prove the whole plugin works. `reset()` abandons fixture edits and confines its
file argument to the disposable project.

MCP input details matter:

- `keys()` uses `send_keys`, which prepends Escape. Use `raw()` inside Insert,
  Terminal, Visual selections, and plugin input loops that Escape would close.
- Raw input still uses Neovim key notation. Send `<lt>` for a literal `<`.
- Batch a multi-key mapping or operator sequence in one input call. Separate RPC
  calls can disturb pending input; one audit attempt failed even its English
  control that way. Poll after the completed sequence.
- Russian text in Insert mode must remain Russian. Compare equivalent physical
  ЙЦУКЕН keys for mapped commands, including shifted/modifier variants where
  applicable. Keep the standard `h/j/k/l` direction model.
- Notification floats count as windows. Filter window configurations with
  `relative == ""` when asserting split layouts.
- For text and Markdown, effective wrap/spell defaults can differ from the
  persisted preference default. Inspect the window option before toggling it.

The notification recorder observes Noice message delivery; it does not replace
`vim.notify`, which would itself trigger Noice's health warning. Editor-state
evidence is not a pixel screenshot, terminal graphics test, or physical keyboard
test. The saved suites cover repeatable representative workflows, not every
mapping of every plugin. The dated audit records the broader exploratory pass
and its coverage gaps.
