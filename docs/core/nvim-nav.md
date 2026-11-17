# Neovim Navigation Cheatsheet

## Buffer / Window / Tab Model

Detailed reference:
[buffers-windows-tabs.md](/home/konkov/.config/nvim/docs/core/buffers-windows-tabs.md:1)

```text
Buffer = loaded text/content
Window = viewport that shows one buffer
Tab    = layout that contains one or more windows
```

Buffers are global to the Neovim session. Tabs contain windows, and each window
shows one buffer. A tab is a window layout, not a browser-style single-file tab.

`<leader>` means Space. Unless a mode or plugin context is specified, use these
keys in Normal mode. `<S-f>` is uppercase `F`; `<S-t>` is uppercase `T`.

## Text Movement

| Key                      | Action                                               |
|--------------------------|------------------------------------------------------|
| `h` / `j` / `k` / `l`    | Left / down / up / right                             |
| `w` / `b`                | Next / previous word start (Spider: camelCase aware) |
| `e` / `ge`               | Next / previous word end (Spider: camelCase aware)   |
| `W` / `B` / `E` / `gE`   | Whitespace-separated WORD movement                   |
| `0`                      | Start of line                                        |
| `$`                      | First non-blank character (**remapped**)             |
| `^`                      | End of line (**remapped**)                           |
| `gg` / `G`               | First / last line of file                            |
| `{count}G` / `:{number}` | Go to a line number                                  |
| `{` / `}`                | Previous / next paragraph                            |
| `%`                      | Matching bracket                                     |
| `H` / `M` / `L`          | Top / middle / bottom of window                      |

Plain `j` / `k` move through wrapped display lines in Normal/Visual mode.
Counts such as `5j` / `5k` use real lines. Counts also work with many other
motions: `3w` moves three word starts; `d3w` deletes across that motion.

## Find a Character: f / F / t / T

Press a motion, then the character to find. These also work in Visual mode and
after operators such as `d`, `c`, or `y`.

| Keys                      | Action                                      |
|---------------------------|---------------------------------------------|
| `f{char}`                 | Find forward; land **on** the character     |
| `F{char}` / `<S-f>{char}` | Find backward; land **on** the character    |
| `t{char}`                 | Find forward; stop **before** the character |
| `T{char}` / `<S-t>{char}` | Find backward; stop **after** the character |
| `;`                       | Repeat in the original motion's direction   |
| `,`                       | Repeat in the opposite direction            |
| `2f,`                     | Find the second comma ahead                 |

Examples: `f)` lands on the next `)`; `t)` stops before it. `dt)` deletes up
to the next `)`, keeping it; `df)` deletes through it, including it.

Flash.nvim enhances these keys: matches are highlighted and motions can cross
lines in the current window, without wrapping at the end of the search range.
Stock Vim restricts them to the current line. Character jump labels are disabled;
you do not need to choose a label. While the character highlights remain active,
`f` / `F` (or `t` / `T` for a till motion) repeat forward/back relative to the
original motion's direction, like `;` / `,` respectively. After another command
ends that active search, a fresh motion takes a new target character.

## Search and Flash Jumps

| Key                                     | Action                                                                        |
|-----------------------------------------|-------------------------------------------------------------------------------|
| `/{pattern}` / `?{pattern}`             | Search forward / backward; Enter confirms                                     |
| `n` / `N`                               | Repeat search in the same / opposite direction; center and open folds         |
| `*` / `#`                               | Search whole word under cursor forward / backward                             |
| `<Esc>`                                 | Clear search highlighting                                                     |
| `s`                                     | Flash: type search text, then a target label (Normal/Visual/operator-pending) |
| `S`                                     | Flash Treesitter: choose a labeled syntax node (same modes as `s`)            |
| `r` after an operator                   | Remote Flash: choose where to apply the operator                              |
| `R` after an operator or in Visual mode | Flash Treesitter search                                                       |
| `<C-s>` in the command line             | Toggle persistent Flash search integration                                    |

Flash search integration is off by default; this preference is separate from
Flash character motions and `s` / `S` jumps.

## Window Movement

Direction model in this config follows Vim defaults: `j = down`, `k = up`.

| Key            | Action                            |
|----------------|-----------------------------------|
| `<C-w>h/j/k/l` | Move to left/down/up/right window |
| `<C-h>`        | Move to left window               |
| `<C-j>`        | Move to lower window              |
| `<C-k>`        | Move to upper window              |
| `<C-l>`        | Move to right window              |
| `[w` / `]w`    | Previous/next window by cycle     |
| `<C-w>s`       | Split horizontal                  |
| `<C-w>v`       | Split vertical                    |
| `<C-w>c`       | Close window                      |
| `<leader>wq`   | Close window                      |
| `<C-w>o`       | Close all other windows           |
| `<C-w>=`       | Equalize window sizes             |
| `<C-w>_`       | Maximize height                   |
| `<C-w>\|`      | Maximize width                    |

`<leader>-` / `<leader>|` split below/right. `<leader>wj` / `<leader>wl`
show the current buffer in a new bottom/right split. `<leader>ws` equalizes all
splits, including fixed-size sidebars; `<C-w>=` respects fixed-size settings.
Ctrl+arrows or Alt+arrows resize splits. In Terminal mode, `<C-h/j/k/l>` exits
Terminal mode and moves to the corresponding window.

## Buffer Navigation

| Key                 | Action                  |
|---------------------|-------------------------|
| `:bnext` / `:bprev` | Next/prev buffer        |
| `<S-h>` / `<S-l>`   | Prev/next buffer        |
| `:b <name>`         | Switch by partial name  |
| `:ls`               | List buffers            |
| `<C-^>`             | Toggle last two buffers |

`[b` / `]b` also cycle buffers. `<leader>bb` switches to the alternate buffer;
`<leader>fb` opens the buffer picker. `<leader>bd` deletes the current buffer
while preserving the window layout (refuses unsaved changes).

## Tab Navigation

| Keys                                | Action              |
|-------------------------------------|---------------------|
| `[<Tab>` / `]<Tab>`                 | Previous / next tab |
| `<leader><Tab>[` / `<leader><Tab>]` | Previous / next tab |
| `<leader><Tab>f` / `<leader><Tab>l` | First / last tab    |
| `<leader><Tab><Tab>`                | New tab             |
| `<leader><Tab>d`                    | Close tab           |

Native `gt` / `gT` normally select next/previous tabs. In Java buffers with the
IntelliJ LSP attached, `gt` opens the subtype hierarchy; use the explicit tab
mappings above there.

## Navigation Matrix

| Keys              | Action                   |
|-------------------|--------------------------|
| `h`               | Left                     |
| `j`               | Down                     |
| `k`               | Up                       |
| `l`               | Right                    |
| `<C-h>`           | Left window              |
| `<C-j>`           | Lower window             |
| `<C-k>`           | Upper window             |
| `<C-l>`           | Right window             |
| `[w`              | Previous window          |
| `]w`              | Next window              |
| `<A-j>`           | Move line/selection down |
| `<A-k>`           | Move line/selection up   |
| `<S-h>`           | Previous buffer          |
| `<S-l>`           | Next buffer              |
| `Telescope <C-j>` | Next item / move down    |
| `Telescope <C-k>` | Previous item / move up  |
| `Glance j`        | Next item / move down    |
| `Glance k`        | Previous item / move up  |

## Preview Scrolling

| Context                    | Key               | Action                    |
|----------------------------|-------------------|---------------------------|
| Glance `gd`/`gR`/`gy`/`gI` | `<C-u>` / `<C-d>` | Scroll preview up/down    |
| Glance                     | `<leader>l`       | Switch list/preview focus |
| Neo-tree file preview      | `P`               | Toggle floating preview   |
| Neo-tree file preview      | `<C-u>` / `<C-d>` | Scroll preview up/down    |
| Neo-tree file preview      | `l`               | Focus preview window      |

## Scrolling and File Targets

| Key               | Action                                                         |
|-------------------|----------------------------------------------------------------|
| `<C-u>`           | Half-page up, centered                                         |
| `<C-d>`           | Duplicate line (normal) / selected lines (visual)              |
| `<C-f>` / `<C-b>` | Full page down/up                                              |
| `gg` / `G`        | File start/end                                                 |
| `{` / `}`         | Paragraph up/down                                              |
| `%`               | Matching bracket                                               |
| `*` / `#`         | Search word under cursor forward/backward                      |
| `gd`              | Glance definitions in LSP buffers; local declaration otherwise |
| `gf`              | Go to file under cursor                                        |

`zz` / `zt` / `zb` place the cursor line at the middle/top/bottom of the window.

## Code Navigation

LSP mappings require an attached server; results depend on its capabilities.

| Keys                        | Action                                         |
|-----------------------------|------------------------------------------------|
| `gd` / `gR`                 | Glance definitions / references                |
| `gy` / `gI`                 | Glance type definitions / implementations      |
| `gD`                        | Go directly to declaration                     |
| `<leader>cd`                | Go to definition in a vertical split           |
| `<leader>co`                | Toggle Aerial code outline                     |
| `<leader>ss` / `<leader>sS` | Pick document / workspace symbols              |
| `<leader>cs`                | Toggle Trouble symbols                         |
| `<leader>cl` / `<leader>cu` | Trouble call hierarchy / usages and references |
| `[f` / `]f`                 | Previous / next function start (Treesitter)    |
| `[c` / `]c`                 | Previous / next class start (Treesitter)       |
| `[a` / `]a`                 | Previous / next parameter start (Treesitter)   |

Treesitter motions also work in Visual/operator-pending mode. In Glance,
`<Tab>` / `<S-Tab>` cycle locations; Enter jumps, `v` / `s` / `t` opens in a
vertical split / horizontal split / tab, and `q` closes. A single result in the
current buffer jumps directly; a result in another file still opens Glance.

## Find Files and Navigate Projects

| Keys                              | Action                                             |
|-----------------------------------|----------------------------------------------------|
| `<leader>ff` / `<leader><Space>`  | Find files in explorer cwd                         |
| `<leader>fF`                      | Find files in project root                         |
| `<leader>fg` / `<leader>fG`       | Literal grep in explorer cwd / project root        |
| `<leader>fi` / `<leader>fI`       | Literal grep including ignored files, cwd / root   |
| `<leader>f/` / `<leader>f?`       | Regex grep in explorer cwd / project root          |
| `<leader>fe` / `<leader>fE`       | Literal / regex grep filtered by extension         |
| `<leader>fR` / `<leader>fr`       | Recent files / resume last picker                  |
| `<leader>Hs`                      | Search history picker                              |
| `<leader>fp` / `<leader>hm`       | Project history picker / manage manual directories |
| `<leader>e` / `<leader>E`         | Neo-tree in explorer cwd / project root            |
| `-` / `<leader>o`                 | Oil at current file's parent / cwd                 |
| `<leader>ha` / `<leader>hh`       | Add file to Harpoon / open Harpoon menu            |
| `<leader>h1` through `<leader>h4` | Jump to Harpoon file 1 through 4                   |

In Telescope, `<C-j>` / `<C-k>` move down/up. Neo-tree's `.` makes the selected
directory the navigation scope; reopening reveals the current file by default,
while switching buffers does not automatically move the tree root.

In Neo-tree, Enter expands directory chains or opens a file; `s` opens with the
window picker. `<C-v>` / `<C-x>` / `<C-t>` open in a vertical split / horizontal
split / tab. In Oil, Enter opens, `-` goes to the parent, `_` goes to cwd, and
the same split/tab keys apply. Oil's `g?` shows its full help.

## Marks

| Key      | Action                            |
|----------|-----------------------------------|
| `ma`     | Set mark 'a'                      |
| `'a`     | Jump to mark 'a' (line)           |
| `` `a `` | Jump to mark 'a' (exact position) |
| `''`     | Jump back to last position        |
| `` `< `` | Jump to start of last selection   |
| `` `> `` | Jump to end of last selection     |

`m]` / `m[` jump to the next/previous mark through marks.nvim (cyclic).
Uppercase marks such as `mA` and `'A` work across files. `g;` / `g,` move through
the change list; `:changes` lists it. Local `['` / `]'` mappings jump to the
start/end of the last changed or yanked region; they do **not** cycle named marks.

## Visual Selection

| Key                 | Action                               |
|---------------------|--------------------------------------|
| `gv`                | Reselect previous visual selection   |
| `<` / `>`           | Indent and keep selection            |
| `<CR>`              | Treesitter: start / expand selection |
| `<A-o>`             | Treesitter: start / expand selection |
| `<Tab>`             | Treesitter: expand to parent node    |
| `<S-Tab>` / `<A-i>` | Treesitter: shrink to previous node  |
| `<BS>`              | Treesitter: move to next sibling     |

Start a manual selection with `v` (characters), `V` (lines), or `<C-v>` (block);
`o` switches its active end. Treesitter selection needs a parser; Markdown
buffers override Normal-mode `<CR>` for following links. `m` in Visual or
operator-pending mode invokes Treehopper's labeled node selection; Normal-mode
`m{letter}` still sets a mark.

## Jumps

| Key      | Action            |
|----------|-------------------|
| `<C-o>`  | Jump back         |
| `<C-i>`  | Jump forward      |
| `:jumps` | List jump history |

## Quickfix

| Key                  | Action          |
|----------------------|-----------------|
| `:cnext` / `:cprev`  | Next/prev item  |
| `:copen` / `:cclose` | Open/close list |

`[l` / `]l` select the previous/next location-list entry. `<leader>XL` /
`<leader>XQ` toggle Trouble's location/quickfix lists; `<leader>Xq` toggles the
editable quickfix window. `[q` / `]q` navigate **Trouble's active view**, which
may contain diagnostics or symbols rather than quickfix entries.

## Diagnostics, Git Hunks, and TODOs

| Keys                                       | Action                                                 |
|--------------------------------------------|--------------------------------------------------------|
| `[d` / `]d`                                | Previous / next diagnostic                             |
| `<leader>xx` / `<leader>xc` / `<leader>xb` | Trouble diagnostics for root / cwd / current buffer    |
| `[h` / `]h`                                | Previous / next Git hunk (Gitsigns, outside diff mode) |
| `[x` / `]x`                                | Previous / next conflict marker                        |
| `[t` / `]t`                                | Previous / next TODO comment                           |
| `<leader>st`                               | Pick TODO comments                                     |

`[c` / `]c` are mapped to Treesitter classes, overriding Vim's native diff-change
motions. In a diff window, `:normal! [c` / `:normal! ]c` bypass mappings to jump
between changes. The configured `[h` / `]h` Gitsigns mappings fall back to native
`[h` / `]h` in diff mode; they do not invoke Gitsigns hunk navigation there.
