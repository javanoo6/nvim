# Neovim Navigation Cheatsheet

## Window Movement

Direction model in this config follows Vim defaults: `j = down`, `k = up`.

| Key            | Action                            |
|----------------|-----------------------------------|
| `<C-w>h/j/k/l` | Move to left/down/up/right window |
| `<C-h>`        | Move to left window               |
| `<C-j>`        | Move to lower window              |
| `<C-k>`        | Move to upper window              |
| `<C-l>`        | Move to right window              |
| `<C-w>s`       | Split horizontal                  |
| `<C-w>v`       | Split vertical                    |
| `<C-w>c`       | Close window                      |
| `<leader>wq`   | Close window                      |
| `<C-w>o`       | Close all other windows           |
| `<C-w>=`       | Equalize window sizes             |
| `<C-w>_`       | Maximize height                   |
| `<C-w>\|`      | Maximize width                    |

## Buffer Navigation

| Key                 | Action                  |
|---------------------|-------------------------|
| `:bnext` / `:bprev` | Next/prev buffer        |
| `<S-h>` / `<S-l>`   | Prev/next buffer        |
| `:b <name>`         | Switch by partial name  |
| `:ls`               | List buffers            |
| `<C-^>`             | Toggle last two buffers |

## In-File Movement

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

| Key               | Action                                    |
|-------------------|-------------------------------------------|
| `<C-d>` / `<C-u>` | Half-page down/up                         |
| `<C-f>` / `<C-b>` | Full page down/up                         |
| `gg` / `G`        | File start/end                            |
| `{` / `}`         | Paragraph up/down                         |
| `%`               | Matching bracket                          |
| `*` / `#`         | Search word under cursor forward/backward |
| `gd`              | Go to local definition                    |
| `gf`              | Go to file under cursor                   |

## Marks

| Key      | Action                            |
|----------|-----------------------------------|
| `ma`     | Set mark 'a'                      |
| `'a`     | Jump to mark 'a' (line)           |
| `` `a `` | Jump to mark 'a' (exact position) |
| `''`     | Jump back to last position        |
| `` `< `` | Jump to start of last selection   |
| `` `> `` | Jump to end of last selection     |

## Visual Selection

| Key                   | Action                                 |
|-----------------------|----------------------------------------|
| `gv`                  | Reselect previous visual selection     |
| `<` / `>`             | Indent and keep selection              |
| `<CR>` / `<A-o>`      | LSP: start / expand semantic selection |
| `<Tab><CR>` / `<A-i>` | LSP: shrink semantic selection         |

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
