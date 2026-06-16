# Neo-tree Cwd Behavior

Neo-tree and picker cwd behavior is intentionally split from raw Neovim cwd.

## Current Behavior

- `<leader>e` opens Neo-tree at the remembered explorer cwd.
- `<leader>E` opens Neo-tree at project root.
- `<leader>e` and `<leader>E` reveal the current file when opening Neo-tree by
  default.
- Telescope cwd pickers (`<leader><space>`, `<leader>ff`, `<leader>fg`) use the
  remembered explorer cwd.
- Opening or switching buffers does not auto-reveal them in Neo-tree. Explorer
  scope stays put unless changed explicitly.
- `.` inside Neo-tree sets the selected directory as the explorer scope.
- Closing Neo-tree with `q` or `<Esc>` preserves that explicit scope.
- `<leader>ue` toggles reveal-on-open for the current session without turning on
  full auto-follow.

## Why

Neo-tree can emit `DirChanged` events while closing and restoring cwd state. A
generic cwd tracker can accidentally treat that close-time restoration as a new
user choice, making the next `<leader>e` reopen the old directory.

The local fix pins explicit explorer choices briefly so close-time cwd churn does
not overwrite them.

## Design Rule

If a plugin should reopen from a deliberate explorer/workspace choice, store
that choice separately. Do not infer it only from the latest `getcwd()`.

Relevant files:

- [lua/plugins/editor.lua](/home/konkov/.config/nvim/lua/plugins/editor.lua:1)
- [lua/util/init.lua](/home/konkov/.config/nvim/lua/util/init.lua:1)
