# Neovim Navigation Cheatsheet

## Window Movement

Custom direction model in this config: `j = up`, `k = down`.

| Key            | Action                            |
|----------------|-----------------------------------|
| `<C-w>h/j/k/l` | Move to left/down/up/right window |
| `<C-h>`        | Move to left window               |
| `<C-j>`        | Move to upper window              |
| `<C-k>`        | Move to lower window              |
| `<C-l>`        | Move to right window              |
| `<C-w>s`       | Split horizontal                  |
| `<C-w>v`       | Split vertical                    |
| `<C-w>c`       | Close window                      |
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
| `j`               | Up                       |
| `k`               | Down                     |
| `l`               | Right                    |
| `<C-h>`           | Left window              |
| `<C-j>`           | Upper window             |
| `<C-k>`           | Lower window             |
| `<C-l>`           | Right window             |
| `<A-j>`           | Move line/selection up   |
| `<A-k>`           | Move line/selection down |
| `<S-h>`           | Previous buffer          |
| `<S-l>`           | Next buffer              |
| `Telescope <C-j>` | Previous item / move up  |
| `Telescope <C-k>` | Next item / move down    |
| `Glance j`        | Previous item / move up  |
| `Glance k`        | Next item / move down    |

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

| Key       | Action                              |
|-----------|-------------------------------------|
| `gv`      | Reselect previous visual selection  |
| `<` / `>` | Indent and keep selection           |
| `<CR>`    | Treesitter: start selection         |
| `<Tab>`   | Treesitter: expand to parent node   |
| `<S-Tab>` | Treesitter: shrink to previous node |
| `<BS>`    | Treesitter: expand to next scope    |

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
