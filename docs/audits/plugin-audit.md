# Neovim Plugin Audit Backlog

Date: 2026-06-09

Purpose: active follow-up list after the plugin audit cleanup passes. Completed
items and stale observations were removed so this file only tracks work still
worth implementing or deliberately closing.

## High Priority

No active high-priority plugin-audit items remain.

## Syntax And UI

- [ ] Decide whether `nvim-treesitter-textobjects` and `mini.ai` both need to
  remain active, or consolidate/document their distinct roles.
- [ ] Verify rainbow delimiter contrast across installed themes.
- [ ] Add a toggle for indent-blankline scope highlighting instead of keeping
  scope permanently disabled.
- [ ] Re-test `vim-illuminate` Treesitter provider after Treesitter updates.
  Keep the current LSP/regex-only provider setup if it still crashes.
- [ ] Improve theme refresh hooks for diagnostics, references, rainbow
  delimiters, and Notify background after colorscheme switches.

## Java

- [ ] Keep Spring Boot command-failure suppression documented and remove it if
  upstream fixes the bridge.
- [ ] Keep `neotest-java` fast-event/fallback docs current.
- [ ] Re-test JDTLS parameter-name inlay hints after JDTLS/Neovim updates.
  Remove Noice inlay-error suppression if the extmark issue is gone.
- [ ]  https://github.com/testcontainers/testcontainers-java
- [ ] Run a real Java project smoke test: JDTLS attach, `:JavaInfo`,
  `<leader>jr`, `<leader>jd`, and Neotest Java.

## Go

- [ ] Pin `gotest.tools/gotestsum` in `neotest-golang` or document that the
  build step intentionally tracks `@latest`.
- [ ] Add Delve setup notes to prerequisites.
- [ ] Decide and document the Go formatting workflow: manual Conform chain,
  gopls, or both.
- [ ] Run a real Go project smoke test: gopls attach, Go test, Go debug, and
  struct-tag helpers.

## Python

- [ ] Run a real Python project smoke test: select/create venv, Pyright attach,
  BasedPyright switch, pytest via Neotest, and DAP debug.
- [ ] Global `pytest` is not installed. This is acceptable if Python testing
  remains venv-based through `venv-selector.nvim` and `neotest-python`;
  close this once a venv-based smoke test is documented.

## Navigation And Files

- [ ] Revisit Telescope preview filtering. The current extension allowlist avoids
  binary previews but hides extensionless scripts and uncommon source files.
- [ ] Make Telescope prompt prefix/selection caret visible enough across themes.
- [ ] Move growing Neo-tree custom command logic into `lua/util/neo_tree.lua` if
  it expands further.
- [ ] Audit whether staying on Harpoon v1 `master` is intentional.
- [ ] Check whether `project.nvim` `VimEnter` behavior conflicts with custom
  root/cwd helpers.

## Testing And Debugging

- [ ] Verify `util.neotest_scope.activate_scope()` changing global cwd does not
  fight Neo-tree, Telescope cwd, or `project.nvim`. Prefer scoped adapter
  args if possible.
- [ ] Add a small manual test matrix for Java, Go, and Python Neotest workflows.

## Editing Helpers

- [ ] Add language-specific `nvim-autopairs` disabled nodes if Treesitter-aware
  pairing inserts quotes/brackets in bad places.
- [ ] Configure `better-escape.nvim` sequence and timeout explicitly if the
  default causes accidental exits.
- [ ] Audit motion keys `s`, `S`, `r`, `R`, and `m` for conflicts with desired
  native/operator workflows.
- [ ] Review smaller helper plugin keymaps against which-key docs:
  `marks.nvim`, `undotree`, `quicker.nvim`, `grug-far.nvim`,
  `todo-comments.nvim`, `toggleterm.nvim`, and `auto-save.nvim`.

## Sessions And Terminals

- [ ] Replace `auto-save.nvim` access to
  `require("lazy.core.config").plugins[...]` with a local option wrapper.
- [ ] Add a split terminal command if long-running logs are common; current
  Toggleterm default is float-only.

## External Services

- [ ] Ensure LeetCode cookie storage is ignored by git and never logged.
- [ ] Decide whether `/home/konkov/Obsidian` should stay hardcoded or become an
  environment-variable/user-option path.

## Residual Verification

- [ ] Project-specific Java/Python/Go run-debug-test workflows were not executed
  during the audit. Command, module, and tool availability were
  smoke-tested instead.
- [ ] Remaining `:checkhealth` warnings are optional ecosystem checks:
  Mason reports missing unconfigured PHP/Composer/Julia/luarocks workflows,
  and which-key reports optional `mini.icons` is absent.
