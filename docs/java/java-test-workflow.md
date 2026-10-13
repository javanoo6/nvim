# Java Test Workflow

IntelliJ resolves project import, test compilation, JDK, and classpaths.
`util.neotest_intellij` retains Neotest's UI and uses neotest-java discovery/XML
result readers. Selected test files are saved before Maven/Gradle compilation;
build failure blocks execution. Tests run through JUnit Console. Use
`:NeotestJava setup` if its standalone jar is missing.

| Keys                                                      | Action                                 |
|-----------------------------------------------------------|----------------------------------------|
| `<leader>tr` / `<leader>tt` / `<leader>tp` / `<leader>tT` | Run nearest / file / package / all     |
| `<leader>td` / `<leader>tf` / `<leader>tP` / `<leader>tD` | Debug those selections                 |
| `<leader>tF`                                              | Rerun failed tests in the active scope |
| `<leader>tq`                                              | Run file methods sequentially          |
| `<leader>to` / `<leader>tO`                               | Show output / toggle output panel      |
| `<leader>ts`                                              | Toggle summary                         |

Debug selections use the owning workspace's IntelliJ JVM adapter and panel.
They close the test summary and never auto-open it; `<leader>ts` opens it manually.
Compiled method signatures come from the project's `javap`. Parameterized cases
aggregate into their method status; any failing case makes the method fail.

The bridge has been checked with conventional Maven/Gradle `src/test` layouts
and JUnit 5. JPMS module-path tests fail explicitly. Custom source sets, TestNG,
dynamic/inherited tests, and multi-module reactor behavior require separate
validation. Discovery IDs do not distinguish same-name overloaded methods;
signature selection uses the first matching method.

See [Java workflow](java-workflow.md) for workspace actions and
[debugging](java-debugging.md) for breakpoint and panel controls.
