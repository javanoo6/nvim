# Neovim Session Context

Purpose: one high-signal reference for local behavior that differs from upstream
plugin defaults, repo-specific helpers, and explicit design decisions.

Update this file when:

- a key behavior differs from upstream plugin defaults
- you add repo-specific helper code or workflow glue
- you make a decision that future sessions should preserve

## Start Here

- [docs/core/crash-course.md](/home/konkov/.config/nvim/docs/core/crash-course.md:1): practical usage guide
- [docs/core/plugin-map.md](/home/konkov/.config/nvim/docs/core/plugin-map.md:1): plugin inventory and wiring
- [docs/core/nvim-nav.md](/home/konkov/.config/nvim/docs/core/nvim-nav.md:1): focused navigation cheat sheet
- [docs/python/python-venv-behavior.md](/home/konkov/.config/nvim/docs/python/python-venv-behavior.md:1): Python venv behavior

## Input Model

- Direction model is intentionally nonstandard:
  `h = left`, `j = up`, `k = down`, `l = right`
- `<leader>` is space, and the `<Space>` placeholder mapping is defined in
  [lua/config/options.lua](/home/konkov/.config/nvim/lua/config/options.lua:1)
  before plugin setup so `which-key` can install its trigger mapping correctly.
- Which-key declares `<leader>` as an explicit manual trigger and wraps
  `which-key.triggers.suspend()` with a same-mode reattach guard. This prevents
  leader-prefix popups from going dead after a popup timeout/cancel path until
  Neovim is restarted.
- Diffview close also refreshes which-key trigger state through
  [lua/util/which_key_refresh.lua](/home/konkov/.config/nvim/lua/util/which_key_refresh.lua:1).
  This covers the case where Diffview closes windows/tabs and mappings still
  execute but the `<leader>` popup no longer appears. `:WhichKeyRefresh` rebuilds
  the current buffer manually.
- which-key now also seeds the current buffer once after setup, because session
  restore can enter a buffer before which-key's first `BufEnter` attach runs.
  Without that explicit refresh, the live buffer can stay on the plain
  `<Space> -> <Nop>` placeholder and `<leader>` will not pop up which-key until
  the buffer is re-entered.
- Node, Perl, Python 3, and Ruby remote-plugin providers are intentionally disabled
  because this config does not use provider-backed remote plugins; this keeps
  `:checkhealth` focused on relevant integrations.
- Clipboard setup is explicit in
  [lua/util/clipboard.lua](/home/konkov/.config/nvim/lua/util/clipboard.lua:1):
  detected tools are stored as absolute commands before `unnamedplus` is enabled,
  and Neovim falls back to plain registers when no system clipboard tool is
  available. This avoids popup/message yank failures from stale or narrowed
  runtime `PATH` values.
- `timeoutlen` is intentionally set to `500` to make leader sequences less
  timing-sensitive with the heavy `<leader>` workflow.
- Mouse support is disabled by default (`mouse=`) and can be toggled with
  `<leader>um` for temporary GUI/terminal mouse use.
- Plain `j/k` are remapped in [lua/config/keymaps.lua](/home/konkov/.config/nvim/lua/config/keymaps.lua:61).
- Modifier variants are aligned to the same model where practical:
  `<C-j>` upper window, `<C-k>` lower window, `<A-j>` move line/selection up,
  `<A-k>` move line/selection down.
- Telescope was patched locally so `<C-j>` means previous/up and `<C-k>` means
  next/down in pickers. See [lua/plugins/editor.lua](/home/konkov/.config/nvim/lua/plugins/editor.lua:186).
- Glance is configured consistently: `j` previous/up, `k` next/down. See
  [lua/plugins/glance.lua](/home/konkov/.config/nvim/lua/plugins/glance.lua:48).
- Glance is pinned to the fork branch `javanoo6/glance.nvim` /
  `fix/fs-read-nil-glance-list` because upstream `list.lua` can crash when
  `vim.loop.fs_read()` returns `nil` for bad `file://` locations from some
  LSPs (seen with Helm/YAML).
- Glance `winbar` is intentionally disabled. Its winbar renderer forwards
  decompiled `jdt://...` Java paths through the statusline parser without
  escaping percent-encoded segments, which breaks JDK/decompiled navigation
  with `E539`. See [lua/plugins/glance.lua](/home/konkov/.config/nvim/lua/plugins/glance.lua:104).
- There is no global Neovim switch that forces all plugins to reinterpret
  `j/k`; plugin-local mappings still need explicit overrides when they diverge.

## Core Editing Deviations

- `$` and `^` are swapped from upstream Vim behavior:
  `$` goes to first non-blank, `^` goes to end of line.
- Plain `j/k` use wrapped display-line movement when no count is given, but
  counted forms use real-line movement. This keeps `5j`, `10k`, etc. sane.
- `<C-s>` saves in insert/normal/visual/select modes.
- `<C-d>` duplicates line or selection instead of default half-page scroll.
- `J` is remapped to join lines while preserving cursor position.
- Visual-mode Treesitter selection on `<Tab>` / `<S-Tab>` uses the live visual
  anchor plus cursor position, not `'<` / `'>` marks, because those marks can
  still be unset while a visual mapping is executing.
- Treesitter incremental selection starts from normal mode with `<CR>` or
  `<A-o>`, expands in visual mode with `<CR>`, `<Tab>`, or `<A-o>`, shrinks with
  `<S-Tab>` or `<A-i>`, and moves to the next sibling with `<BS>`.
- `<leader>b-` and `<leader>b|` do not open a fresh empty split in place.
  They create the split and move the current buffer into the new lower/right
  window, leaving the newly created empty buffer behind in the original window.

## File / Root / Explorer Decisions

- Neo-tree and file finding are split by scope:
  `<leader>e` uses current explorer cwd, `<leader>E` uses project root.
- Telescope grep defaults to literal ripgrep matching for the main grep keys:
  `<leader>fg` cwd, `<leader>fG` root, and `<leader>fe` by extension all pass
  `--fixed-strings`. Regex grep is explicit on `<leader>f/` cwd,
  `<leader>f?` root, and `<leader>fE` by extension.
- Neo-tree sidebar cwd is intentionally tied to global cwd to avoid stale
  tab-local reopen behavior.
- Neo-tree does not auto-follow the current file on buffer switches. In large
  monorepos this keeps the sidebar/root stable while opening buffers; scope
  changes stay explicit via `<leader>e`, `<leader>E`, or `.` inside Neo-tree.
- Neo-tree reopen behavior reveals the current file by default when opened via
  `<leader>e` or `<leader>E`, without enabling full `follow_current_file`.
  `<leader>ue` toggles that reveal-on-open behavior for the current session.
- `project.nvim` runs in manual mode. Opening files, including Python files in
  nested monorepo packages, must not auto-`cd` the session; use explicit root
  changes instead.
- Neo-tree `Y` copies the selected absolute path to the `+` clipboard register
  when available and falls back to the unnamed register with a warning when the
  system clipboard is unavailable.
- Root detection policy is documented separately in
  [docs/core/root-detection-policy.md](/home/konkov/.config/nvim/docs/core/root-detection-policy.md:1).
- Python actions live under `<leader>p`: `ps` select venv, `pc` create venv,
  `pr` recreate venv, `pi` install default deps into the active venv, `pI`
  prompt for custom `pip install ...` args. Python terminals inherit the
  selected env, the current env name is shown in lualine for Python buffers,
  and Python LSP clients are restarted on venv switch so Pyright picks up the
  new interpreter. There is a repo-local extra search for managed envs under
  `~/.local/share/nvim/python-venvs`. That search uses an explicit resolved
  `fd`/`fdfind` path at startup so env discovery does not depend on the shell
  `PATH` that launched Neovim.
- When a Python venv is activated, `${project_root}/.env` is loaded into
  Neovim's process environment if present. New terminals, neotest runs, and
  other future jobs spawned by Neovim inherit those variables.
- Plugin management moved to `<leader>P`; `<leader>Pl` opens Lazy.
- Lazy.nvim rocks support is disabled because no configured plugin requires
  luarocks/hererocks.
- Python linting uses `nvim-lint` with `ruff`, but local lint startup now
  skips any linter whose executable is missing instead of surfacing `ENOENT`
  when opening a buffer before Mason or a venv provides that tool.
- Lua linting uses `nvim-lint` with Selene, but Selene is launched from the
  repo root so the local `selene.toml` and `vim.yml` stdlib are visible and
  `vim` is not flagged as an undefined global.
- Markdown linting uses Mason `markdownlint-cli2`, but routes it through the
  Node binary bundled with Mason `basedpyright` when available because the
  installed `markdownlint-cli2` release requires newer JavaScript regex support
  than the system Node 18 provides.
- Python LSP defaults to Pyright. BasedPyright is installed/configured but
  opt-in through `:PythonLspUseBasedPyright`; use `:PythonLspUsePyright` to
  switch back without changing config files.
- Python formatting currently uses the repo-local IntelliJ formatter bridge
  (`idea_formatter`) rather than `black`; Mason installs `ruff` for Python
  linting but no longer installs `black`.
- `FormatDir` uses `fd`/`fdfind` with explicit directory excludes instead of a
  manual Lua recursive walker. It includes hidden files, respects ignore files
  such as `.fdignore`, and filters candidates through Conform's configured
  filetypes.
- `nvim-lint` still runs immediately after writes, but `BufReadPost` linting is
  debounced briefly so opening many files does not start expensive linters all at
  once.
- Debounced linting runs through `nvim_buf_call()` for the original event buffer,
  because `nvim-lint`'s `try_lint()` targets the current buffer. Without that,
  delayed Markdown lint jobs can attach markdownlint diagnostics to a newly
  opened Java buffer.
- Completion source ordering is filetype-aware: Markdown/text/gitcommit and
  shell/YAML prefer path-aware sources before buffer words, Python keeps LSP and
  signature help first, and buffer completion ignores buffers above 512 KiB.
- Local config quality checks are exposed through `make check`, which runs
  Mason-managed `stylua --check` and `selene` against `init.lua`, `lua/`, and
  `ftplugin/`. Selene uses the repo-local [vim.yml](/home/konkov/.config/nvim/vim.yml:1)
  standard library so the Neovim `vim` global is accepted.
- Neotest has a repo-local failed-test rerun helper at
  [lua/util/neotest_failed.lua](/home/konkov/.config/nvim/lua/util/neotest_failed.lua:1).
  `<leader>tF` reruns currently failed test positions from Neotest's cached
  results, limited to the active test scope/project root.
- `neotest-java` file detection is locally overridden at
  [lua/neotest-java/core/file_checker.lua](/home/konkov/.config/nvim/lua/neotest-java/core/file_checker.lua:1)
  so valid `src/test/java/*Test.java` files are not rejected when the adapter was
  constructed from a stale cwd outside the Java project.
- Formatter dependency status is exposed as `:FormatterInfo`. The IntelliJ
  formatter bridge now skips itself when `java` or the formatter jar is missing
  instead of failing late during format.
- Directory formatting commands are registered from
  [lua/util/format_dir.lua](/home/konkov/.config/nvim/lua/util/format_dir.lua:1)
  so [lua/plugins/formatting.lua](/home/konkov/.config/nvim/lua/plugins/formatting.lua:1)
  stays focused on Conform configuration.
- Format-on-save skips buffers with LSP errors and shows a Conform warning once
  per unchanged error state, so repeated saves do not spam notifications.
- Format-on-save uses a `10000ms` timeout for filetypes routed through the
  IntelliJ formatter bridge and `500ms` for other auto-formatted filetypes.
- Pyright is configured locally through `vim.lsp.config("pyright", ...)` with
  a resolved Mason absolute binary path, because current `mason-lspconfig`
  auto-enable behavior can otherwise bypass repo-local `cmd` customization.
  `:PyrightInfo` shows the exact command the current session will use.
- Remaining `:checkhealth` warnings after the audit are optional: Mason reports
  missing ecosystem runtimes for unconfigured PHP/Julia/luarocks workflows, and
  which-key reports optional `mini.icons` is absent while this config uses
  `nvim-web-devicons`.
- Lualine diagnostic and diff symbols intentionally use restrained ASCII labels
  (`E:`, `W:`, `I:`, `H:`, `+`, `~`, `-`) so they remain visible without
  depending on icon fonts or a specific theme.
- Lualine Java status intentionally stays a minimal colored `●`: green for
  attached/idle JDTLS, yellow when LSP status is busy, red when unavailable.
- `nvim-notify` background is derived from the active float/normal highlights
  via the local `NotifyBackground` refresh hook instead of a TokyoNight-specific
  hex color, so fade animations and popup contrast survive theme switches.
- Bufferline slant separators are tied to `TabLine` / `TabLineSel` /
  `TabLineFill` highlights rather than ad hoc colors so separators stay readable
  across the installed themes.
- Detailed Neo-tree cwd behavior is documented in
  [docs/core/neo-tree-cwd-behavior.md](/home/konkov/.config/nvim/docs/core/neo-tree-cwd-behavior.md:1).
- Oil is part of the core editing workflow. In oil buffers, delete/change
  behavior is intentionally restored so `dd` plus `p` works for moving entries.

## Java Stack: Local Solutions

- Java is not “stock lspconfig”; it is handled by `nvim-java` plus local helper
  code in `lua/util/java_*`.
- Java home resolution prefers `NVIM_JAVA_HOME`, then `JAVA_HOME`, then
  `/usr/lib/jvm/java-21-openjdk-amd64`.
- The local nvim-java JDTLS command/version patch is installed before
  `require("java").setup()` because auto-session can restore Java buffers during
  `VimEnter` and trigger JDTLS startup from inside nvim-java setup.
- `spring-boot.nvim` stays attached on Java buffers. A local patch wraps its
  `workspace/executeClientCommand` bridge so background Spring Boot command
  failures do not surface as `spring-boot: -32603: Internal error.` during Java
  rename/refactor flows.
- `nvim-java` client lookup is patched locally so Java run/debug/test/profile
  flows prefer the `jdtls` client attached to the current buffer instead of the
  first global `jdtls` client. Without this, opening multiple Java workspaces
  can make `<leader>jr` and related flows operate on the wrong project.
- For dual-build roots that contain both `pom.xml` and Gradle build files, the
  local JDTLS config forces Maven import on and Gradle import off for that
  workspace, and injects those import settings into
  `initializationOptions.settings` before JDTLS startup. This makes Maven the
  source of truth for main-class discovery and related Java run/debug flows in
  mixed-build projects like Spring Petclinic.
- `<leader>jr` is wrapped locally to wait briefly for `jdtls` attachment before
  invoking the Java runner. This avoids a silent no-op when the key is pressed
  immediately after opening a Java buffer in a fresh project.
- `<leader>jl` toggles the Java runner log window without stopping the running
  app. `<leader>jc` stops the app itself.
- `:JavaInitProject [dir]` / `<leader>ji` creates a small Java 21 Maven or
  Gradle project from local templates, opens `Main.java`, and changes Neovim's
  cwd to the new project root. It intentionally does not shell out to
  `mvn archetype` or `gradle init`.
- Java patch/workflow details live in the Java deep-dive docs listed below.
- Scratch-file behavior is customized for Java projects: the scratch flow prefers
  project-local `Scratch.java` under source roots so JDTLS resolves deps.
- The planned IntelliJ-like Java scratch work is tracked in
  [docs/java/java-scratch-roadmap.md](/home/konkov/.config/nvim/docs/java/java-scratch-roadmap.md:1).
- Planned Java lint work is tracked in
  [docs/java/java-inspection-lint-roadmap.md](/home/konkov/.config/nvim/docs/java/java-inspection-lint-roadmap.md:1).
- Planned IntelliJ Community inspection-engine research is tracked in
  [docs/java/java-intellij-inspection-engine-roadmap.md](/home/konkov/.config/nvim/docs/java/java-intellij-inspection-engine-roadmap.md:1).
- `<leader>fi` / `:ScratchInfo` reports the global scratch directory, Java
  project root, and resolved Java `Scratch.java` path for the current context.
- JDTLS is configured to download Maven dependency sources when available, so
  external libraries should open as real source before falling back to
  decompiled `jdt://...` class content.
- JDTLS runs with full-document sync (`allow_incremental_sync = false`) because
  the local custom JDTLS build can assert on incremental `didChange` edits and
  then report bogus parse errors around otherwise valid Java comments.
- There is an explicit workspace clean command exposed as `<leader>XC`.
- Java completion already applies JDTLS `additionalTextEdits`, so accepting a
  class completion item can add the matching import. For pasted unresolved class
  names, `<leader>ci` imports the symbol under the cursor, auto-applying a
  single JDTLS `Import '<symbol>' (...)` quickfix or prompting when multiple
  candidates exist. `<leader>cI` walks current-buffer Java diagnostics,
  auto-applies unambiguous imports, and prompts only for ambiguous import
  candidates. Bulk organize-import cleanup remains delegated to the IntelliJ
  formatter bridge, not an LSP keymap.
- Neotest scope, discovery filtering, package/file target resolution, and the
  guarded current-file discovery fallback live in
  [lua/util/neotest_scope.lua](/home/konkov/.config/nvim/lua/util/neotest_scope.lua:1).
- Neotest run wrappers capture the source buffer/path before opening Neotest UI
  windows, then resolve file/package targets from that captured path. This keeps
  `<leader>tt`, `<leader>tf`, `<leader>tp`, and `<leader>tP` aimed at the test
  file that had focus when the key was pressed, even when split/UI window changes
  leave another buffer visible or current.
- The Neotest summary window uses the repo-local opener in
  [lua/util/neotest_summary.lua](/home/konkov/.config/nvim/lua/util/neotest_summary.lua:1):
  it opens as a right-side vertical split sized to one third of the screen by
  default, or one quarter when the current tab already has two or more vertical
  file-buffer columns.
- `<leader>tt` for Java starts one `neotest-java` JUnit Console command for the
  current file/class target, not one Neovim-spawned process per test method.
  Method execution order is controlled by JUnit/project settings, but Neotest
  summary results are populated only after `neotest-java` reads the completed
  JUnit XML reports, so `<leader>ts` may update at class/file completion rather
  than after each method.
- `<leader>tq` uses [lua/util/neotest_sequential.lua](/home/konkov/.config/nvim/lua/util/neotest_sequential.lua:1)
  to collect discovered `test` nodes under the current file and run them one by
  one. It is generic Neotest plumbing, but Java is the main supported use case;
  adapters must support running individual test-node IDs for it to behave well.

## LSP / UI Decisions

- LSP “go to” flows prefer Glance over raw jumps for defs/refs/types/impls.
- Code actions use `actions-preview.nvim` for richer UI and diff-backed actions.
  If `actions-preview.nvim` or its Telescope-backed setup fails,
  `<leader>ca`/`<A-CR>` fall back to native `vim.lsp.buf.code_action()`.
- LSP rename refreshes loaded inlay-hint buffers after the rename response is
  handled, so renamed variables do not leave stale inlay hints behind.
- Inline diagnostics are provided by `tiny-inline-diagnostic.nvim`, enabled on
  LSP attach, and toggled with `<leader>ud`.
- LSP inlay hints render at end-of-line through `nvim-lsp-endhints` instead of
  Neovim's native inline positions. This avoids inline hint text colliding with
  renamed/edited variables while preserving the normal `vim.lsp.inlay_hint`
  enable/disable API and the local `<leader>uh` toggle. `nvim-lsp-endhints` is
  loaded as a `nvim-lspconfig` dependency so its handler override is installed
  before `LspAttach` enables hints.
- Noice is allowed to own command/message UI, but hover/signature rendering is
  intentionally disabled there to avoid conflicts with the chosen editing setup.
- `<C-CR>` and `<leader>Hy` open Yanky's Telescope `yank_history` picker through
  [lua/util/yank_history.lua](/home/konkov/.config/nvim/lua/util/yank_history.lua:1).
- `<C-A-CR>` opens Yanky's built-in ring-history picker. Dressing has a
  prompt-specific override for `Ring history>` so this picker uses a larger
  no-preview horizontal Telescope window (`80%` width, `70%` height) without
  changing other select prompts.
- LSP hover and signature-help floats use rounded borders through explicit
  `vim.lsp.handlers` configuration; `vim.lsp.util.open_floating_preview` is not
  monkey-patched globally.
- Reference highlighting style is managed locally in `util/init.lua`, not left to
  plugin defaults.
- UI/highlight conflict inspection is centralized in
  [lua/util/ui_debug.lua](/home/konkov/.config/nvim/lua/util/ui_debug.lua:1).
  Use `:UiInspect` or `<leader>ui` to open a cursor-position report covering
  `vim.inspect_pos()`, Treesitter captures, parser state, diagnostics, conceal,
  and the current colorscheme.
- Buffer-local noisy-layer toggles are available as `:UiToggleTreesitter`
  (`<leader>uT`) and `:UiToggleIlluminate` (`<leader>uI`).
- Treesitter highlighting remains enabled for Markdown and YAML, but Treesitter
  indentation is not forced for those filetypes because it is more likely to
  fight prose/list indentation and YAML alignment.
- Manual Treesitter startup is guarded with `pcall`; if a parser is broken or
  missing, editing continues and a per-filetype warning is shown instead of
  raising from the `FileType` autocmd.
- Treesitter incremental selection mappings call Neovim's built-in
  `vim.treesitter._select` module directly.
- DAP virtual text masks values when the variable name or rendered value
  contains common secret terms: `secret`, `api_key`, `apikey`, `token`,
  `password`, `passwd`, `credential`, or `authorization`.
- DAP UI opens on session start and closes on termination by default.
  `<leader>dU` toggles keeping DAP UI open after session exit for final-state
  inspection.

## Git / Merge Decisions

- Diffview is the primary repo/file history and merge-view tool.
- LazyGit is customized via both user config and repo-local
  [lazygit/config.yml](/home/konkov/.config/nvim/lazygit/config.yml:1).
- LazyGit uses an explicit dark selected-line background in the repo-local
  config so green diff text remains readable while staging hunks from the TUI.
- Gitsigns hunk commands are intentionally buffer-local and grouped under
  `<leader>Gh*`.
- Gitsigns uses visible but quiet delete/topdelete signs instead of empty delete
  markers, so removed-line context is visible in the sign column.
- Live git hunks view is repo-local glue in
  [lua/util/live_hunks.lua](/home/konkov/.config/nvim/lua/util/live_hunks.lua:1).
  `<leader>ug` / `:LiveHunksToggle` opens a right-side scratch buffer for the
  current file's unstaged hunks. It uses Gitsigns `get_hunks()` first, falls
  back to `git diff --unified=0`, and keeps one scratch row per source line so
  `WinScrolled` can sync the view topline with the edit window.
- Diffview branch/ref helpers use structured `vim.cmd.DiffviewOpen(...)` calls
  for dynamic ref arguments.
- Planned work:
  [docs/plans/code-action-cleanup-highlight-plan.md](/home/konkov/.config/nvim/docs/plans/code-action-cleanup-highlight-plan.md:1)
  tracks code-action cleanup highlighting, and
  [docs/plans/live-hunks-view-plan.md](/home/konkov/.config/nvim/docs/plans/live-hunks-view-plan.md:1)
  tracks the right-side live hunks view.

## External Workflow Helpers

- LeetCode DSA roadmap selection/query logic lives in
  [lua/util/leetcode_roadmap.lua](/home/konkov/.config/nvim/lua/util/leetcode_roadmap.lua:1);
  [lua/plugins/leetcode.lua](/home/konkov/.config/nvim/lua/plugins/leetcode.lua:1)
  only handles plugin setup, cookie refresh, and keymaps.

## Deep-Dive Docs

- Navigation and usage:
  [docs/core/crash-course.md](/home/konkov/.config/nvim/docs/core/crash-course.md:1)
  [docs/core/nvim-nav.md](/home/konkov/.config/nvim/docs/core/nvim-nav.md:1)
  [docs/core/notation-reference.md](/home/konkov/.config/nvim/docs/core/notation-reference.md:1)
- Plugin wiring:
  [docs/core/plugin-map.md](/home/konkov/.config/nvim/docs/core/plugin-map.md:1)
- Root/workspace behavior:
  [docs/core/root-detection-policy.md](/home/konkov/.config/nvim/docs/core/root-detection-policy.md:1)
  [docs/core/neo-tree-cwd-behavior.md](/home/konkov/.config/nvim/docs/core/neo-tree-cwd-behavior.md:1)
  [docs/python/python-venv-behavior.md](/home/konkov/.config/nvim/docs/python/python-venv-behavior.md:1)
- Java-specific custom work:
  [docs/java/java-debugging.md](/home/konkov/.config/nvim/docs/java/java-debugging.md:1)
  [docs/java/java-leetcode-debugging.md](/home/konkov/.config/nvim/docs/java/java-leetcode-debugging.md:1)
  [docs/java/nvim-java-patches.md](/home/konkov/.config/nvim/docs/java/nvim-java-patches.md:1)
  [docs/java/java-test-workflow.md](/home/konkov/.config/nvim/docs/java/java-test-workflow.md:1)
  [docs/java/neotest-java-fast-event-fix.md](/home/konkov/.config/nvim/docs/java/neotest-java-fast-event-fix.md:1)
  [docs/java/lua-lsp-and-java-fixes.md](/home/konkov/.config/nvim/docs/java/lua-lsp-and-java-fixes.md:1)
