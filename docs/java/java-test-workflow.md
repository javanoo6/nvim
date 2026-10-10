# Java Test Workflow

## Active IntelliJ workflow

- IntelliJ LSP owns Java editing and test compilation/classpaths. Neotest keeps
  its summary/output and nearest/file/package workflows through
  `util.neotest_intellij`, reusing neotest-java discovery and XML result readers.
- `<leader>tr/tt/tp/tT` run nearest/file/package/all tests; `td/tf/tP/tD` debug
  those selections using IntelliJ's JVM adapter and the default IntelliJ panel.
- `<leader>tF` reruns failed tests; `<leader>tq` runs file methods sequentially.
  Parameterized cases aggregate into their method status; a failing case makes
  that method fail. `to/tO` show output; `ts` toggles summary.
- Tests compile first through Maven/Gradle and then run via JUnit Console. Run
  `:NeotestJava setup` if its standalone jar is absent. No JDTLS is involved.
- App run/debug is complete in Step 5; remote attach was skipped in Step 6.
- Results and limits: [Step 7](intellij-lsp-step-7.md),
  [workspace/import helpers](intellij-lsp-step-8.md).
