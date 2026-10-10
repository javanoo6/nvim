# Step 5 — Java Run/Debug and Default IntelliJ DAP UI

- Status: complete for the checked fixtures; Step 4 formatting gaps remain open.
- Checked on 2026-10-10 with plugin `9cfad18005470e4187090013e08f92ec9e437219`
  and server `263.6379.0`.
- Evidence: [runtime results](intellij-lsp-step-5-evidence.json).
  Disposable fixtures: `/tmp/nvim-intellij-step5-9bbi2qm3`.

## Workflow

- `<leader>jr`: run the Java class enclosing the cursor.
- `<leader>jd`: debug that class; existing breakpoint/stepping keys apply.
- `<leader>jc`: stop a pending Java build or IntelliJ Java session.
- `<leader>jl`: toggle the shared IntelliJ import/build/program output panel.
- `:IntellijLspRun` / `:IntellijLspDebug`: equivalent launches. Add `!` to
  explicitly skip building. Unsupported build resolution otherwise blocks launch.
- `<leader>du`: toggle IntelliJ's debug panel for any DAP adapter.
- `<leader>dU`: toggle keeping the panel open after exit.
- `<leader>de`: evaluate the source expression or visual selection.
- Panel keys: Enter/Tab expand values or select frames; `e` evaluate; `w` watch;
  `dd` remove watch; `c/n/i/o` continue/step over/into/out; `q` close.

## Implementation Decisions

- User preference replaces the earlier plan to retain nvim-dap-ui: IntelliJ's
  stack/locals/watches panel is now the default globally. nvim-dap-ui is disabled.
  DAP REPL, virtual text/secret masking, and Go/Python adapters remain configured.
- `util.debug_ui` installs the upstream panel independently of the plugin's
  Java run/debug defaults, preserving our mappings. It closes on exit unless
  keep-open is enabled. Source-window routing avoids debug/output panels and REPL.
- `util.java_launch` captures the source buffer and cursor before async symbol
  resolution. It uses the source workspace for build/launch resolution and embeds
  that client ID/root in the DAP configuration for adapter startup and run-last.
  Upstream's first-global-client lookup is bypassed, including its run lens handler.
- Source is saved before requesting the build command. Maven/Gradle compilation
  streams into the output panel; nonzero exit, spawn failure, or unavailable build
  resolution blocks launch. One pending build/launch is allowed at a time. Stop
  kills the build process and waits for its completion before permitting another.
- IntelliJ resolves the JDK, classpath/module paths, working directory, and VM
  arguments. The adapter uses `internalConsole` so stdout/stderr reach the panel.
  Optional helper arguments allow `vmArgs`, `args`, `cwd`, `env`, and `build=false`;
  VM argument overrides are tested, other overrides remain unverified.
- Plain-JVM launching supports the checked Spring Boot main class. This does not
  invoke `bootRun`, `spring-boot:run`, or an IntelliJ persisted run configuration.
- Upstream `run=false/debug=false` remain intentional: our scoped setup owns the
  commands, adapter, UI listeners, and keys. Upstream main run code lenses remain
  disabled; the scoped handler is prepared for any explicit command invocation.

## Validation

- Full configuration startup passes with the IntelliJ adapter/panel registered
  and nvim-dap-ui unloaded. `make check` and `git diff --check` pass.
- Maven and Gradle: compile before debug; breakpoint hit; stack/scopes/variables;
  panel displays `value = 41`; step over changes it to `42`; evaluation returns
  expected values; continue exits. Run output verifies dependency classpath,
  packaged resources, project working directory, and `-Dprobe=works`.
- Deliberate compilation errors block launch and appear in the build panel for
  both build tools. Cancellation uses a synthetic build-command response with
  a real sleeping subprocess; stop terminates it without launching a JVM.
- Two Maven workspaces in one Neovim: launching the second then switching to the
  first keeps build/launch/adapter requests on the second client; stop, debug
  relaunch, breakpoint, and stop again pass.
- Dependency stepping enters `StringUtils.upperCase` at line 9384 and opens its
  attached source jar as a 9602-line buffer. The separate DAP source request
  returns no content; navigation uses the jar URI/source reader.
- Python/debugpy: the same panel displays locals, toggles, and closes on exit;
  no nvim-dap-ui load. Go adapter setup is retained; live Go debugging is untested.
- Minimal Maven Spring Boot 3.4.1: application context starts, prints
  `BOOT_READY=true`, closes, and exits successfully through the plain JVM launch.
- Early test runs invoked Java keys from the import/output buffer, and a recorder
  tried to serialize circular DAP frame objects. The harness now restores source
  focus and serializes safe snapshots. Those failed runs are excluded from evidence.

## Limits

- The panel shows one stopped thread and the first scope; no thread/scope selector.
  Locals/frame values clear on termination even with keep-open enabled, while
  watch expressions persist. UI interactions are checked headlessly, not through
  physical keyboard use. Long-running Gradle daemon cancellation is unverified.
- Launch selection uses the class at the cursor, with no main-class picker;
  nested main classes and persisted IDE run configurations remain untested.
- Spring Boot web services, custom profiles, build-tool run-task arguments, and
  the user's cloudos application are unverified. Dependency binaries without
  attached sources retain the Step 3 decompilation limitations.
- Remote attach remains Step 6. JUnit/Neotest execution and debugging remain Step 7.
