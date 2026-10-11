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
- [docs/core/buffers-windows-tabs.md](/home/konkov/.config/nvim/docs/core/buffers-windows-tabs.md:1): buffer/window/tab mental model
- [docs/git/fix-empty-git-object-lazygit-crash.md](/home/konkov/.config/nvim/docs/git/fix-empty-git-object-lazygit-crash.md:1): LazyGit/Git recovery for empty
  object files
- [docs/python/python-venv-behavior.md](/home/konkov/.config/nvim/docs/python/python-venv-behavior.md:1): Python venv behavior

## Input Model

- Direction model follows standard Vim movement:
  `h = left`, `j = down`, `k = up`, `l = right`
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
- `smoothscroll` is enabled for smoother wrapped-line scrolling on supported
  Neovim versions.
- Mouse support is disabled by default (`mouse=`) and can be toggled with
  `<leader>um` for temporary GUI/terminal mouse use.
- Plain `j/k` are remapped in [lua/config/keymaps.lua](/home/konkov/.config/nvim/lua/config/keymaps.lua:61).
- Modifier variants are aligned to the same model where practical:
  `<C-j>` lower window, `<C-k>` upper window, `<A-j>` move line/selection down,
  `<A-k>` move line/selection up.
- `[w` and `]w` cycle to the previous/next window. They complement spatial
  window movement on `<C-h/j/k/l>`, while preserving the bracket-prefix pattern
  used by buffer and tab navigation.
- Telescope is configured so `<C-j>` means next/down and `<C-k>` means
  previous/up in pickers. See [lua/plugins/editor.lua](/home/konkov/.config/nvim/lua/plugins/editor.lua:186).
- Glance is configured consistently: `j` next/down, `k` previous/up. See
  [lua/plugins/glance.lua](/home/konkov/.config/nvim/lua/plugins/glance.lua:48).
- Glance is pinned to the fork branch `javanoo6/glance.nvim` /
  `fix/fs-read-nil-glance-list` because upstream `list.lua` can crash when
  `vim.loop.fs_read()` returns `nil` for bad `file://` locations from some
  LSPs (seen with Helm/YAML).
- Glance `winbar` is intentionally disabled. Its winbar renderer forwards
  decompiled `jdt://...` Java paths through the statusline parser without
  escaping percent-encoded segments, which breaks JDK/decompiled navigation
  with `E539`. See [lua/plugins/glance.lua](/home/konkov/.config/nvim/lua/plugins/glance.lua:104).
- Plugin-local mappings still need explicit overrides when their default
  `j/k` or `<C-j>/<C-k>` behavior diverges from this config's movement model.

## Core Editing Deviations

- `$` and `^` are swapped from upstream Vim behavior:
  `$` goes to first non-blank, `^` goes to end of line.
- Plain `j/k` use wrapped display-line movement when no count is given, but
  counted forms use real-line movement. This keeps `5j`, `10k`, etc. sane.
- `<C-s>` saves in insert/normal/visual/select modes.
- `<C-d>` duplicates line or selection instead of default half-page scroll.
  Visual duplication copies whole selected lines in character, line, and block
  modes, using the live anchor/cursor so old selection marks cannot affect it.
- `ga` splits text at and after the cursor onto a line above the remaining
  prefix; `gA` puts it below. The cursor follows the moved text.
- Markdown settings live in `after/ftplugin/markdown.lua` so they run after the
  built-in ftplugin and append its undo script. Wrap/spell settings stay local;
  changing filetype restores defaults. `<CR>` follows heading links outside
  Obsidian vaults; Obsidian replaces that fallback on vault-buffer entry.
- Obsidian's personal workspace resolves `~/Obsidian` from the current user's
  home. External links use `vim.ui.open()` for the native platform opener;
  unavailable handlers or launch failures produce a notification.
- Direct `af/if/ac/ic` mappings and text-object navigation belong to
  `nvim-treesitter-textobjects`. mini.ai supplies block/tag/quote/bracket objects
  and next/previous variants (`anf/alf`, `inf/ilf`, and their class equivalents).
  Its function/class specs are retained for those variants.
- Treesitter activation resolves FileType aliases to parser languages, including
  `sh`, JSX, TSX, and `yaml.helm-values`. Markdown/YAML parser languages keep
  stock indentation; missing/unsupported parsers are skipped quietly.
- Both `markdown` and `markdown_inline` are explicit installation targets.
  Inline emphasis, code, and link captures use the latter through Markdown
  injections; startup also requests it when only the block parser is installed.
- `J` is disabled to avoid accidental joins from `<S-j>`.
- `<leader>bd` deletes the current buffer while preserving the current window
  layout. This intentionally avoids raw `:bdelete` behavior, which can collapse
  a split when the deleted buffer is displayed in that window.
- Visual-mode Treesitter selection on `<Tab>` / `<S-Tab>` uses the live visual
  anchor plus cursor position, not `'<` / `'>` marks, because those marks can
  still be unset while a visual mapping is executing.
- Treesitter incremental selection starts from normal mode with `<CR>` or
  `<A-o>`, expands in visual mode with `<CR>`, `<Tab>`, or `<A-o>`, shrinks with
  `<S-Tab>` or `<A-i>`, and moves to the next sibling with `<BS>`.
- `[<Tab>` and `]<Tab>` switch to the previous and next tab respectively. This
  leaves the existing bracket-prefix mappings such as `[b` and `]b` intact.

## File / Root / Explorer Decisions

- Neo-tree and file finding are split by scope:
  `<leader>e` uses current explorer cwd, `<leader>E` uses project root.
- Telescope grep defaults to literal ripgrep matching for the main grep keys:
  `<leader>fg` cwd, `<leader>fG` root, and `<leader>fe` by extension all pass
  `--fixed-strings`. Regex grep is explicit on `<leader>f/` cwd,
  `<leader>f?` root, and `<leader>fE` by extension.
- Ignored-file literal grep is explicit on `<leader>fi` cwd and `<leader>fI`
  root. These pass `--fixed-strings --no-ignore` so ripgrep searches files
  skipped by repo `.gitignore` rules.
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
  Its explicit detection keeps upstream LSP-first ordering and stock markers;
  it does not use `util.root_patterns`. The shared statusline/navigation helper
  remains marker-first and honors explicit cwd narrowing. Root profiling found
  no worthwhile reason to cache it on this machine; measurements and a repeatable
  probe are linked from `docs/core/root-detection-policy.md`.
- `util.frequent_roots` now manages manual directories only (`<leader>hm`).
  Inactive project tracking/picking and unused exports were removed. Legacy
  `pinned` entries still load as manual dirs; project/history and unknown JSON
  fields are preserved without validation or rewriting during manual saves.
- Helm detection is centralized in `util.helm_filetype`: only files in a chart
  containing `Chart.yaml` or `Chart.yml` receive Helm-specific filetypes.
  Templates use `helm`; chart-root metadata/values use `yaml.helm-values`.
  Nested charts use their nearest owning chart, and unrelated templates/values
  stay with ordinary detection.
- Mergetool startup and diff-buffer hooks share one augroup ID so creating the
  latter cannot clear the former's `VimEnter` mapping setup.
- `auto-session` treats non-startup restores as LSP workspace boundaries:
  `lsp_stop_on_restore = true` stops attached LSP clients before restoring a
  different session, including Git branch auto-restores. Restored buffers then
  attach fresh clients for the branch contents instead of carrying old workspace
  state across branches.
- `auto-session` scrubs invalid `setlocal includeformatexpr=...` lines from
  saved session files, plus orphaned `winminheight`/`winminwidth` restore lines
  whose saved script-local variables are absent, before restore and after save.
  This keeps `sessionoptions+=localoptions` enabled while avoiding restore
  failures from stale or plugin-generated session state that Neovim does not
  recognize.
  [lua/util/session_scrub.lua](/home/konkov/.config/nvim/lua/util/session_scrub.lua:1)
  cleans only the exact managed file: `SourcePre` supplies the restore path,
  and `v:this_session` supplies the path after `:mksession`. The source hook is
  installed before auto-session setup so it also covers startup restoration.
  Old sessions are repaired when next restored; there is no eager migration or
  repeated directory scan. Clean files are read but not rewritten. Files outside
  auto-session's configured root are excluded. The installed restore hook passes
  a display name, so the source event avoids guessing escaped/branch filenames.
  [tests/session_scrub.lua](/home/konkov/.config/nvim/tests/session_scrub.lua:1)
  exercises actual auto-session save/restore with disposable files, invalid
  options/orphaned restores, valid paired restores, special names, failed writes,
  and zero reads of unrelated sessions.
  Local synthetic profiling (10 runs, 1,000 lines per file) measured mean cleanup
  costs for 10/100/500 saved sessions at 2.410/22.155/110.160 ms before and
  0.284/0.282/0.234 ms after. These are scrubber costs on warm local storage,
  not complete startup/restore timings. Validation did not rewrite user sessions.
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
  The loader appends `.env` PATH directories after the inherited PATH to keep
  the selected venv and system tools available; only PATH supports `$PATH` /
  `${PATH}` expansion. On the next activation it removes those added directories
  and restores previous values of other loaded variables unless changed since.
  After cleanup it explicitly puts the selected interpreter's bin directory
  first, including when switching to an env previously added by `.env`.
  Neotest guards Go discovery by filename and executable availability before
  invoking upstream `is_test_file`, so Python tests do not require Go.
- Plugin management moved to `<leader>P`; `<leader>Pl` opens Lazy.
- Lazy.nvim rocks support is disabled because no configured plugin requires
  luarocks/hererocks.
- Lazy bootstrap checks both Git clone exit status and process-launch failures.
  Failure aborts initialization before adding the failed path or loading Lazy,
  with the destination, original Git error, and a retry hint. It raises a startup
  error without waiting for a keypress or forcibly exiting Neovim. Existing
  installations still skip cloning. `tests/lazy_bootstrap.lua` checks failure,
  missing Git, successful installation, and the installed-manager path using
  disposable data directories and a fake Git executable.
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
- JavaScript and TypeScript support uses Treesitter for syntax, `ts_ls` for
  LSP, `eslint_d` through `nvim-lint`, and Prettier through Conform for
  `javascript`, `javascriptreact`, `typescript`, and `typescriptreact`.
- Ruby support uses RVM rather than Mason for gem-backed tooling. Ruby LSP,
  syntax diagnostics, and RuboCop formatting run through the project
  `.ruby-version`/`.ruby-gemset` when present, otherwise RVM Ruby `3.2.5`.
  Project `.env` can set `BUNDLE_GEMFILE` for projects whose Gemfile is not at
  the Ruby root. The helper lives in
  [lua/util/ruby.lua](/home/konkov/.config/nvim/lua/util/ruby.lua:1).
- Ruby formatting uses Conform with RuboCop through RVM. Projects with a Gemfile
  run `bundle exec rubocop -x --force-exclusion`; standalone Ruby files use
  `rubocop -x --force-exclusion`. This is layout-only autocorrection on save,
  not full RuboCop `-a`/`-A` cleanup.
- Python LSP defaults to Pyright. BasedPyright is installed/configured but
  opt-in through `:PythonLspUseBasedPyright`; use `:PythonLspUsePyright` to
  switch back without changing config files.
  `util.python_lsp` owns session-wide selection: switching disables the other
  server, and venv restarts reactivate only the selected server. A generation
  guard prevents delayed restarts from undoing a newer selection.
- gopls inherits nvim-lspconfig's callback-based root resolver, including Go
  workspace/module/Git and dependency-source handling, rather than a legacy
  return-value-only `root_pattern()` override.
- Python formatting uses the standalone IntelliJ jar by user request, as do
  Markdown, XML, and YAML (`.yaml` / `.yml`). Ruff remains configured for linting.
- `FormatDir` uses `fd`/`fdfind` with explicit directory excludes instead of a
  manual Lua recursive walker. It includes hidden files, respects ignore files
  such as `.fdignore`, and filters candidates through Conform's configured
  filetypes.
- Directory discovery runs asynchronously, followed by one asynchronous Conform
  request at a time. `:FormatDirCancel` stops after the active request completes;
  overlapping directory runs are rejected. Modified buffers are skipped, and
  Conform rejects stale results if a buffer changes during its request. Successful
  edits are written with format-on-save suppressed; failed writes retain the
  modified buffer. Unchanged files count as skipped. Tests use disposable files
  and real subprocesses; measurements are in
  `docs/audits/format-dir-profile-2026-10-11.md`.
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
- `cmp-buffer` is patched at runtime in
  [lua/plugins/completion.lua](/home/konkov/.config/nvim/lua/plugins/completion.lua:38)
  so its async/on-lines indexer clamps requested line ranges to the live buffer
  line count and uses non-strict line reads. This prevents completion indexing
  from surfacing `Index out of bounds` errors when a buffer changes while the
  source is indexing.
- Local config quality checks are exposed through `make check`, which runs
  Mason-managed `stylua --check` and `selene` against `init.lua`, `lua/`,
  `after/`, and `tests/`, then `make check-config` for isolated regressions.
  The regression runner uses installed plugins/parsers without installing tools
  or launching LSPs. Selene uses the repo-local [vim.yml](/home/konkov/.config/nvim/vim.yml:1)
  standard library so the Neovim `vim` global is accepted.
- [docs/core/compatibility-patches.md](/home/konkov/.config/nvim/docs/core/compatibility-patches.md:1)
  records internal patches, verified plugin revisions, checks, removal criteria,
  and live workflow limits. `make check-compatibility` checks installed contracts
  and patch behavior; it is also included in `make check-config` / `make check`.
  A changed plugin revision requires reviewing/updating the registry, and tracked
  Lua edits inside the covered plugin checkouts must be documented rather than
  silently treated as upstream code. These checks launch no language servers,
  debuggers, or test processes.
- Neotest has a repo-local failed-test rerun helper at
  [lua/util/neotest_failed.lua](/home/konkov/.config/nvim/lua/util/neotest_failed.lua:1).
  `<leader>tF` reruns currently failed test positions from Neotest's cached
  results, limited to the active test scope/project root.
- IntelliJ's debug panel is the default UI for all `nvim-dap` adapters;
  `nvim-dap-ui` is disabled. [lua/util/debug_ui.lua](/home/konkov/.config/nvim/lua/util/debug_ui.lua:1)
  installs its listeners separately from upstream run/debug defaults, preserving
  our global mappings. The panel opens on stops and closes on exit by default.
  `<leader>du` toggles it; `<leader>dU` keeps it open on exit; `<leader>de`
  evaluates the source expression/selection; `<leader>df` opens the panel and
  focuses the current frame. Panel keys: Enter/Tab expand, `e` evaluate, `w`
  watch, `dd` remove watch, `c/n/i/o` continue/step, `q` close.
- The panel displays the stopped thread's stack and first scope, with no thread
  or scope selector. Upstream clears locals/frame values on termination, even
  when keep-open is enabled; watch expressions survive. DAP REPL and virtual
  text (including secret masking) remain configured. Source jumps avoid both
  IntelliJ panels and the REPL.
- Neotest output rendering is guarded by
  [lua/util/neotest_output_guard.lua](/home/konkov/.config/nvim/lua/util/neotest_output_guard.lua:1).
  Upstream `output` and `output_panel` read each result output file fully before
  sending it to a terminal buffer, which can freeze Neovim on very large Java
  test output. The local guard caps rendered output to
  `vim.g.neotest_output_max_bytes` or 2 MiB by default, shows the beginning and
  end, and keeps the full temp-file path visible.
  Its synchronous libuv reads use value-first return ordering and close the
  descriptor after a failed read. The compatibility suite exercises both output
  consumers with real large/small files and an injected read failure.
- `neotest-java` file detection is locally overridden at
  [lua/neotest-java/core/file_checker.lua](/home/konkov/.config/nvim/lua/neotest-java/core/file_checker.lua:1)
  so valid `src/test/java/*Test.java` files are not rejected when the adapter was
  constructed from a stale cwd outside the Java project.
- `neotest-java` root finding is locally overridden at
  [lua/neotest-java/core/root_finder.lua](/home/konkov/.config/nvim/lua/neotest-java/core/root_finder.lua:1)
  so Java test discovery uses Maven/Gradle roots only and never treats a plain
  `.git` ancestor as a runnable Java project. This avoids `unknown project type:
  unknown` in monorepos or after unrelated cwd changes.
- `neotest-java` result mapping is locally overridden at
  [lua/neotest-java/core/result_builder.lua](/home/konkov/.config/nvim/lua/neotest-java/core/result_builder.lua:1)
  so a single executed invocation of a parameterized JUnit method maps back to
  the Neotest method node instead of leaving a stale failed summary status.
- `:FormatterInfo` reports active formatter dependencies and IntelliJ migration
  gaps, including the standalone jar, Java executable, and explicit EditorConfig path.
- Directory formatting commands are registered from
  [lua/util/format_dir.lua](/home/konkov/.config/nvim/lua/util/format_dir.lua:1)
  so [lua/plugins/formatting.lua](/home/konkov/.config/nvim/lua/plugins/formatting.lua:1)
  stays focused on Conform configuration.
- Format-on-save skips buffers with LSP errors and shows a Conform warning once
  per unchanged error state, so repeated saves do not spam notifications.
- Buffer auto-save writes normal file buffers even when LSP errors exist; in
  that case the write proceeds without format-on-save because Conform skips
  formatting on LSP errors.
- Format-on-save uses `10000ms` for standalone IntelliJ formatter routes and
  Ruby/RuboCop, and `500ms` for other auto-formatted filetypes.
- Pyright is configured locally through `vim.lsp.config("pyright", ...)` with
  a resolved Mason absolute binary path, because current `mason-lspconfig`
  auto-enable behavior can otherwise bypass repo-local `cmd` customization.
  `:PyrightInfo` shows the exact command the current session will use.
- `<leader>ll` opens `vim.lsp.log.get_filename()` directly instead of calling
  `:LspLog`, because this Neovim runtime does not provide a built-in `:LspLog`
  command.
- Remaining `:checkhealth` warnings after the audit are optional: Mason reports
  missing ecosystem runtimes for unconfigured PHP/Julia/luarocks workflows, and
  which-key reports optional `mini.icons` is absent while this config uses
  `nvim-web-devicons`.
- Lualine diagnostic and diff symbols intentionally use restrained ASCII labels
  (`E:`, `W:`, `I:`, `H:`, `+`, `~`, `-`) so they remain visible without
  depending on icon fonts or a specific theme.
- Lualine Java status intentionally stays a minimal colored `●` in Java buffers:
  red when the buffer has no attached IntelliJ client or that client is stopped;
  yellow while its initial import is incomplete or its status is busy;
  green when it is attached, ready, and idle. Readiness and busy checks use
  `intellij-lsp.progress.is_ready(client.id)` and
  `intellij-lsp.status.is_idle(client.id)` for that buffer's IntelliJ client.
  Other language clients do not affect the Java indicator.
- `nvim-notify` background is derived from the active float/normal highlights
  via the local `NotifyBackground` refresh hook instead of a TokyoNight-specific
  hex color, so fade animations and popup contrast survive theme switches.
- Bufferline slant separators are tied to `TabLine` / `TabLineSel` /
  `TabLineFill` highlights rather than ad hoc colors so separators stay readable
  across the installed themes.
- `<leader>bp` routes through the local
  [lua/util/bufferline.lua](/home/konkov/.config/nvim/lua/util/bufferline.lua:1)
  wrapper instead of raw `:BufferLineTogglePin`. Bufferline can restore stale
  pinned buffer ids from sessions/ShaDa and then crash with `Invalid buffer id`
  while persisting the next pin; the wrapper removes stale ids, persists the
  already-applied pin state, and cleans deleted buffers from bufferline's manual
  groups.
- Detailed Neo-tree cwd behavior is documented in
  [docs/core/neo-tree-cwd-behavior.md](/home/konkov/.config/nvim/docs/core/neo-tree-cwd-behavior.md:1).
- Oil is part of the core editing workflow. In oil buffers, delete/change
  behavior is intentionally restored so `dd` plus `p` works for moving entries.

## Java Stack: Local Solutions

- IntelliJ LSP owns Java; obsolete `nvim-java` / JDTLS runtime helpers and
  plugin spec have been removed. `spring-boot.nvim` is not configured.
  Neotest uses `util.neotest_intellij` with
  neotest-java's discovery/XML result readers; no JDTLS execution path or backend selector.
- Plugin revision: `9cfad18005470e4187090013e08f92ec9e437219`; server bundle:
  `263.6379.0`. The user explicitly accepted its EAP EULA on 2026-10-10.
- `gt` opens IntelliJ type hierarchy (subtypes) in attached Java buffers. It is
  buffer-local; other filetypes keep Vim's next-tab behavior.
- Startup and protocol/health validation passed on a disposable Maven project.
  Step 3 editing/navigation checks pass on disposable Maven/Gradle/multi-module
  fixtures; Spring/Lombok dependency resolution also passes. See the Step 3
  evidence for limits on UI coverage and large-project validation.
- `lua/util/java_intellij.lua` wraps the pinned plugin's client factory to merge
  cmp/file-operation capabilities and disable built-in completion after attach.
  Upstream `autotrigger=false` alone still enables built-in completion.
- Java inlay hints override upstream `hints.collapse complex types` to `false`
  through `inlay_hint_settings.jetbrains.java` in `lua/plugins/intellij-lsp.lua`,
  so generic type arguments remain visible (for example, `Map<String, String>`
  instead of `Map<...>`). Hint enablement stays with the repo's `<leader>uh` control.
- Plugin theme, Git, leader keymaps, completion triggers/Enter, signature popup,
  folds, upstream run/debug defaults, and independent format-on-save are disabled
  to preserve repo ownership while each workflow is migrated.
- IntelliJ file templates are enabled for new empty Java files: Class, Interface,
  Record, Enum, Annotation, and Exception. The picker derives the package and name
  from the project path; `:IntellijLspFileTemplate` opens it manually for an empty
  attached buffer. Selecting a template creates the file on disk before interpolation.
- Neo-tree `a` -> `SomeClass.java` -> `o` offers that picker after the new empty
  Java buffer has an IntelliJ client. `lua/util/java_file_templates.lua` tracks
  Neo-tree's `file_added` paths and handles buffer entry/late LSP attachment,
  because on-disk creation bypasses upstream's `BufNewFile` template trigger.
  Populated files are ignored; cancellation/reopening does not repeat the picker.
- `:JavaInfo` reports the IntelliJ client/root, JDK, bundle and EULA state.
- `<leader>jr/jd/jc/jl` run/debug/stop/toggle output through
  [lua/util/java_launch.lua](/home/konkov/.config/nvim/lua/util/java_launch.lua:1).
  Launch resolution and adapter startup use the source workspace's client ID;
  no upstream first-global-client selection. Source is saved before building;
  Maven/Gradle builds stream into IntelliJ output and failures block launch.
  Remote attach remains unavailable: the user skipped Step 6.
- Java tests use IntelliJ's test compile command, JDK, and classpath with JUnit
  Console execution and XML results. Existing nearest/file/package/debug,
  failed-rerun, and sequential mappings remain. Parameterized invocations aggregate
  into their method node. JPMS, overloaded test methods, and nonstandard source
  layouts remain limitations of this bridge. Run `:NeotestJava setup` if the console
  jar is missing; it does not install or start JDTLS.
- `<leader>ci/cI` use freshly pulled IntelliJ diagnostic `Import class` fixes;
  ambiguity uses the plugin picker. Bulk imports wait for edits between fixes and
  pause after a cancelled/unanswered picker. Field counters and JDTLS lens glue
  are retired; the redundant `<leader>uJ` retirement notice was removed.
  References remain on `gR` (Glance).
  The pinned IntelliJ plugin exposes Run/Debug code lenses, not a field-usage
  counter setting. Inspection of server bundle `263.6379.0` found JVM main-entry
  lens providers and no dedicated field-count lens provider; IDE Code Vision
  classes bundled with the server do not establish an exposed LSP feature.
- `JavaRestart` restarts only the owning workspace; `JavaCleanCorruptWorkspaces`
  and `<leader>XC/XJ` clear only its reported index inside its claimed cache slot.
  Restart allows a short graceful stop then forces it if necessary, waits for
  actual exit, and checks ownership before deletion. Other workspaces remain active.
- `JavaBranchRefresh` explicitly reloads the owning workspace. BufEnter/FocusGained
  detect HEAD changes and reload; BufEnter/SessionLoadPost/LspAttach ensure a loaded
  Java buffer reattaches without a duplicate client. Scratch storage remains
  project-local, preferring test sources; dependency completion and run/debug are
  checked. `spring-boot.nvim` relies on unsupported `sts.java.*` commands and stays off.
- `JavaProjectUpdate` / `<leader>ju` reloads only the workspace owning the current
  buffer, including build-file buffers. Mixed Maven/Gradle roots explicitly use
  Maven on initial import and reload; other roots keep auto-detection.
- IntelliJ follow-up suggestion commands target nvim-cmp, and follow-up rename
  targets the IntelliJ client. LSP completion snippets use LuaSnip; upstream
  SnippetTextEdit live templates use Neovim's native snippet engine.
- Pinned server `263.6379.0` inspection diagnostics have fixed selection limits:
  unused declarations are explicitly disabled, several requested checks are off
  or informational, and a live project-profile override did not affect results.
  Imports/raw types/unchecked calls/self-assignment/constant conditions and
  accidental boolean assignments do report warnings. See the diagnostics audit
  in `docs/java/intellij-lsp-migration-plan.md`; Lua display settings cannot enable
  checks the server does not emit.
- `JavaInfo` includes progress state and whether initial import finished.
- Conform uses the standalone `intellij-code-formatter` jar for Java, Markdown,
  XML, Python, YAML, and shell. Full-file Java formatting optimizes imports and rearranges members;
  range requests omit both cleanup flags and use Conform's filtered formatting
  edits. The jar is more capable than pinned LSP formatting for these routes;
  the comparison table is in `lua/plugins/formatting.lua`.
- [lua/util/format.lua](/home/konkov/.config/nvim/lua/util/format.lua:1) checks
  Java/jar availability and disables LSP fallback on standalone routes.
  Formatting does not wait for the IntelliJ language server or project import.
  The explicit style file is this config's `.editorconfig`, restoring the previous
  standalone formatter policy.
- Python, YAML, and shell routes use the standalone jar by explicit user request,
  even though earlier baseline samples did not change. Other languages retain
  their existing formatters.
- Conform LSP requests run inside `nvim_buf_call` for their target because this
  Conform revision builds formatting parameters from the current buffer's URI
  and indentation even when `bufnr` is supplied. Directory writes temporarily
  disable autoformat to avoid duplicate cleanup.
- Plan and evidence:
  [docs/java/intellij-lsp-migration-plan.md](/home/konkov/.config/nvim/docs/java/intellij-lsp-migration-plan.md:1),
  [docs/java/intellij-lsp-baseline.md](/home/konkov/.config/nvim/docs/java/intellij-lsp-baseline.md:1),
  [docs/java/intellij-lsp-step-2.md](/home/konkov/.config/nvim/docs/java/intellij-lsp-step-2.md:1),
  [docs/java/intellij-lsp-step-3.md](/home/konkov/.config/nvim/docs/java/intellij-lsp-step-3.md:1),
  [docs/java/intellij-lsp-step-4.md](/home/konkov/.config/nvim/docs/java/intellij-lsp-step-4.md:1),
  [docs/java/intellij-lsp-step-5.md](/home/konkov/.config/nvim/docs/java/intellij-lsp-step-5.md:1),
  [docs/java/intellij-lsp-step-7.md](/home/konkov/.config/nvim/docs/java/intellij-lsp-step-7.md:1),
  [docs/java/intellij-lsp-step-8.md](/home/konkov/.config/nvim/docs/java/intellij-lsp-step-8.md:1).

- `:JavaInitProject [dir]` / `<leader>ji` creates a Java 21 Maven or Gradle
  project, opens `Main.java`, and changes cwd to its root. Java scratch files
  remain project-local, preferring test sources; `:ScratchInfo` reports the path.
- Cleanup removed obsolete JDTLS implementations, raw migration evidence, and
  formatter fixtures. Readable migration findings and known limits remain in
  the Java step notes and migration plan.

- Neotest scope, discovery filtering, package/file target resolution, and the
  guarded current-file discovery fallback live in
  [lua/util/neotest_scope.lua](/home/konkov/.config/nvim/lua/util/neotest_scope.lua:1).
- Activating a Neotest scope never changes global/tab/window cwd or the
  remembered explorer scope. Test targets and process working directories are
  independent of the editor workspace; opening summary or running tests from
  another project does not redirect Neo-tree, Telescope, or session cwd.
- Discovery retains the union of explicitly activated test scopes for the
  session, so activating another project/module does not exclude an earlier
  asynchronous discovery pass. Ignored directories and unactivated siblings
  remain excluded. `SessionLoadPost` clears those remembered scopes.
- Go test-file detection uses the most specific activated scope for its
  GOPATH/GOROOT check, falling back to editor cwd for unactivated paths. This
  keeps an activated GOPATH project discoverable after switching projects,
  while retaining the adapter's guard against unrelated SDK/dependency tests.
- `util.neotest_python` wraps the adapter's public `build_spec` method to capture
  the owning project root and assign both RunSpec and DAP cwd. Unmarked files
  use their directory; an explicit run `cwd` override is honored. A builder
  finishing after another scope activates still launches from its source root.
  Go and IntelliJ Java builders already set their process working directories.
- Neotest run wrappers capture the source buffer/path before opening Neotest UI
  windows, then resolve file/package targets from that captured path. This keeps
  `<leader>tt`, `<leader>tf`, `<leader>tp`, and `<leader>tP` aimed at the test
  file that had focus when the key was pressed, even when split/UI window changes
  leave another buffer visible or current.
- `<leader>tr` and `<leader>td` also capture the source cursor before opening
  the Neotest summary. They resolve the nearest test from that original
  buffer/line instead of relying on Neotest's no-argument `run.run()`, because
  the summary split becomes current before the run starts.
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
- `<leader>co` opens Aerial as an explicit left-side code outline. It is
  intentionally not auto-opened and closes after jumping to a symbol, so it acts
  like a temporary outline picker rather than a persistent sidebar.
- Glance and Neo-tree preview scrolling both use plugin-local `<C-u>` /
  `<C-d>` for up/down. This differs from normal-buffer `<C-d>`, which
  duplicates lines here.
- Code actions use `actions-preview.nvim` for richer UI and diff-backed actions.
  If `actions-preview.nvim` or its Telescope-backed setup fails,
  `<leader>ca`/`<A-CR>` fall back to native `vim.lsp.buf.code_action()`.
- Java extract-to-local-variable may move focus into the follow-up rename prompt.
  Use `<C-w>w` to cycle focus back to the hover/floating window, or `<C-w>p` to
  return to the previously focused window.
- LSP rename uses [lua/util/lsp_rename.lua](/home/konkov/.config/nvim/lua/util/lsp_rename.lua:1)
  to wrap each attached client's rename handler once. Successful non-nil results
  refresh loaded inlay-hint buffers after the existing handler applies edits.
  Custom client handlers are preserved; otherwise the wrapper delegates to the
  current global handler. No global replacement or restoration timer is used.
  `<leader>cr` retains native prompts/prepare-rename and selects only IntelliJ
  for Java. IntelliJ follow-up renames also use the installed client wrapper.
  `tests/lsp_rename.lua` checks cancellation, errors, overlapping requests,
  custom handlers, and Java routing through the native API. A real IntelliJ
  smoke test in a disposable Maven project updated a method declaration and
  call site, refreshed hints, and preserved the global handler. Interactive
  typing and complex refactoring conflicts were not exercised by that probe.
- Inline diagnostics are provided by `tiny-inline-diagnostic.nvim`, enabled on
  LSP attach, and toggled with `<leader>ud`.
- LSP inlay hints are managed by
  [lua/util/inlay_hints.lua](/home/konkov/.config/nvim/lua/util/inlay_hints.lua:1)
  through Neovim's native `vim.lsp.inlay_hint` API and toggled with
  `<leader>uh`. Switching between normal and insert mode does not toggle hints;
  Java, Go, and Python still clear stale hint text after edits.
- Noice is allowed to own command/message UI, but hover/signature rendering is
  intentionally disabled there to avoid conflicts with the chosen editing setup.
  Inlay-hint error suppression was removed so both invalid-column errors and
  other inlay-hint notifications remain visible through normal Noice routes.
  This is an observation decision, not a claim that the original error is fixed.
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
- IntelliJ's DAP panel opens on stops and closes on exit by default.
  `<leader>dU` keeps the panel open, but upstream clears terminated-frame values.

## Git / Merge Decisions

- Diffview is the primary repo/file history and merge-view tool.
- LazyGit is customized via both user config and repo-local
  [lazygit/config.yml](/home/konkov/.config/nvim/lazygit/config.yml:1).
- LazyGit opens from `<leader>Gg` or the direct alternate shortcut `<A-g>`.
- LazyGit uses an explicit dark selected-line background in the repo-local
  config so green diff text remains readable while staging hunks from the TUI.
- LazyGit's `o` open-file action is overridden through `os.open` in the
  repo-local config. It runs
  [scripts/lazygit-open-in-nvim.sh](/home/konkov/.config/nvim/scripts/lazygit-open-in-nvim.sh:1),
  which closes the LazyGit float through
  [lua/util/lazygit_open.lua](/home/konkov/.config/nvim/lua/util/lazygit_open.lua:1)
  and opens the selected file with `:edit` through the current Neovim `$NVIM`
  server in the same tab/window context instead of a new tab.
  This avoids Linux `xdg-open` / GNOME text editor for changed files while
  preserving `e` as LazyGit's editor action.
  [lua/util/lazygit_config.lua](/home/konkov/.config/nvim/lua/util/lazygit_config.lua:1)
  exports `NVIM_LAZYGIT_OPEN_HELPER` from `stdpath("config")` before launching
  LazyGit, so the shell helper follows custom config paths on Linux/macOS.
  The YAML command quotes that helper path and leaves `{{filename}}` unwrapped:
  LazyGit already shell-quotes filenames. Outside this integration, the helper
  path falls back to `${XDG_CONFIG_HOME:-$HOME/.config}/${NVIM_APPNAME:-nvim}`.
  Global LazyGit config is discovered with `lazygit --print-config-dir` and
  included only when present; repo overrides remain last. That preserves native
  Linux/macOS/XDG/legacy directory selection instead of guessing the OS path.
  `tests/portability.lua` checks simulated Linux/macOS paths and URL handlers,
  missing vault/openers/configs, and real shell-helper RPC with spaces/quotes in
  filenames. It does not launch a browser, modify a vault, or run macOS itself.
- Inside LazyGit's terminal buffer, `<A-a>` first sends LazyGit `q` and then
  opens ToggleTerm after LazyGit exits. This prevents stacking the terminal
  float over the LazyGit float.
- Git mergetool finish/abort keys are installed for both classic diff-mode
  Neovim and LazyGit's nested `nvim "$MERGED" -c "DiffviewOpen"` flow:
  `<leader>GQ` writes all/quits back to LazyGit, and `<leader>GA` aborts.
- `git-conflict.nvim` is installed for inline marker resolution in ordinary
  files, including accidentally committed conflict markers. `:GitConflictMarkers`
  and `<leader>GC` search tracked files for committed marker lines and open the
  results in quickfix.
- `git-conflict.nvim` diagnostic suppression is handled in
  [lua/plugins/git.lua](/home/konkov/.config/nvim/lua/plugins/git.lua:1) with
  `vim.diagnostic.enable(false, { bufnr = ... })`, because plugin release 2.1.0
  still calls the removed `vim.diagnostic.disable()` API on Neovim 0.12.
- Gitsigns hunk commands are intentionally buffer-local and grouped under
  `<leader>Gh*`.
- Gitsigns uses visible but quiet delete/topdelete signs instead of empty delete
  markers, so removed-line context is visible in the sign column.
- Live git hunks view is repo-local glue in
  [lua/util/live_hunks.lua](/home/konkov/.config/nvim/lua/util/live_hunks.lua:1).
  `<leader>ug` / `:LiveHunksToggle` opens a right-side scratch buffer for the
  current file's unstaged hunks. Gitsigns `get_hunks()` is its only data source;
  there is no separate Git process or diff parser. A nil result means Gitsigns
  is not attached, while an empty table means no unstaged hunks. The panel shows
  that distinction and refreshes on `GitSignsUpdate`, including after delayed
  attachment. It keeps one scratch row per source line so `WinScrolled` can
  sync the view topline with the edit window.
  `tests/live_hunks.lua` verifies real Gitsigns attachment, clean/unsaved hunks,
  rapid edits, source selection, scroll synchronization, unavailable/error
  states, and closing the panel with a refresh pending. Direct synchronous Git
  calls from the panel are prohibited in that probe.
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
  [docs/java/java-project-init.md](/home/konkov/.config/nvim/docs/java/java-project-init.md:1)
  [docs/java/java-leetcode-debugging.md](/home/konkov/.config/nvim/docs/java/java-leetcode-debugging.md:1)
  [docs/java/java-test-workflow.md](/home/konkov/.config/nvim/docs/java/java-test-workflow.md:1)
  [docs/java/lua-lsp-and-java-fixes.md](/home/konkov/.config/nvim/docs/java/lua-lsp-and-java-fixes.md:1)
