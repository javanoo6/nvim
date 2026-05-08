# Java Debugging in Neovim

Complete workflow for debugging Java applications using **nvim-java** + **nvim-dap**.

---

## Architecture Overview

```nvim-java (orchestrator)
    ↓
jdtls + java-debug-adapter (debug server on localhost:port)
    ↓
nvim-dap (debug client + DAP UI)
```

When you start debugging:

1. `nvim-java` requests `jdtls` for class paths, module paths, JVM executable
2. `jdtls` starts a debug session and returns a port (e.g., `localhost:5005`)
3. `nvim-dap` connects to that port via the Debug Adapter Protocol
4. DAP UI opens automatically (variables, call stack, REPL)

---

## Prerequisites

### 1. Ensure JDTLS is running

Check with:

```
:LspInfo
```

You should see `jdtls` attached with status `attached`. If not:

```
:Lazy java
```

Or wait for JDTLS to start automatically (it may take 2-5 seconds on first open).

### 2. Verify Java Debug Adapter is enabled

Your `lua/plugins/nvim-java.lua` should have:

```lua
java_debug_adapter = { enable = true }
```

### 3. Check logs if things fail

```
tail -f ~/.local/state/nvim/nvim-java.log
```

---

## Starting Debug Sessions

### A. Debugging Tests (Most Common)

#### Via Command Line

Place cursor on the test method or class:

| Command                       | Action                         |
|-------------------------------|--------------------------------|
| `:JavaTestDebugCurrentMethod` | Debug test method under cursor |
| `:JavaTestDebugCurrentClass`  | Debug entire test class        |
| `:JavaTestDebugAllTests`      | Debug all tests in workspace   |

#### Via Lua API (keybindings or mappings)

```lua
require('java').test.debug_current_method()    -- <leader>jmd
require('java').test.debug_current_class()     -- <leader>jmd
require('java').test.debug_all_tests()         -- <leader>jma
```

#### Via Neotest (if configured)

```lua
<leader>tr    -- Run/Debug nearest test (check your neotest config)
```

### B. Debugging Main Applications

#### Spring Boot / Main Class

Place cursor on a main class (e.g., `@SpringBootApplication`):

```
:JavaDebugCurrentFile
```

Or via API:

```lua
require('java').debug.debug_current_file()
```

#### Debug Last Run File

```lua
require('java').debug.debug_last_file()
```

#### Attach to Remote JVM

If your app is running externally with `-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005`:

```lua
require('dap').continue {
  type = 'java',
  request = 'attach',
  name = 'Attach to Remote',
  hostName = 'localhost',
  port = 5005
}
```

---

## DAP Controls (Once Debugging Started)

| Key                         | Action                 | Context                                        |
|-----------------------------|------------------------|------------------------------------------------|
| `<leader>db`                | Toggle breakpoint      | Set breakpoint on current line                 |
| `<leader>dB`                | Conditional breakpoint | Set breakpoint with condition (e.g., `i == 5`) |
| `<leader>dc`                | Continue / Resume      | Continue execution to next breakpoint          |
| `<leader>dC`                | Run to cursor          | Run until current line                         |
| `<leader>di`                | Step into              | Enter method/function                          |
| `<leader>dO`                | Step over              | Skip method, stay at same level                |
| `<leader>do`                | Step out               | Execute remaining and return to caller         |
| `<leader>dg`                | Go to line             | Jump cursor to line (no execute)               |
| `<leader>dp`                | Pause                  | Suspend execution                              |
| `<leader>dt`                | Terminate              | Stop debug session                             |
| `<leader>ds`                | Session info           | Show current thread, frames                    |
| `<leader>dk` / `<leader>dj` | Down/Up stack          | Navigate call stack frames                     |
| `<leader>du`                | Toggle DAP UI          | Show/hide variables, call stack, REPL          |
| `<leader>de`                | Eval expression        | Select text and eval (e.g., `user.getName()`)  |
| `<leader>dr`                | Toggle REPL            | Interactive debug console                      |
| `<leader>dw`                | Hover widgets          | Show variable values inline                    |

---

## Complete Workflow Example

### Scenario: Debug a failing test `UserControllerTest.testCreateUser`

**Step 1**: Open the test file and locate the failing test

```bash
# Find the file
:Telescope find_files
# Or
:ls
```

**Step 2**: Place cursor on the test method name

```java

@Test
public void testCreateUser() {  // ← Cursor here
    // ...
}
```

**Step 3**: Set breakpoints (optional but recommended)

- Go to `UserController.createUser()` method
- Press `<leader>db` on the line where you expect the bug
- Repeat for other suspicious lines
- Breakpoints appear as red dots (or your highlight color)

**Step 4**: Start debugging

```
:JavaTestDebugCurrentMethod
```

Or if you have a keybinding:

```
<leader>jd   (hypothetical - check your config)
```

**Step 5**: Wait for startup (5-10 seconds)

- JDTLS compiles the project
- Debug session starts
- DAP UI opens automatically (variables, call stack, REPL)
- Execution pauses at first breakpoint or test start

**Step 6**: Interact with the debugger

```
<leader>dc    # Continue to first breakpoint
<leader>di    # Step into a method call
<leader>dO    # Step over a method call
<leader>de    # Select "user.getName()" and press to evaluate
```

**Step 7**: Inspect state

- **DAP UI left panel**: Variables (hover over any to see full value)
- **Call stack**: Navigate frames with `<leader>dj`/`<leader>dk`
- **REPL** (`<leader>dr`): Type `System.out.println(x)` to inspect

**Step 8**: Fix and re-run

- Fix the bug
- Press `<leader>dt` to terminate
- Re-run test with `<leader>jm` (run mode) or repeat Step 4 (debug mode)

---

## Advanced Techniques

### Conditional Breakpoints

```
<leader>dB    # Prompt: "Breakpoint condition: "
Type: user != null && user.getId() == 123
```

### Hot Reloading (Edit While Running)

If using Spring Boot DevTools:

1. Start debug session
2. Edit Java file (e.g., change logic in service layer)
3. Save with `<C-s>`
4. Hot reload may apply changes without restarting (if using Spring Boot DevTools)

### Inspecting Collections

In DAP UI or REPL:

```
list.stream().map(u -> u.getName()).collect(Collectors.toList())
```

### Thread Switching

If debugging multi-threaded apps:

```
<leader>ds    # See all threads
# Then navigate to specific thread frame in call stack
```

---

## Troubleshooting

### "No debug session found" or "DAP not available"

**Cause**: Debug session hasn't started or crashed.

**Fix**:

```
:JavaInfo           # Check nvim-java status
:LspInfo            # Check JDTLS attached
:checkhealth java   # Detailed Java health check
```

### "Failed to start debug session"

**Cause**: JDTLS not fully loaded, or project not compiled.

**Fix**:

```
:Lazy java          # Reload java plugin
# Or wait 5 seconds and retry
```

### "Port already in use"

**Cause**: Stale debug session from previous run.

**Fix**:

```
:q                  # Close nvim
# Or kill jdtls process
killall java        # If no other java apps running
```

### Breakpoints not hitting

**Check**:

1. Is JDTLS compiled the latest code? (`:LspInfo` → check for compilation errors)
2. Are you in the right thread? (`<leader>ds`)
3. Is the code actually executed? (check call stack `<leader>ds`)

### Logs

```
~/.local/state/nvim/nvim-java.log    # nvim-java logs
~/.cache/nvim/jdtls/snapshots/*      # JDTLS state
```

---

## Quick Reference

| Task                      | Command                           |
|---------------------------|-----------------------------------|
| Debug current test method | `:JavaTestDebugCurrentMethod`     |
| Debug current test class  | `:JavaTestDebugCurrentClass`      |
| Debug main file           | `:JavaDebugCurrentFile`           |
| Toggle breakpoint         | `<leader>db`                      |
| Continue                  | `<leader>dc`                      |
| Step into                 | `<leader>di`                      |
| Step over                 | `<leader>dO`                      |
| Step out                  | `<leader>do`                      |
| Eval expression           | `<leader>de` + select text        |
| Toggle DAP UI             | `<leader>du`                      |
| Terminate                 | `<leader>dt`                      |
| Check health              | `:JavaInfo` / `:checkhealth java` |

---

## Configuration Details

**nvim-java setup** (`lua/plugins/nvim-java.lua`):

```lua
require("java").setup({
    java_debug_adapter = { enable = true },  -- Critical!
    jdk = { auto_install = false },
})
```

**nvim-dap setup** (`lua/plugins/dap.lua`):

- Auto-opens DAP UI on `event_initialized`
- Auto-closes on `event_terminated`/`event_exited`
- Virtual text hides secrets (lines 155-165)

---

**Last updated**: Based on nvim-java v0.6+ and nvim-dap v0.9+
