# Neovim Navigation Cheatsheet

## Window Movement

| Key            | Action                            |
|----------------|-----------------------------------|
| `<C-w>h/j/k/l` | Move to left/down/up/right window |
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
| `:b <name>`         | Switch by partial name  |
| `:ls`               | List buffers            |
| `<C-^>`             | Toggle last two buffers |

## In-File Movement

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
