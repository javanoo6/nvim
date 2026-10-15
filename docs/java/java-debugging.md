# Java Debugging in Neovim

Open a Java source file in a Maven/Gradle project and check `:JavaInfo` for an
attached, ready IntelliJ client. Set breakpoints with `<leader>db`, then put the
cursor inside the class to launch.

Source breakpoints persist with the directory/branch session, including conditions,
hit conditions, and log messages. `<leader>Ss` saves them immediately; session
auto-save also captures them on exit and branch changes. Restarting Neovim or
restoring that branch recovers its saved set without launching a debugger.

| Key / command                              | Action                                      |
|--------------------------------------------|---------------------------------------------|
| `<leader>jr`                               | Run the class enclosing the cursor          |
| `<leader>jd`                               | Debug that class                            |
| `<leader>jc`                               | Stop the Java build/program                 |
| `<leader>jl`                               | Toggle build/program output                 |
| `<leader>dc`                               | Continue                                    |
| `<leader>di` / `<leader>dO` / `<leader>do` | Step into / over / out                      |
| `<leader>de`                               | Evaluate the source expression or selection |
| `<leader>du`                               | Toggle the IntelliJ debug panel             |
| `<leader>dU`                               | Keep the panel open after exit              |
| `<leader>dt`                               | Terminate the current DAP session           |

Source is saved and Maven/Gradle compiles before launch. Build failure blocks
launch and opens output. `:IntellijLspRun!` and `:IntellijLspDebug!` explicitly
skip compilation; use them only when classes are already built. Unsupported
build resolution blocks a normal launch. Build, launch, and adapter requests
use the source workspace's IntelliJ client.

The IntelliJ panel is the default for every DAP adapter. Enter/Tab expand values
or select frames; `e` evaluates, `w` adds a watch, `dd` removes one, and `q` closes.
It shows one stopped thread and the first scope. Locals clear on termination,
even when the panel stays open; watches persist. DAP REPL is separate.

Launching a Spring main class uses a plain JVM, rather than `bootRun`,
`spring-boot:run`, or saved IDE run configurations. Launch selection uses the
class at the cursor and has no main-class picker. Remote attach is unavailable.

Java test debugging uses the same adapter and panel through
[Neotest](java-test-workflow.md). See [Java workflow](java-workflow.md) for
workspace health, restart, and project setup.
