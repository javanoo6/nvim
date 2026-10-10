# IntelliJ Migration — Step 7

Implemented on 2026-10-10. Step 6 was skipped; remote JVM attach remains unavailable.

## Active test workflow

- `util/neotest_intellij.lua` uses IntelliJ to import the owning project, resolve
  Maven/Gradle test compilation, and obtain its Java executable/test classpath.
- `neotest-java` supplies tree discovery and the existing XML result reader.
  Its JDTLS build/launch path is replaced. `nvim-java` stays disabled.
- Selected test files are saved before compilation. Compilation failure blocks
  execution. Tests run through the installed JUnit Console standalone jar;
  `:NeotestJava setup` installs it when missing.
- Compiled method signatures come from the project's JDK `javap`, including
  parameter types needed to select parameterized methods.
- Existing nearest/file/package/all, last/failed rerun, sequential, summary,
  and output mappings remain. Debug selections launch ConsoleLauncher using
  the source workspace's `intellij_jvm` adapter and IntelliJ debug panel.
- Parameterized invocations aggregate into the method node. One failing case
  makes that method fail; XML supplies its failure messages and source lines.

## Verified

- Maven and Gradle JUnit fixtures: passing, failing, and parameterized methods;
  nearest parameterized selection; file/package runs; failed reruns; sequential
  file execution; summary and captured output.
- Real Neotest DAP execution on both build tools: stopped at a test breakpoint,
  continued, and recorded a passing result.
- Mixed passing/failing parameterized cases: method reports failure with the
  failing invocation's message.
- `make check` passed formatting and Selene during validation.

## Limits

- This is a local Neotest bridge, not a native IntelliJ Neotest adapter. IntelliJ
  advertises test discovery/launch commands; the chosen bridge retains the
  repository's existing discovery/result behavior and JUnit Console execution.
- Validated on conventional Maven/Gradle `src/test` source roots and JUnit 5.
  Module grouping follows those roots. JPMS module-path tests fail explicitly.
- Custom source sets, TestNG, dynamic/inherited tests, overloaded test methods,
  and multi-module reactor behavior need separate validation. Discovery IDs
  do not distinguish same-name overloaded methods; `javap` selects the first.
- These fixture checks do not establish full cloudos suite compatibility.
- JUnit Console 6.0.3 is installed locally; fixtures use JUnit Jupiter 5.11.4.
