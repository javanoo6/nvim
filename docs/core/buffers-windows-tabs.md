# Buffers, Windows, and Tabs

Neovim separates file content, screen layout, and workspace layout into three
different concepts:

```text
Buffer = loaded text/content
Window = viewport that shows one buffer
Tab    = layout that contains one or more windows
```

The important nesting model is:

```text
Neovim session
|-- Buffers: global list of loaded files/content
|-- Tab page 1
|   |-- Window A -> Buffer 3
|   `-- Window B -> Buffer 7
`-- Tab page 2
    |-- Window C -> Buffer 3
    `-- Window D -> Buffer 12
```

Buffers are global to the whole Neovim session. They do not belong to a specific
tab. Tabs contain windows, and each window displays one buffer.

## Buffer

A buffer is Neovim's in-memory copy of text.

Most buffers correspond to files, but not all of them do:

```text
main.go        -> file buffer
README.md      -> file buffer
terminal       -> terminal buffer
Telescope      -> plugin/special buffer
new empty file -> unnamed buffer
```

Opening a file loads it into a buffer:

```vim
:edit app.py
```

The buffer can stay loaded even when no window is currently showing it.

Common buffer states:

| State      | Meaning                                             |
|------------|-----------------------------------------------------|
| visible    | currently displayed in at least one window          |
| hidden     | loaded but not currently displayed                  |
| modified   | has unsaved changes                                 |
| listed     | appears in normal buffer navigation                 |
| unlisted   | internal, plugin, scratch, or special-purpose buffer |

Useful commands:

| Command    | Action                            |
|------------|-----------------------------------|
| `:ls`      | list buffers                      |
| `:bnext`   | switch to next buffer             |
| `:bprev`   | switch to previous buffer         |
| `:b 5`     | switch to buffer number 5         |
| `:b name`  | switch to buffer matching `name`  |
| `:edit #`  | switch to alternate buffer        |
| `:bdelete` | delete/unload the current buffer  |

Local keymaps:

| Key               | Action                    |
|-------------------|---------------------------|
| `[b` / `]b`       | previous / next buffer    |
| `<S-h>` / `<S-l>` | previous / next buffer    |
| `<leader>bb`      | alternate buffer          |
| `<leader>bd`      | delete buffer, keep split |

`<leader>bd` is intentionally safer than raw `:bdelete` for the local workflow:
it removes the current buffer while preserving the current window layout.

## Window

A window is a viewport. It shows one buffer.

Splitting the screen creates more windows:

```vim
:split
:vsplit
```

Example:

```text
+----------------------+----------------------+
| Window 1             | Window 2             |
| showing main.go      | showing test.go      |
+----------------------+----------------------+
```

Different windows can show different buffers:

```text
Window 1 -> main.go
Window 2 -> README.md
```

Multiple windows can also show the same buffer:

```text
Window 1 -> main.go, top of file
Window 2 -> main.go, bottom of file
```

Each window has its own cursor position, scroll position, folds, and local
window options.

Useful commands:

| Command  | Action                     |
|----------|----------------------------|
| `<C-w>s` | split horizontally         |
| `<C-w>v` | split vertically           |
| `<C-w>h` | move to left window        |
| `<C-w>j` | move to lower window       |
| `<C-w>k` | move to upper window       |
| `<C-w>l` | move to right window       |
| `<C-w>c` | close current window       |
| `<C-w>o` | close all other windows    |
| `<C-w>=` | equalize window sizes      |

Local keymaps:

| Key          | Action             |
|--------------|--------------------|
| `<C-h>`      | left window        |
| `<C-j>`      | lower window       |
| `<C-k>`      | upper window       |
| `<C-l>`      | right window       |
| `<leader>wq` | close window       |
| `<C-Up>`     | increase height    |
| `<C-Down>`   | decrease height    |
| `<C-Left>`   | decrease width     |
| `<C-Right>`  | increase width     |

Closing a window does not necessarily delete its buffer. The buffer usually
remains loaded and can be opened again in another window.

## Tab

A tab in Neovim is a tab page: a layout containing one or more windows.

It is not equivalent to a browser tab containing one file. Use tabs for separate
layouts or work contexts.

Example:

```text
Tab 1: coding layout
+----------------------+----------------------+
| main.go              | test.go              |
+----------------------+----------------------+

Tab 2: git/debug layout
+----------------------+----------------------+
| terminal             | logs                 |
+----------------------+----------------------+
```

All tabs share the same global buffer list, so the same buffer can be visible in
multiple tabs:

```text
Tab 1, Window A -> main.go
Tab 2, Window C -> main.go
```

Useful commands:

| Command        | Action            |
|----------------|-------------------|
| `:tabnew`      | create new tab    |
| `:tabclose`    | close current tab |
| `:tabnext`     | next tab          |
| `:tabprevious` | previous tab      |
| `:tabfirst`    | first tab         |
| `:tablast`     | last tab          |

Local keymaps:

| Key                  | Action       |
|----------------------|--------------|
| `[<tab>`             | previous tab |
| `]<tab>`             | next tab     |
| `<leader><tab>[`     | previous tab |
| `<leader><tab>]`     | next tab     |
| `<leader><tab>f`     | first tab    |
| `<leader><tab>l`     | last tab     |
| `<leader><tab><tab>` | new tab      |
| `<leader><tab>d`     | close tab    |

Closing a tab closes that tab's window layout. The buffers shown inside it
usually remain loaded.

## Command Effects

These commands operate at different layers:

| Command     | Layer  | Effect                                      |
|-------------|--------|---------------------------------------------|
| `:bdelete`  | buffer | removes/unloads content from the buffer list |
| `:close`    | window | closes one viewport                         |
| `:tabclose` | tab    | closes one tab page and its window layout   |

Example with `main.go` visible in two splits:

```text
:bdelete main.go
  main.go is removed from both windows.

:close
  only the current split/window closes.

:tabclose
  the whole current tab layout closes.
```

## Practical Workflow

Use buffers for files you are working with.

Use windows when you need to see multiple things at once:

```text
source + test
code + terminal
implementation + interface
file + diagnostics
```

Use tabs for separate layouts or contexts:

```text
feature work
git/diff/merge
debugging
temporary investigation
```

The practical rule:

```text
Files live in buffers.
Splits are windows.
Tabs are collections of splits.
```
