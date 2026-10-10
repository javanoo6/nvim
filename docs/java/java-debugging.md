# Java Debugging in Neovim

## Active IntelliJ workflow

- `<leader>jr` runs the class enclosing the cursor; `<leader>jd` debugs it.
- `<leader>jc` stops the Java build/program; `<leader>jl` toggles build/program output.
- Source is saved and Maven/Gradle compiles before launch. Build failure blocks
  launch and opens IntelliJ's output panel. `:IntellijLspRun!` and
  `:IntellijLspDebug!` explicitly skip compilation.
- IntelliJ's debug panel is the default for every DAP adapter. `<leader>du`
  toggles it, `<leader>de` evaluates the expression/selection, and existing
  breakpoint/stepping keys remain. Inside the panel, `e` evaluates, `w` adds
  watches, Enter/Tab expand values, and `q` closes.
- Launch/adapter requests use the source workspace's IntelliJ client. See
  [Step 5 checks and limits](intellij-lsp-step-5.md).
- Java test debugging uses the same adapter/panel through Neotest; see
  [Step 7](intellij-lsp-step-7.md). Remote attach remains unavailable because
  Step 6 was skipped.
