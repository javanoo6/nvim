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
5. final fallback is current working directory

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

- [lua/util/init.lua](/home/konkov/.config/nvim/lua/util/init.lua:48)

## Plugins Already Using Shared Root Logic

- Neo-tree root open:
  [lua/plugins/editor.lua](/home/konkov/.config/nvim/lua/plugins/editor.lua:206)
- picker helper defaults:
  [lua/util/init.lua](/home/konkov/.config/nvim/lua/util/init.lua:179)
- primary Telescope file/grep mappings:
  [lua/plugins/editor.lua](/home/konkov/.config/nvim/lua/plugins/editor.lua:34)
- lualine root display:
  [lua/plugins/ui.lua](/home/konkov/.config/nvim/lua/plugins/ui.lua:112)
- `project.nvim` marker list:
  [lua/plugins/projects.lua](/home/konkov/.config/nvim/lua/plugins/projects.lua:15)
- Trouble project filtering:
  [lua/plugins/trouble.lua](/home/konkov/.config/nvim/lua/plugins/trouble.lua:31)

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

`nvim-lint` currently runs with `cwd` set to the current file's directory:

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
