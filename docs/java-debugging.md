# Java Debugging in Neovim

Current workflow for this config using `nvim-java`, JDTLS, Java debug adapter,
`nvim-dap`, and `neotest`.

## Architecture

```text
nvim-java
  -> jdtls + java-debug bundle
  -> nvim-dap
  -> dap-ui / virtual text / REPL
```

Java LSP and Java DAP are owned by `nvim-java`; do not add
`mfussenegger/nvim-jdtls` alongside it.

Relevant files:

- [lua/plugins/nvim-java.lua](/home/konkov/.config/nvim/lua/plugins/nvim-java.lua:1)
- [lua/plugins/lsp.lua](/home/konkov/.config/nvim/lua/plugins/lsp.lua:1)
- [lua/plugins/dap.lua](/home/konkov/.config/nvim/lua/plugins/dap.lua:1)
- [lua/util/java_debug.lua](/home/konkov/.config/nvim/lua/util/java_debug.lua:1)
- [lua/util/java_runner.lua](/home/konkov/.config/nvim/lua/util/java_runner.lua:1)

## Preconditions

Open a Java file and wait for JDTLS.

Check attachment:

```vim
:LspInfo
```

Useful health/log commands:

```vim
:JavaInfo
:checkhealth java
:LspLog
```

Log path:

```text
~/.local/state/nvim/nvim-java.log
```

## App Run And Debug

| Key          | Action                                    |
|--------------|-------------------------------------------|
| `<leader>jr` | run current Java main / Spring Boot app   |
| `<leader>jd` | debug current Java main / Spring Boot app |
| `<leader>jc` | stop current Java runner app              |
| `<leader>jl` | toggle Java runner logs                   |
| `<leader>ja` | attach to remote JVM                      |

`<leader>jd` calls:

```lua
require("util.java_debug").debug_main()
```

That helper ensures Java DAP is configured, reads `dap.configurations.java`, and
either starts the single launch config or prompts when multiple Java launch
configs exist.

## Test Run And Debug

Use `neotest` for the mapped test workflow:

| Key          | Action                         |
|--------------|--------------------------------|
| `<leader>tr` | run nearest test               |
| `<leader>td` | debug nearest test             |
| `<leader>tt` | run current file/package       |
| `<leader>tf` | debug current file             |
| `<leader>tp` | run package                    |
| `<leader>tP` | debug package                  |
| `<leader>tT` | run all test files in scope    |
| `<leader>tD` | debug all test files in scope  |
| `<leader>tl` | run last                       |
| `<leader>tF` | run failed tests               |
| `<leader>tL` | debug last                     |
| `<leader>ta` | attach to running test process |

Raw `nvim-java` test commands are still available when needed:

```vim
:JavaTestRunCurrentMethod
:JavaTestRunCurrentClass
:JavaTestDebugCurrentMethod
:JavaTestDebugCurrentClass
:JavaTestDebugAllTests
```

## DAP Controls

These work once a debug session is active:

| Key          | Action                              |
|--------------|-------------------------------------|
| `<leader>db` | toggle breakpoint                   |
| `<leader>dB` | conditional breakpoint              |
| `<leader>dc` | continue                            |
| `<leader>dC` | run to cursor                       |
| `<leader>di` | step into                           |
| `<leader>dO` | step over                           |
| `<leader>do` | step out                            |
| `<leader>dp` | pause                               |
| `<leader>dt` | terminate                           |
| `<leader>dl` | run last DAP session                |
| `<leader>ds` | show current DAP session            |
| `<leader>dj` | move up stack frame                 |
| `<leader>dk` | move down stack frame               |
| `<leader>du` | toggle DAP UI                       |
| `<leader>de` | eval expression or visual selection |
| `<leader>dr` | toggle DAP REPL                     |
| `<leader>dw` | DAP hover widget                    |

DAP UI opens automatically when a session starts and closes when the session
terminates or exits.

## Remote JVM Attach

Current state:

- `<leader>ja` prompts for JDWP host and port.
- Defaults are `127.0.0.1` and `5005`.
- The helper runs a Java DAP `attach` configuration.

Typical JVM flag for the target process:

```bash
-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
```

Future note: this section is intentionally short for now. Add the full remote
debug recipe here when the project-specific attach workflow is finalized.

## Example: Debug A Spring Boot App

1. Open the app's main class.
2. Wait for `jdtls` in `:LspInfo`.
3. Set breakpoints with `<leader>db`.
4. Press `<leader>jd`.
5. If prompted, select the intended Java launch config.
6. Use `<leader>dc`, `<leader>dO`, `<leader>di`, and `<leader>de` to inspect.
7. Terminate with `<leader>dt`.

If no launch configs appear, wait for JDTLS import/build to finish and retry.
For mixed Maven/Gradle roots, this config forces Maven import before startup so
main-class discovery follows the Maven project model.

## Example: Debug A Test

1. Open the test file.
2. Put the cursor inside the test method.
3. Set breakpoints with `<leader>db`.
4. Press `<leader>td` to debug nearest test.
5. Use DAP controls once the session starts.

For a whole file or package, use `<leader>tf` or `<leader>tP`.

## Troubleshooting

### No Java Launch Configs

Check:

```vim
:LspInfo
:JavaInfo
```

Then wait for project import/build to complete. Java launch configs are created
after JDTLS and the Java debug bundle have enough project state.

### Debug Session Does Not Start

Try:

```vim
:JavaDapConfig
```

Then retry `<leader>jd` or the relevant Neotest debug mapping.

### Breakpoints Do Not Hit

Check:

- the debug session is active
- the code path is actually executed
- the project compiled without JDTLS errors
- the target JVM is the one you attached to for remote debugging

### Port Already In Use

Terminate stale sessions with `<leader>dt`. If an external process still owns
the JDWP port, stop that process or use a different port.

## Notes

- `:JavaDebugCurrentFile` is not part of the current installed `nvim-java`
  command set; use `<leader>jd` for app/main debugging.
- LeetCode-style standalone `Solution` files need a `main` harness before they
  can be debugged as Java applications. See
  [docs/java-leetcode-debugging.md](/home/konkov/.config/nvim/docs/java-leetcode-debugging.md:1).
