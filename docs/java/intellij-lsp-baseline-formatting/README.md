# Formatter Baseline Fixtures

- Captured on 2026-10-10 using the existing daemon jar and repo `.editorconfig`.
- `input/` contains deliberately unformatted samples; `output/` contains the
  first invocation's actual result. Do not auto-format these comparison files.
- All six first and second invocations returned exit code 0.
- All outputs were unchanged by a second invocation.

| File | First invocation changed text |
| --- | --- |
| `Baseline.java` | Yes: reformat, import cleanup/sort, member rearrangement |
| `baseline.md` | Yes |
| `baseline.xml` | Yes |
| `baseline.py` | No |
| `baseline.yaml` | No |
| `baseline.sh` | No |

- Unchanged Python/YAML/shell samples include visible formatting issues. Record
  this as a baseline coverage gap, rather than treating success exit codes as
  proof that the bundled engine formats these languages.
- Full environment, hashes and migration implications:
  [Step 1 baseline](../intellij-lsp-baseline.md).
