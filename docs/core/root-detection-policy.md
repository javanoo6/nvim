# Root Detection Policy

This config now has a shared root-detection policy in `lua/util/init.lua`.

The goal is simple:

- root-aware plugins should behave consistently
- "project root" should mean the same thing across navigation, UI, and search
- new plugins should reuse the common logic instead of inventing their own

## Shared API

Use these helpers from `require("util")`:

- `get_root(bufnr)`:
  main entry point for buffer-based root detection
- `get_root_basename(bufnr)`:
  display helper for statusline/UI root labels
- `get_marker_root(bufnr)`:
  nearest marker-based root for a buffer
- `get_lsp_root(bufnr)`:
  best matching LSP workspace root for a buffer
- `get_root_from_path(path)`:
  marker-based root for an arbitrary file path
- `root_patterns`:
  the shared marker list

## Current Policy

Root resolution is conservative by design:

1. nearest marker root is the default
2. LSP root may refine that only if it is equal to or inside the marker root
3. broader LSP roots are rejected
4. if no marker root exists, fall back to LSP root
5. an explicit `:cd`, `:lcd`, or `:tcd` inside the detected root narrows the
   active scope when it also contains the buffer's file
6. final fallback is current working directory

This prevents one language server from unexpectedly broadening the scope of
Neo-tree, statusline root, or root-aware pickers.

## Shared Markers

The current shared marker list includes:

- `.git`
- `_darcs`
- `.hg`
- `.bzr`
- `.svn`
- `lua`
- `Makefile`
- `package.json`
- `go.mod`
- `pom.xml`
- `build.gradle`
- `build.gradle.kts`
- `settings.gradle`
- `settings.gradle.kts`
- `pyproject.toml`
- `setup.py`
- `Cargo.toml`

Edit this list in one place only:

- [lua/util/init.lua](/home/konkov/.config/nvim/lua/util/init.lua:109)

## Plugins Already Using Shared Root Logic

- Neo-tree root open:
  [lua/plugins/editor.lua](/home/konkov/.config/nvim/lua/plugins/editor.lua:320)
- picker helper defaults:
  [lua/util/init.lua](/home/konkov/.config/nvim/lua/util/init.lua:405)
- project-root Telescope file/grep mappings:
  [lua/plugins/editor.lua](/home/konkov/.config/nvim/lua/plugins/editor.lua:50)
  Cwd-scoped mappings use `get_explorer_cwd()` instead.
- lualine root display:
  [lua/plugins/ui.lua](/home/konkov/.config/nvim/lua/plugins/ui.lua:164)
  It now renders only the root basename while preserving the same underlying
  root resolution.
- Trouble project filtering:
  [lua/plugins/trouble.lua](/home/konkov/.config/nvim/lua/plugins/trouble.lua:56)

## project.nvim Uses Its Own Detection Policy

[lua/plugins/projects.lua](/home/konkov/.config/nvim/lua/plugins/projects.lua:11)
sets `manual_mode = true`; the shared `patterns` assignment is commented out.
Opening a buffer therefore does not automatically change cwd. `:ProjectRoot`
explicitly invokes project.nvim detection, while selecting a directory through
its Telescope projects picker can explicitly change cwd.

The installed plugin retains its [upstream defaults](https://github.com/ahmedkhalf/project.nvim#configuration):

- detection order: LSP first, then patterns
- patterns: `.git`, `_darcs`, `.hg`, `.bzr`, `.svn`, `Makefile`, `package.json`
- cwd changes: global scope

This differs from `util.get_root()`, which prefers the nearest shared marker and
accepts only equally scoped or narrower LSP roots. The relationship is through
cwd: explicit project selection can change cwd, which the shared helper then
considers. project.nvim does not directly call the shared helper. Retaining its
current manual behavior does not require merging the two detection policies.

## Statusline Root Cost

The statusline resolves `get_root_basename()` without a cache.
This keeps filename, cwd, workspace, and marker changes visible on the next
resolution without cache invalidation rules.

Run `make check-config` for root-policy fixtures.

## When To Reuse Shared Root Logic

Use the shared helpers when a plugin or command is supposed to be:

- project-aware
- repo-aware
- scoped to the current module/workspace root
- consistent with Neo-tree and statusline behavior

Examples:

- file pickers
- grep pickers
- explorer roots
- project filters
- repo-scoped diagnostics/references views

## When Not To Reuse Shared Root Logic Blindly

Some plugins have a different concept of scope and should stay specialized.

### Neotest

Neotest in this config intentionally uses filetype-specific test scopes such as:

- Go module
- Java Maven/Gradle module
- Python test project marker

That logic is narrower than generic project root and is intentional.

Activating a test scope changes discovery/targets only. It preserves editor
cwd (including `:lcd` / `:tcd`) and the remembered Neo-tree/Telescope scope.
Python run/debug specs use the owning project root; Go/Java keep their adapter
process directories. Activated discovery scopes accumulate until session
restore, allowing pending work in another project to finish independently.

Relevant file:

- [lua/plugins/neotest.lua](/home/konkov/.config/nvim/lua/plugins/neotest.lua:43)

### Obsidian

Obsidian uses a fixed configured workspace path, not editor project root.

Relevant file:

- [lua/plugins/obsidian.lua](/home/konkov/.config/nvim/lua/plugins/obsidian.lua:9)

### LeetCode

LeetCode uses its own storage/home directory and is not project-root driven.

Relevant file:

- [lua/plugins/leetcode.lua](/home/konkov/.config/nvim/lua/plugins/leetcode.lua:34)

### Linting

`nvim-lint` uses linter-specific working directories. Selene explicitly runs
from this config root, Ruby uses its project/RVM helper, and other linters retain
their configured or upstream cwd behavior. Delayed lint jobs target the original
event buffer through `nvim_buf_call()`:

- [lua/plugins/linting.lua](/home/konkov/.config/nvim/lua/plugins/linting.lua:31)

That is not automatically wrong. It is a tool-execution choice, not necessarily
a project-root bug. Revisit it only if linter behavior is inconsistent in real
repos.

## Rule For New Plugins

Before adding any root-aware plugin, decide which of these it is:

1. project-root aware
2. current-working-directory aware
3. domain-specific scope aware

If it is project-root aware, default to the shared `util` helpers.

Do not add a fresh marker list unless the plugin has a genuinely separate scope
model and that difference is intentional.
