# Lua LSP and Java Fixes

Short record of local fixes made during debugging on 2026-05-25.

## Java Rename Guard

Problem:

- JDTLS rename/refactor sometimes returned no rename targets.
- `nvim-java` assumed the response was always a table.
- Result: `bad argument #1 to 'ipairs' (table expected, got nil)`.

Local behavior:

- runtime patch guards the `nvim-java` rename path
- empty or invalid rename responses become a warning instead of a Lua stack
  trace

Relevant file:

- [lua/util/java_patches.lua](/home/konkov/.config/nvim/lua/util/java_patches.lua:1)

## LuaLS Workspace Setup

Problem:

- Lua files reported `vim` as an undefined global.
- Neovim API/library awareness was not reliably applied.

Local behavior:

- [.luarc.json](/home/konkov/.config/nvim/.luarc.json:1) is the workspace
  source of truth.
- `lua_ls` also has Neovim-side settings in
  [lua/plugins/lsp.lua](/home/konkov/.config/nvim/lua/plugins/lsp.lua:1).
- `${env:VIMRUNTIME}` keeps the workspace config portable.

Expected result:

- LuaLS understands `vim`.
- LuaLS uses LuaJIT runtime settings.
- Third-party workspace prompts are disabled.
