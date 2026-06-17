# Java IntelliJ Inspection Engine Roadmap

Purpose: investigate using IntelliJ IDEA Community's inspection engine from
Neovim for richer Java diagnostics than Checkstyle, PMD, SpotBugs, and JDTLS can
provide alone.

This is separate from the immediate Java linter work because it is likely to be
slower, heavier, and more sensitive to IntelliJ project indexing behavior.

## Target Model

- Use IntelliJ IDEA Community inspection engine or a Qodana-like invocation from
  an explicit Neovim command.
- Reuse project inspection profiles when available.
- Emit machine-readable reports.
- Convert reports into quickfix entries first, diagnostics later if practical.

Non-goals:

- Do not run IntelliJ inspections on save.
- Do not depend on proprietary IntelliJ IDEA Ultimate features.
- Do not block Checkstyle, PMD, or SpotBugs integration on this research.

## Phase 1: Entry Point Research

Find the smallest reliable headless path for running IntelliJ inspections
against a Java project.

Candidates:

- IntelliJ IDEA Community command-line inspection runner.
- Qodana-style invocation if it can run locally with acceptable setup.
- Direct Community source entry point only if packaged CLI behavior is
  insufficient.

Questions:

- Which executable is available locally?
- Can it run against Maven/Gradle projects without opening the IDE UI?
- Does it require prior project indexing?
- Does it support explicit inspection profiles?
- What report formats are supported: XML, JSON, plain text?

Acceptance checks:

- `:JavaInspectInfo` can report whether the engine is available.
- A manual shell command can inspect one real Java project.
- Output is deterministic enough to parse.

## Phase 2: Report Parsing

Map inspection output into Neovim navigation.

Initial target:

- quickfix entries with file, line, column, severity, inspection id, and message

Later target:

- optional diagnostics namespace for current-buffer findings

Acceptance checks:

- Paths map back to real project files.
- Findings are grouped under a clear source name such as `intellij-inspections`.
- Multiline descriptions are shortened without losing the actionable message.

## Phase 3: Neovim Commands

Add a helper module, probably `lua/util/java_inspections.lua`.

Commands:

- `:JavaInspectInfo`
- `:JavaInspectProject`
- `:JavaInspectFile` only if the engine supports narrow scopes cheaply

Behavior:

- Commands are explicit and manual.
- Results go to quickfix.
- Missing executable/profile/project state is reported without noisy stack
  traces.

Acceptance checks:

- `:JavaInspectProject` does not mutate project files.
- The command can be cancelled or at least does not block the UI indefinitely.
- Quickfix entries jump to the correct files.

## Phase 4: Profile Support

Support project or user inspection profiles.

Discovery:

- project `.idea/inspectionProfiles`
- user-provided profile path
- default engine profile only as a fallback

Acceptance checks:

- `:JavaInspectInfo` reports selected profile.
- Users can override profile without editing Lua code.
- Missing profiles fail clearly.

## Phase 5: Overlap Audit

Compare IntelliJ inspection output against:

- JDTLS diagnostics
- Checkstyle
- PMD
- SpotBugs

Acceptance checks:

- Obvious duplicate categories are documented.
- The command remains useful enough to justify the startup/indexing cost.
- Save-time lint remains limited to lightweight Java linters.

## Recommended Implementation Order

1. Find and document the working CLI/headless invocation.
2. Add `:JavaInspectInfo`.
3. Add manual `:JavaInspectProject` that writes quickfix entries.
4. Add profile discovery/override support.
5. Audit overlap with JDTLS, Checkstyle, PMD, and SpotBugs.
6. Consider diagnostics integration only after quickfix output is stable.

