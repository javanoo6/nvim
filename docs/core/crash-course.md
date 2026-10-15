# 🚀 Neovim Crash Course

nvim setup reference guide.

---

## 📋 Table of Contents

1. [Vim Basics](#vim-basics)
2. [Movement & Navigation](#movement--navigation)
3. [Editing & Text Objects](#editing--text-objects)
4. [Commenting](#commenting)
5. [Search & Replace](#search--replace)
6. [Window Management](#window-management)
7. [Buffer Management](#buffer-management)
8. [File Explorer (Neo-tree)](#file-explorer-neo-tree)
9. [LSP & Code Navigation](#lsp--code-navigation)
10. [Debugging](#debugging)
11. [Testing (Neotest)](#testing-neotest)
12. [Git Integration](#git-integration)
13. [UI & Toggles](#ui--toggles)
14. [Tabs](#tabs)
15. [Telescope (Fuzzy Finder)](#telescope-fuzzy-finder)
16. [Harpoon (Quick File Switching)](#harpoon-quick-file-switching)
17. [Marks](#marks)
18. [Terminal Mode](#terminal-mode)
19. [Go Development](#go-development)
20. [Python Development](#python-development)
21. [Miscellaneous](#miscellaneous)
22. [Sessions](#sessions)
23. [Obsidian (Notes)](#obsidian-notes)
24. [LeetCode](#leetcode)

---

## Vim Basics

### Modes

| Key              | Action                                |
|------------------|---------------------------------------|
| `i`              | Insert mode (before cursor)           |
| `a`              | Insert mode (after cursor)            |
| `I`              | Insert at beginning of line           |
| `A`              | Insert at end of line                 |
| `o`              | Open new line below (enter insert)    |
| `O`              | Open new line above (enter insert)    |
| `ga`             | Move text from cursor to a line above |
| `gA`             | Move text from cursor to a line below |
| `v`              | Visual mode                           |
| `V`              | Visual line mode                      |
| `<C-v>`          | Visual block mode                     |
| `Esc` or `<C-[>` | Return to normal mode                 |
| `:`              | Command mode                          |

**Visual block tip:** After `<C-v>`, you can edit multiple lines column-wise with `I` or `A`.
Type your text, then press `Esc` to apply it to every selected line.
Until you press `Esc`, it may look like only one line changed.

### Saving & Quitting

| Key           | Action                                    |
|---------------|-------------------------------------------|
| `:w`          | Save file                                 |
| `:q`          | Quit                                      |
| `:wq` or `ZZ` | Save and quit                             |
| `:q!`         | Quit without saving                       |
| `<C-s>`       | Save in normal/insert/visual/select modes |
| `<leader>qq`  | Quit all                                  |

---

## Movement & Navigation

### Basic Movement

| Key             | Action                                |
|-----------------|---------------------------------------|
| `h` `j` `k` `l` | Left, Down, Up, Right                 |
| `w`             | Next word start (camelCase aware)     |
| `e`             | Next word end (camelCase aware)       |
| `b`             | Previous word start (camelCase aware) |
| `ge`            | Previous word end (camelCase aware)   |
| `0`             | Start of line                         |
| `$`             | First non-blank character (remapped)  |
| `^`             | End of line (remapped)                |
| `gg`            | First line of file                    |
| `G`             | Last line of file                     |
| `:{n}`          | Go to line n                          |
| `H`             | Top of screen                         |
| `M`             | Middle of screen                      |
| `L`             | Bottom of screen                      |

### Counts

Vim lets you prefix many motions and operators with a number.

Core rule:

- `{count}{command}` repeats the command `count` times
- `{operator}{count}{motion}` applies the operator across that many motions
- `j` means down and `k` means up, matching Vim defaults

Examples:

| Keys   | Action                                        |
|--------|-----------------------------------------------|
| `5j`   | Move down 5 lines                             |
| `5k`   | Move up 5 lines                               |
| `3w`   | Move forward 3 words                          |
| `10dd` | Delete 10 lines                               |
| `3yy`  | Yank 3 lines                                  |
| `5>>`  | Indent 5 lines right                          |
| `d3w`  | Delete 3 words forward                        |
| `c2j`  | Change from cursor through 2 lines downward   |
| `y4k`  | Yank through 4 lines upward                   |
| `V5j`  | Extend selection down 5 lines (6 lines total) |

Count behavior for `j` and `k`:

- plain `j` and `k` use display-line movement for wrapped lines
- counted forms like `5j` and `5k` switch to real-line movement
- so counts stay predictable even when wrapping is on

### Scrolling (Centered)

| Key     | Action                         |
|---------|--------------------------------|
| `<C-u>` | Scroll up half page (centered) |
| `<C-f>` | Scroll down full page          |
| `<C-b>` | Scroll up full page            |
| `zz`    | Center cursor on screen        |

### Fast Navigation (Flash.nvim)

| Key                    | Action                               |
|------------------------|--------------------------------------|
| `s`                    | Flash jump (search text, then label) |
| `S`                    | Flash treesitter (select node)       |
| `r` (operator)         | Remote flash                         |
| `R` (operator/visual)  | Treesitter search                    |
| `<C-s>` (command mode) | Toggle flash search                  |

### Jump Lists

| Key     | Action       |
|---------|--------------|
| `<C-o>` | Jump back    |
| `<C-i>` | Jump forward |

### Buffer Navigation

| Key          | Action                       |
|--------------|------------------------------|
| `[b`         | Previous buffer              |
| `]b`         | Next buffer                  |
| `<S-h>`      | Previous buffer (alt)        |
| `<S-l>`      | Next buffer (alt)            |
| `<leader>bb` | Alternate buffer (last used) |
| `<leader>bd` | Delete buffer                |

### Quickfix & Location List

| Key  | Action                    |
|------|---------------------------|
| `]q` | Next trouble/quickfix     |
| `[q` | Previous trouble/quickfix |
| `[l` | Previous location list    |
| `]l` | Next location list        |

---

## Editing & Text Objects

### Insert Mode

| Key     | Action                          |
|---------|---------------------------------|
| `<C-h>` | Delete previous character       |
| `<C-w>` | Delete previous word            |
| `<C-u>` | Delete to start of line         |
| `<C-a>` | Insert previously inserted text |
| `<C-e>` | Abort completion                |
| `<C-n>` | Next completion                 |
| `<C-p>` | Previous completion             |

**Snippet tip:** in Java, Go, and Python, typing `main` and expanding it through
completion/snippets inserts the language-appropriate entry-point template.

### Operators (wait for motion)

| Key  | Action                          |
|------|---------------------------------|
| `d`  | Delete                          |
| `c`  | Change (delete + insert)        |
| `y`  | Yank (copy)                     |
| `>`  | Indent right                    |
| `<`  | Indent left                     |
| `=`  | Auto-indent                     |
| `g~` | Toggle case                     |
| `gu` | Lowercase                       |
| `gU` | Uppercase                       |
| `!`  | Filter through external program |

### Common Combos

| Key     | Action                             |
|---------|------------------------------------|
| `dd`    | Delete line                        |
| `cc`    | Change line                        |
| `yy`    | Yank line                          |
| `D`     | Delete to end of line              |
| `C`     | Change to end of line              |
| `Y`     | Yank to end of line                |
| `x`     | Delete character                   |
| `r`     | Replace character                  |
| `J`     | Disabled to avoid accidental joins |
| `gJ`    | Join without space                 |
| `.`     | Repeat last change                 |
| `u`     | Undo                               |
| `<C-r>` | Redo                               |

### Standard Delete / Change / Macro Guide

These keys use standard Vim behavior.

#### Delete and Change

| Key | Meaning                              |
|-----|--------------------------------------|
| `d` | Delete using a motion or text object |
| `D` | Delete from cursor to end of line    |
| `c` | Change using a motion or text object |
| `C` | Change from cursor to end of line    |
| `x` | Delete character under cursor        |
| `X` | Delete character before cursor       |

Core rule:

- deleted or changed text goes into the unnamed register
- so `p` can usually paste what you just deleted or changed

Examples:

| Keys   | Result                               |
|--------|--------------------------------------|
| `dw`   | Delete to the start of the next word |
| `diw`  | Delete inner word                    |
| `dd`   | Delete line                          |
| `D`    | Delete to end of line                |
| `cw`   | Change word and enter insert mode    |
| `ci\"` | Change inside quotes                 |
| `C`    | Change to end of line                |
| `x`    | Delete char under cursor             |
| `X`    | Delete char before cursor            |

Mental model:

- `d` removes text and stays in normal mode
- `c` removes text and enters insert mode
- uppercase `D` and `C` are fast line-tail variants

#### Macros

| Key | Meaning                                            |
|-----|----------------------------------------------------|
| `q` | Start recording into a register, or stop recording |
| `Q` | Replay the last recorded macro in Neovim           |

Standard macro workflow:

1. `qa` starts recording into register `a`
2. make edits
3. `q` stops recording
4. `@a` plays macro `a`
5. `@@` repeats the last played macro

Examples:

| Keys  | Result                                |
|-------|---------------------------------------|
| `qa`  | Start recording macro in register `a` |
| `q`   | Stop recording                        |
| `@a`  | Play macro from register `a`          |
| `@@`  | Repeat last macro                     |
| `5@a` | Play macro `a` five times             |

Practical beginner tip:

- use `qq` to record into register `q`
- use `q` to stop
- use `@q` to replay
- use `@@` to repeat

That gives you a simple habit while still staying inside the standard Vim model.

### Text Objects (Treesitter and Mini.ai)

Treesitter owns direct function/class/parameter/loop/conditional mappings and
their navigation. Mini.ai supplies block/tag/quote/bracket objects and
next/previous variants: `anf` / `alf` select the next/previous whole function,
`inf` / `ilf` select its contents; use `c` instead of `f` for classes.

| Object        | Description                        |
|---------------|------------------------------------|
| `af` / `if`   | Around / Inside function           |
| `ac` / `ic`   | Around / Inside class              |
| `aa` / `ia`   | Around / Inside parameter/argument |
| `al` / `il`   | Around / Inside loop               |
| `ai` / `ii`   | Around / Inside conditional        |
| `ao` / `io`   | Around / Inside block              |
| `at` / `it`   | Around / Inside HTML tag           |
| `a"` / `i"`   | Around / Inside double quotes      |
| `a'` / `i'`   | Around / Inside single quotes      |
| ``a` / `i` `` | Around / Inside backticks          |
| `a(` / `i(`   | Around / Inside parentheses        |
| `a[` / `i[`   | Around / Inside brackets           |
| `a{` / `i{`   | Around / Inside braces             |

**Examples:**

- `dif` - Delete inside function
- `yac` - Yank around class
- `cii` - Change inside if-statement
- `vi"` - Select inside double quotes
- `da(` - Delete around parentheses

### Treesitter Text Objects

| Key                   | Action                 |
|-----------------------|------------------------|
| `m` (visual/operator) | Select treesitter node |

### Treesitter Incremental Selection

| Key                 | Action                           |
|---------------------|----------------------------------|
| `<CR>`              | Start selection from normal mode |
| `<A-o>`             | Start / expand selection         |
| `<Tab>`             | Expand to parent node            |
| `<S-Tab>` / `<A-i>` | Shrink to previous node          |
| `<BS>`              | Move to next sibling node        |

### Moving Lines

| Key                                     | Action         |
|-----------------------------------------|----------------|
| `<A-j>`                                 | Move line down |
| `<A-k>`                                 | Move line up   |
| (Works in normal, insert, visual modes) |

### Duplicating Lines (IntelliJ-style)

| Key     | Mode   | Action                                                       |
|---------|--------|--------------------------------------------------------------|
| `<C-d>` | normal | Duplicate current line below, cursor moves to the copy       |
| `<C-d>` | visual | Duplicate all lines in selection below, cursor on first copy |

### Surround (Mini.surround)

| Key   | Action                                                     |
|-------|------------------------------------------------------------|
| `gsa` | Add surround (e.g., `gsaiw"` to surround word with quotes) |
| `gsd` | Delete surround                                            |
| `gsr` | Replace surround                                           |
| `gsf` | Find surround (right)                                      |
| `gsF` | Find surround (left)                                       |
| `gsh` | Highlight surround                                         |
| `gsn` | Update n lines                                             |

**Examples (Normal Mode):**

- `gsaiw"` - Surround inner word with "
- `gsd"` - Delete surrounding "
- `gsr"'` - Replace " with '

**Examples (Visual Mode):**

Select text first, then press `gsa` + bracket/quote:

| After Selection | Press     | Result            |
|-----------------|-----------|-------------------|
| `viw` (word)    | `gsa"`    | `"word"`          |
| `V` (line)      | `gsa(`    | `(selected line)` |
| `viw`           | `gsa[`    | `[word]`          |
| `viw`           | `gsa{`    | `{word}`          |
| `viw`           | ``gsa` `` | `` `word` ``      |

---

## Commenting

| Key   | Action                                 |
|-------|----------------------------------------|
| `gcc` | Toggle comment on current line         |
| `gc`  | Toggle comment (operator, e.g. `gcip`) |
| `gc`  | Toggle comment on visual selection     |

**Examples:**

- `gcc` - Comment/uncomment current line
- `gcip` - Comment/uncomment inner paragraph
- `V5jgc` - Select current line plus 5 below, then comment all
- `gc` (in visual) - Comment/uncomment selection

---

## Search & Replace

### Search

| Key     | Action                              |
|---------|-------------------------------------|
| `/`     | Search forward                      |
| `?`     | Search backward                     |
| `n`     | Next match (centered)               |
| `N`     | Previous match (centered)           |
| `*`     | Search word under cursor (forward)  |
| `#`     | Search word under cursor (backward) |
| `g*`    | Search partial word (forward)       |
| `g#`    | Search partial word (backward)      |
| `<Esc>` | Clear search highlight              |

When typing `/` or `?`, completion suggestions may appear. Keep typing to
ignore them, use `<C-e>` to close only the suggestions while staying in the
search prompt, then press `<CR>` to run the search.

### Replace (in-buffer)

| Key              | Action                           |
|------------------|----------------------------------|
| `:s/old/new/`    | Replace first occurrence in line |
| `:s/old/new/g`   | Replace all in line              |
| `:%s/old/new/g`  | Replace all in file              |
| `:%s/old/new/gc` | Replace all with confirmation    |

### Replace (project-wide — grug-far)

| Key          | Mode   | Action                                                        |
|--------------|--------|---------------------------------------------------------------|
| `<leader>rg` | normal | Open scoped to **current file** (Paths pre-filled)            |
| `<leader>rG` | normal | Literal replace across files in the current working directory |
| `<leader>rR` | normal | Regex replace across files in the current working directory   |
| `<leader>rw` | normal | Open with word under cursor, scoped to current file           |
| `<leader>rg` | visual | Open with selection, scoped to current file                   |

**How to use grug-far:**

1. Open with one of the keys above
2. Fill in **Search** and **Replace** fields (`Tab` to move between them)
3. Results preview updates live as you type
4. Press `\r` (`<localleader>r`) to **apply** all replacements
5. Press `q` to close

**Tip:** Clear **Paths** to search the working directory. The defaults use
`--fixed-strings`; use `<leader>rR` or remove that flag for regex matching. Use
globs such as `*.go` in **Paths** to scope by filetype.

### Replace (within visual selection)

| Key          | Mode   | Action                                       |
|--------------|--------|----------------------------------------------|
| `<leader>rw` | visual | `:s/\%V` — replace only within selected text |

**Tip:** After `<leader>rw` in visual mode, type your pattern and replacement: `old/new/g` then `<CR>`.

## Window Management

Detailed mental model:
[buffers-windows-tabs.md](/home/konkov/.config/nvim/docs/core/buffers-windows-tabs.md:1)

Core distinction:

```text
Buffer = loaded text/content
Window = viewport that shows one buffer
Tab    = layout that contains one or more windows
```

Buffers are global to the whole Neovim session. Tabs contain windows, and each
window displays one buffer. A tab is a split/layout workspace, not a
browser-style single-file tab.

### Navigation

| Key     | Action             |
|---------|--------------------|
| `<C-h>` | Go to left window  |
| `<C-j>` | Go to lower window |
| `<C-k>` | Go to upper window |
| `<C-l>` | Go to right window |
| `[w`    | Previous window    |
| `]w`    | Next window        |

### Move Buffer to Split

| Key          | Action                      |
|--------------|-----------------------------|
| `<leader>wj` | Move buffer to bottom split |
| `<leader>wl` | Move buffer to right split  |

### Splitting

| Key          | Action                          |
|--------------|---------------------------------|
| `<leader>-`  | Split horizontally (below)      |
| `<leader>\|` | Split vertically (right)        |
| `<C-w>s`     | Split horizontal                |
| `<C-w>v`     | Split vertical                  |
| `<leader>wq` | Close window                    |
| `<C-w>c`     | Close window                    |
| `<C-w>o`     | Only this window (close others) |
| `<C-w>q`     | Quit window                     |

### Resizing

| Key                      | Action              |
|--------------------------|---------------------|
| `<C-Up>`                 | Increase height     |
| `<C-Down>`               | Decrease height     |
| `<C-Left>`               | Decrease width      |
| `<C-Right>`              | Increase width      |
| `<M-Up>` / `<M-Down>`    | Resize height (alt) |
| `<M-Left>` / `<M-Right>` | Resize width (alt)  |
| `<C-w>=`                 | Equalize windows    |
| `<C-w>_`                 | Maximize height     |
| `<C-w>\|`                | Maximize width      |

---

## Buffer Management

| Key               | Action                      |
|-------------------|-----------------------------|
| `[b` / `]b`       | Prev / Next buffer          |
| `<S-h>` / `<S-l>` | Prev / Next buffer (alt)    |
| `<leader>bb`      | Alternate buffer            |
| `<leader>bd`      | Delete buffer, keep split   |
| `<leader>bp`      | Toggle pin                  |
| `<leader>bP`      | Delete non-pinned buffers   |
| `<leader>bo`      | Delete other buffers        |
| `<leader>br`      | Delete buffers to the right |
| `<leader>bl`      | Delete buffers to the left  |

---

## File Explorer (Neo-tree)

| Key         | Action                       |
|-------------|------------------------------|
| `<leader>e` | Explorer (current directory) |
| `<leader>E` | Explorer (project root)      |

### Inside Neo-tree

| Key     | Action                                            |
|---------|---------------------------------------------------|
| `<CR>`  | Open file / Expand full single-child folder chain |
| `o`     | Open file                                         |
| `h`     | Collapse folder / Go to parent                    |
| `<bs>`  | Go to parent directory                            |
| `.`     | Set current folder as root                        |
| `s`     | **Open with window picker** (pick split)          |
| `P`     | Toggle floating file preview                      |
| `l`     | Focus preview window                              |
| `<C-d>` | Scroll preview down                               |
| `<C-u>` | Scroll preview up                                 |
| `<C-v>` | Open in vertical split                            |
| `<C-x>` | Open in horizontal split                          |
| `<C-t>` | Open in new tab                                   |
| `a`     | Add file/folder                                   |
| `d`     | Delete                                            |
| `r`     | Rename                                            |
| `c`     | Copy                                              |
| `m`     | Move                                              |
| `H`     | Toggle hidden files                               |

**Tip:** Renaming or moving a Java file via `r` / `m` triggers LSP file operations — IntelliJ handles package/import/reference updates
across the project. This may modify many buffers at once. Save them all with `:wall`.

**Preview tip:** `P` uses Neo-tree's native preview mode, so you can scan files without leaving the tree. Press `<Esc>` to close Neo-tree.

---

## Quick Directory Navigation

| Key          | Action                                    |
|--------------|-------------------------------------------|
| `-`          | Open **Oil** (parent dir of current file) |
| `<leader>o`  | Open **Oil** in cwd                       |
| `<leader>fp` | Switch project (stock `project.nvim`)     |
| `<leader>hm` | Manage manual dirs (add/remove/list)      |

`<leader>fp` uses `project.nvim` history. `<leader>hm` opens your custom persistent manual-dir list.

### Inside Oil (stevearc/oil.nvim)

Oil treats the directory as a buffer — **edit filenames directly and `:w` to apply**.

| Key     | Action                   |
|---------|--------------------------|
| `<CR>`  | Open file / Enter dir    |
| `-`     | Go to parent directory   |
| `_`     | Open cwd root            |
| `<C-v>` | Open in vertical split   |
| `<C-x>` | Open in horizontal split |
| `<C-t>` | Open in new tab          |
| `<C-r>` | Refresh                  |
| `g.`    | Toggle hidden files      |
| `gx`    | Open with system app     |
| `g?`    | Show help                |
| `q`     | Close Oil                |

**File operations (buffer-editing workflow):**

| Task   | How                                                    |
|--------|--------------------------------------------------------|
| Rename | Edit filename text inline → `:w`                       |
| Move   | `dd` the line → navigate to target dir → `p` → `:w`    |
| Copy   | `yy` the line → navigate to target dir → `p` → `:w`    |
| Create | `o` new line with filename (trailing `/` = dir) → `:w` |
| Delete | `dd` the line → `:w`                                   |

> **Tip:** All path edits have full vim completion (`<C-x><C-f>` for paths). Move across
> directories by opening a second Oil split and yanking between them.

---

## Command Line (Cmdline) Completion

When typing commands with `:` and autocomplete menu appears:

This uses `nvim-cmp` cmdline completion:

| Key      | Action                                             |
|----------|----------------------------------------------------|
| `<Down>` | Next completion item                               |
| `<Up>`   | Previous completion item                           |
| `<CR>`   | Confirm selected completion item without executing |
| `<C-e>`  | Close the completion menu without leaving cmdline  |

---

## Telescope (Fuzzy Finder)

| Key               | Action                         |
|-------------------|--------------------------------|
| `<leader><space>` | Find files from cwd            |
| `<leader>ff`      | Find files from cwd            |
| `<leader>fF`      | Find files from project root   |
| `<leader>fg`      | Literal grep from cwd          |
| `<leader>fG`      | Literal grep from root         |
| `<leader>fi`      | Literal grep ignored from cwd  |
| `<leader>fI`      | Literal grep ignored from root |
| `<leader>f/`      | Regex grep from cwd            |
| `<leader>f?`      | Regex grep from root           |
| `<leader>fb`      | Buffers                        |
| `<leader>fR`      | Recent files                   |
| `<leader>fs`      | New scratch file               |
| `<leader>fS`      | Open scratch file              |
| `<leader>fN`      | New named scratch file         |
| `<leader>Hy`      | Yank history                   |
| `<leader>Hc`      | Command history                |
| `<leader>Hs`      | Search history                 |
| `<leader>:`       | Command history                |
| `<leader>ss`      | Document symbols               |
| `<leader>sS`      | Workspace symbols              |
| `<leader>st`      | Search TODOs                   |
| `<leader>fe`      | Literal grep by extension      |
| `<leader>fE`      | Regex grep by extension        |
| `<leader>fr`      | Resume last search             |

### Inside Telescope

| Key               | Action                                                       |
|-------------------|--------------------------------------------------------------|
| `<C-j>` / `<C-k>` | Next / Previous                                              |
| `<C-n>` / `<C-p>` | Next / Previous in history                                   |
| `<C-d>` / `<C-u>` | Scroll preview down / up                                     |
| `<CR>`            | Open                                                         |
| `<C-x>`           | Open in horizontal split                                     |
| `<C-v>`           | Open in vertical split                                       |
| `<C-t>`           | Open in tab                                                  |
| `<Tab>`           | Multi-select entry                                           |
| `<C-q>`           | Send Tab-selected (or all if none selected) to quickfix list |
| `<Esc>`           | Close                                                        |

### Scratch Files

Scratch files are persistent temporary files managed by `scratch.nvim`.

- They live under `stdpath("state") .. "/scratch"`.
- Use them for throwaway code, JSON inspection, shell snippets, or notes you
  may want to reopen later.
- `<leader>fs` creates a scratch file quickly.
- `<leader>fS` opens an existing scratch file. In non-Java flows this uses the
  global scratch list through Telescope.
- `<leader>fN` creates one with an explicit filename.
- In a Maven/Gradle Java project, choosing `java` opens a project-local
  `src/test/java/Scratch.java` (or `src/main/java/Scratch.java` fallback) so
  IntelliJ can resolve project dependencies.

**Tip:** `<leader>fg`, `<leader>fG`, and `<leader>fe` search the text you type as-is, so `foo.` matches a literal dot. Use `<leader>f/`,
`<leader>f?`, or `<leader>fE` when you want ripgrep regex syntax.

**Tip:** `<leader>fi` and `<leader>fI` also search literal text, but include files
ignored by `.gitignore`. Scratch path details are available with `:ScratchInfo`.

**Tip:** `<leader>fr` resumes the last Telescope search exactly where you left off — useful for returning to a search after editing a file.

### Workflow: Edit multiple files from a search

Use this when you need to rename variables or make targeted edits across many files one by one:

1. `<leader>ff` searches for files; `<leader>fg` or `<leader>fe` searches file contents
2. `<Tab>` to select specific files, or skip to send all results
3. `<C-q>` — send to quickfix list
4. `<leader>XQ` — open quickfix as a persistent Trouble sidebar
5. `<CR>` on a file in the sidebar — jump to it and edit
6. `]q` / `[q` — jump to next/prev file without leaving the sidebar
7. Repeat until done, then `<leader>XQ` to close

---

## LSP & Code Navigation

### Go To

| Key  | Action                         |
|------|--------------------------------|
| `gd` | Go to definition (Glance)      |
| `gR` | Go to references (Glance)      |
| `gy` | Go to type definition (Glance) |
| `gI` | Go to implementation (Glance)  |
| `gD` | Go to declaration (native LSP) |

### Glance Popup

After `gd`, `gR`, `gy`, or `gI`, Glance normally opens a results list with a
file preview. A single result in the current buffer jumps directly.

| Key                 | Action                                            |
|---------------------|---------------------------------------------------|
| `j` / `<Down>`      | Next result                                       |
| `k` / `<Up>`        | Previous result                                   |
| `<Tab>` / `<S-Tab>` | Next / previous location                          |
| `<C-u>` / `<C-d>`   | Scroll preview up / down from the list            |
| `<CR>`              | Jump to selected result                           |
| `v` / `s` / `t`     | Open in vsplit / split / new tab                  |
| `o`                 | Preview selected location                         |
| `<leader>l`         | Switch between list and preview                   |
| `q` / `Q` / `<Esc>` | Close from the list; `Q` also closes from preview |

### Documentation

| Key  | Action              |
|------|---------------------|
| `K`  | Hover documentation |
| `gK` | Signature help      |

### Code Actions

| Key                     | Action                                                                |
|-------------------------|-----------------------------------------------------------------------|
| `<leader>ca` / `<A-CR>` | Code action                                                           |
| `<leader>cr`            | Rename                                                                |
| `<leader>cp`            | Fix package declaration                                               |
| `<leader>ci`            | Java: import class under cursor, prompt if ambiguous                  |
| `<leader>cI`            | Java: import unambiguous classes in buffer                            |
| `<leader>cf`            | Format through Conform (Java: standalone jar, imports, rearrangement) |
| `<leader>cF`            | Format current file's directory, or prompt for a directory            |
| `:FormatDirCancel`      | Stop directory formatting after the current file finishes             |

### Symbols & Outline

| Key          | Action                                               |
|--------------|------------------------------------------------------|
| `<leader>co` | Toggle left code outline (Aerial; closes after jump) |
| `<leader>cs` | Symbols (Trouble)                                    |
| `<leader>cl` | Call hierarchy (Trouble)                             |
| `<leader>cu` | Usages / references (Trouble)                        |

### LSP Server Management

| Key          | Action      |
|--------------|-------------|
| `<leader>lr` | Restart LSP |
| `<leader>li` | LSP info    |
| `<leader>ll` | LSP log     |

### Diagnostics

| Key          | Action                                   |
|--------------|------------------------------------------|
| `[d`         | Prev diagnostic                          |
| `]d`         | Next diagnostic                          |
| `<leader>xd` | Line diagnostics (float)                 |
| `<leader>xl` | Diagnostics to loclist                   |
| `<leader>xx` | Diagnostics for project root (Trouble)   |
| `<leader>xc` | Diagnostics for cwd (Trouble)            |
| `<leader>xb` | Diagnostics for current buffer (Trouble) |
| `<leader>XL` | Location list (Trouble)                  |
| `<leader>XQ` | Quickfix list (Trouble)                  |

### Todos

| Key          | Action                   |
|--------------|--------------------------|
| `]t`         | Next TODO comment        |
| `[t`         | Previous TODO comment    |
| `<leader>Xt` | TODOs (Trouble)          |
| `<leader>XT` | TODO/FIX/FIXME (Trouble) |

---

## Debugging

| Key           | Action                      |
|---------------|-----------------------------|
| `<leader>db`  | Toggle breakpoint           |
| `<leader>dB`  | Breakpoint with condition   |
| `<leader>dc`  | Continue active session     |
| `<leader>dC`  | Run to cursor               |
| `<leader>df`  | Focus current frame         |
| `<leader>di`  | Step into                   |
| `<leader>do`  | Step out                    |
| `<leader>dO`  | Step over                   |
| `<leader>dg`  | Go to line (no execute)     |
| `<leader>dl`  | Run last                    |
| `<leader>dp`  | Pause                       |
| `<leader>dr`  | Toggle REPL                 |
| `<leader>dt`  | Terminate                   |
| `<leader>ds`  | Session info                |
| `<leader>dj`  | Down (call stack)           |
| `<leader>dk`  | Up (call stack)             |
| `<leader>dw`  | Hover widgets               |
| `<leader>du`  | Toggle IntelliJ debug panel |
| `<leader>dU`  | Toggle DAP UI keep-open     |
| `<leader>de`  | Evaluate expression         |
| `<leader>dgt` | Debug Go test               |
| `<leader>dgl` | Debug last Go test          |

---

IntelliJ's panel is the default for Java, Go, and Python. It opens on a stop,
shows stack/locals/watches, and closes on exit unless keep-open is enabled.
Inside the panel: Enter/Tab expand, `e` evaluates, `w` adds a watch, `dd` removes
one, `c/n/i/o` continue/step, and `q` closes. Keep-open preserves the panel and
watch expressions; terminated-frame values are cleared by upstream.

## Testing (Neotest)

| Key          | Action                      |
|--------------|-----------------------------|
| `<leader>tt` | Run file                    |
| `<leader>tT` | Run all test files          |
| `<leader>tr` | Run nearest test            |
| `<leader>td` | Debug nearest test          |
| `<leader>tp` | Run package                 |
| `<leader>tP` | Debug package               |
| `<leader>tq` | Run file tests sequentially |
| `<leader>tl` | Run last                    |
| `<leader>tL` | Debug last                  |
| `<leader>tf` | Debug file                  |
| `<leader>tD` | Debug all test files        |
| `<leader>ta` | Attach to running test      |
| `<leader>tF` | Run failed tests            |
| `<leader>ts` | Toggle summary              |
| `<leader>to` | Show output                 |
| `<leader>tO` | Toggle output panel         |
| `<leader>tc` | Clear output panel          |
| `<leader>tS` | Stop (interactive)          |
| `<leader>tw` | Toggle watch                |

Debug-test mappings close the summary and never auto-open it. Use `<leader>ts`
to open it manually. Regular runs honor the persisted `test_summary_on_run`
preference. `<leader>tl` reruns normally even if the last run was a debug run.

### Java-specific

IntelliJ LSP owns Java. Use `:JavaInfo` and `:checkhealth intellij-lsp` to
inspect the backend. App run/debug, Java Neotest, smart imports, workspace
reload/restart, and cache clearing use IntelliJ. Remote attach is unavailable;
`<leader>ja` only reports that limitation. Field-usage counters are unavailable;
`gR` lists references. See [Java workflow](../java/java-workflow.md).

| Key          | Action                    |
|--------------|---------------------------|
| `<leader>jr` | Run Main                  |
| `<leader>jd` | Debug Main                |
| `<leader>ji` | Init Project              |
| `<leader>ju` | Update Project            |
| `<leader>jc` | Stop Main                 |
| `<leader>jl` | Toggle Runner Logs        |
| `<leader>ja` | Remote attach unavailable |

`:JavaInitProject [dir]` prompts for Maven/Gradle, project directory, artifact,
group id, and package, then opens the generated `Main.java`.

`:JavaProjectUpdate` / `<leader>ju` reloads the current IntelliJ workspace after
changing `pom.xml` or Gradle configuration. It also works from a build-file
buffer and reloads only its owning workspace. Mixed Maven/Gradle roots prefer Maven.

### Java Code Actions

Java refactors and generate actions come from IntelliJ code actions.
Use `<leader>ca` or `<A-CR>` to open the code action list in
`actions-preview.nvim`.

Important limitation:

- edit-backed actions usually show a real diff preview before apply
- many Java refactors are command-only IntelliJ actions, so they cannot be
  diff-previewed and may show the fallback “Preview is not available” message
- extract-to-local-variable can move focus into the follow-up rename prompt;
  use `<C-w>w` to cycle focus back to the hover/floating window, or `<C-w>p` to
  return to the previously focused window.

This is expected behavior, not a broken Neovim or LSP setup.

---

Full-file Java formatting uses the standalone jar to optimize imports and
rearrange members; range formatting omits both cleanup flags.

### Java Debugging

**How Java debugging works:** IntelliJ LSP resolves Maven/Gradle compilation and
launch paths, starts its JVM debug adapter, and nvim-dap connects to it.

#### Starting Debug Sessions

| Key          | Action                           |
|--------------|----------------------------------|
| `<leader>td` | Debug nearest test               |
| `<leader>tf` | Debug current test file          |
| `<leader>tP` | Debug current test package       |
| `<leader>tD` | Debug all tests                  |
| `<leader>jd` | Debug main class/Spring Boot app |

Main launch uses `util.java_launch`; tests use `util.neotest_intellij` with
IntelliJ compilation/classpaths and the JUnit Console launcher.

#### Workflow Example

1. **Open test file** (e.g., `UserControllerTest.java`) and place cursor on test method
2. **Set breakpoints** with `<leader>db` on lines where you expect the bug
3. **Start debugging**: `<leader>td`
4. **Wait for Maven/Gradle compilation** and the IntelliJ debug panel to open
5. **Use DAP controls**:
    - `<leader>dc` — Continue to breakpoint
    - `<leader>di` — Step into method
    - `<leader>dO` — Step over method
    - `<leader>de` — Select expression and evaluate (e.g., `user.getName()`)
    - `<leader>du` — Toggle DAP UI (variables, call stack, REPL)
6. **Fix and re-run** or terminate with `<leader>dt`

#### Troubleshooting

| Issue                    | Fix                                                                |
|--------------------------|--------------------------------------------------------------------|
| "No debug session found" | Run `:JavaInfo` — ensure IntelliJ is attached and ready            |
| "Failed to start"        | Check build output with `<leader>jl`; use `:JavaRestart` if needed |
| "Port already in use"    | Stop the Java program with `<leader>jc` and retry                  |
| Breakpoints not hitting  | Check `:JavaInfo` and build/program output with `<leader>jl`       |

**See also:** `docs/java/java-debugging.md` for complete reference.

---

## Git Integration

### LazyGit

| Key          | Action       |
|--------------|--------------|
| `<leader>Gg` | Open LazyGit |
| `<A-g>`      | Open LazyGit |

**Inside LazyGit window:**

| Key     | Action                                    |
|---------|-------------------------------------------|
| `<esc>` | Back / Cancel                             |
| `o`     | Open file in same nvim tab, close LazyGit |
| `e`     | Edit selected file via LazyGit            |
| `q`     | Quit lazygit                              |
| `<C-q>` | Exit terminal mode (back to nvim)         |

**Custom LazyGit commands:**

| Key | Context        | Action                                           |
|-----|----------------|--------------------------------------------------|
| `F` | Anywhere       | Fetch menu: all, all + prune, or selected remote |
| `U` | Anywhere       | Pull menu: merge, `--rebase`, autostash, ff-only |
| `X` | Local branches | Delete local branches whose upstream is `[gone]` |

Notes:

- `X` runs `git fetch --prune` first, then removes local branches whose upstream no longer exists.
- `X` never deletes the currently checked out branch.
- `U` can pull from the tracked upstream or an explicitly chosen remote/branch.
- `o` is overridden through LazyGit `os.open` to open the file in the current Neovim server and close the LazyGit float.
- These commands are loaded by `lazygit.nvim` from `~/.config/nvim/lazygit/config.yml`.

### Diffview

| Key          | Action                          |
|--------------|---------------------------------|
| `<leader>GD` | Repo diff (DiffviewOpen)        |
| `<leader>GF` | File history                    |
| `<leader>GH` | Repo history                    |
| `<leader>GL` | Line history (normal)           |
| `<leader>GL` | Range history (visual)          |
| `<leader>Gt` | Open `git mergetool`            |
| `<leader>GC` | Find committed conflict markers |
| `<leader>GQ` | Finish `git mergetool`          |
| `<leader>GA` | Abort `git mergetool`           |
| `<leader>Gb` | Diff vs branch/ref              |
| `<leader>Gm` | Diff vs main/master             |
| `<leader>GM` | Diff vs origin/main             |
| `<leader>Gq` | Close Diffview                  |

Keep the Diffview lhs definitions only in `lua/config/keymaps.lua`. If the same
lhs is duplicated in a lazy.nvim plugin `keys` list, lazy.nvim can delete the
real mapping on first use and it will not be restored for command-only plugins.

**Inside Diffview:**

| Key          | Action                   |
|--------------|--------------------------|
| `<leader>Gq` | Close Diffview           |
| `<tab>`      | Next changed file        |
| `<S-tab>`    | Prev changed file        |
| `[x` / `]x`  | Prev / Next conflict     |
| `<leader>Co` | Choose ours (conflict)   |
| `<leader>Ct` | Choose theirs (conflict) |
| `<leader>Cb` | Choose both (conflict)   |
| `<leader>CB` | Choose base (conflict)   |
| `<leader>C0` | Choose none (conflict)   |
| `dx`         | Delete conflict region   |

### Merge Conflict Resolution

#### What a conflict looks like in the file

When a merge produces conflicts, Git inserts markers into the file:

```
<<<<<<< HEAD
your changes  (the branch you are currently on)
=======
their changes (the branch you are merging in)
>>>>>>> feature-branch
```

Both sets of changes are present — you must decide which to keep.

---

#### Full workflow: merging a branch and resolving conflicts

**Step 1 — Start the merge**

Option A: in the terminal

```
git merge feature-branch
```

Option B: in lazygit (`<leader>Gg`)

- Navigate to `Branches` panel (`4`)
- Highlight the branch you want to merge in
- Press `M` → confirm

**Step 2 — Git stops with conflicts**

The merge is paused. Conflicted files are not yet staged. You will see them as `AA` (both modified) in lazygit's Files panel, or as `UU` in `git status`.

**Step 3 — Open a conflicted file in nvim**

In lazygit: press `e` on any conflicted file to open it in nvim.
From terminal: just open the file normally (`nvim path/to/file`).

git-conflict.nvim activates automatically when it detects markers in the file.

If you launch the external merge tool from lazygit or Git, you get **nvimdiff**
instead of inline markers. In this setup the windows are:

- `LOCAL` (top-left) = your side
- `REMOTE` (top-right) = incoming side
- `MERGED` (bottom) = the result you keep

**Step 4 — Navigate conflicts**

| Key  | Action                |
|------|-----------------------|
| `]x` | Jump to next conflict |
| `[x` | Jump to prev conflict |

**Step 5 — Resolve each conflict**

For simple conflicts (pick one side or both):

| Key          | Action                                    |
|--------------|-------------------------------------------|
| `<leader>Co` | Keep **ours** (current branch, HEAD)      |
| `<leader>Ct` | Keep **theirs** (incoming branch)         |
| `<leader>Cb` | Keep **both** (ours first, theirs second) |
| `<leader>C0` | Keep **neither** (delete both sides)      |

After pressing one of these, the markers disappear and the chosen content stays. Move to the next conflict with `]x` and repeat.

For complex conflicts (you need to hand-edit the result):

- Delete the marker lines manually (`<<<<<<< HEAD`, `=======`, `>>>>>>> ...`)
- Edit the remaining code however you need
- Save with `<C-s>`

If you are in **nvimdiff mergetool** instead of inline markers:

| Key          | Action                      |
|--------------|-----------------------------|
| `]c`         | Jump to next diff hunk      |
| `[c`         | Jump to previous diff hunk  |
| `<leader>GQ` | Write all and quit (`:wqa`) |
| `<leader>GA` | Abort merge tool (`:cq`)    |

Notes:

- The exact pane layout is controlled by your Git merge-tool configuration.
- Use `<C-h/j/k/l>` to focus a pane and `:diffget` to copy from a selected reference
  buffer; this repo does not install LOCAL/REMOTE/MERGED focus shortcuts.
- The `<leader>Co/Ct` keys resolve inline marker blocks or Diffview conflicts;
  they are not classic vimdiff copy-hunk mappings.

**Step 6 — Need more context? Use Diffview 3-way view**

If a conflict is hard to understand from the inline markers alone, open the full 3-way merge view:

```
:DiffviewOpen
```

This shows 4 panels: **OURS** (left) | **BASE** (middle, common ancestor) | **THEIRS** (right) | **RESULT** (bottom).

| Key          | Action in Diffview merge view |
|--------------|-------------------------------|
| `]x` / `[x`  | Next / prev conflict          |
| `<leader>Co` | Accept ours into result       |
| `<leader>Ct` | Accept theirs into result     |
| `<leader>Cb` | Accept both into result       |
| `<leader>CB` | Accept base into result       |
| `<leader>C0` | Accept none into result       |
| `dx`         | Delete conflict region        |
| `q`          | Close panel                   |

When done: `:DiffviewClose` or `<leader>Gq`

**Step 7 — Stage the resolved file**

In lazygit: press `<space>` on the file to stage it.
From terminal: `git add path/to/file`

Repeat steps 3–7 for each conflicted file.

**Step 8 — Complete the merge**

In lazygit: press `c` to commit — Git pre-fills the merge commit message, just confirm.
From terminal: `git commit` (no `-m` needed, Git opens your editor with the message).

---

#### Quick reference cheatsheet

```
git merge feature-branch   →  conflicts appear
open file in nvim          →  markers highlighted automatically
]x / [x                    →  jump between conflicts
<leader>Co / Ct / Cb / C0  →  resolve inline (ours/theirs/both/none)
classic vimdiff mergetool  →  navigate panes, use :diffget and edit MERGED
:wqa or <leader>GQ         →  finish mergetool
:cq or <leader>GA          →  abort mergetool
:DiffviewOpen              →  3-way view for complex cases
stage file in lazygit      →  <space>
git commit                 →  finalize merge
```

### Gitsigns (in-buffer)

| Key           | Action            |
|---------------|-------------------|
| `]h` / `[h`   | Next / Prev hunk  |
| `<leader>Ghs` | Stage hunk        |
| `<leader>Ghr` | Reset hunk        |
| `<leader>GhS` | Stage buffer      |
| `<leader>GhR` | Reset buffer      |
| `<leader>Ghu` | Undo stage hunk   |
| `<leader>Ghp` | Preview hunk      |
| `<leader>Ghb` | Blame line (full) |
| `<leader>GhB` | Toggle blame      |
| `<leader>GhF` | Blame file        |
| `<leader>Ghd` | Diff this         |
| `<leader>Ghw` | Toggle word diff  |
| `<leader>Ghl` | Toggle line hl    |
| `<leader>Ghv` | Toggle deleted    |
| `ih`          | Text object: hunk |

---

## Yank History (Yanky)

| Key          | Action                              |
|--------------|-------------------------------------|
| `p` / `P`    | Paste after / before (yanky-aware)  |
| `<C-p>`      | Cycle forward through yank history  |
| `<C-n>`      | Cycle backward through yank history |
| `<C-CR>`     | Open Telescope yank history picker  |
| `<C-A-CR>`   | Open built-in yank ring picker      |
| `<leader>Hy` | Open Telescope yank history picker  |

**Tip:** paste with `p`, then keep pressing `<C-p>` to replace the pasted text with earlier yanks.

---

## Harpoon (Quick File Switching)

| Key          | Action              |
|--------------|---------------------|
| `<leader>ha` | Add file to harpoon |
| `<leader>hh` | Open harpoon menu   |
| `<leader>hm` | Manage manual dirs  |
| `<leader>h1` | Go to file 1        |
| `<leader>h2` | Go to file 2        |
| `<leader>h3` | Go to file 3        |
| `<leader>h4` | Go to file 4        |

---

## Marks

| Key         | Action                                  |
|-------------|-----------------------------------------|
| `mx`        | Set mark x (a-z)                        |
| `m;`        | Toggle next available mark on this line |
| `m]` / `m[` | Next / previous mark                    |
| `dmx`       | Delete mark x                           |
| `dm-`       | Delete all marks in line                |
| `dm<space>` | Delete all marks in buffer              |
| `]'`        | End of last changed/yanked text         |
| `['`        | Start of last changed/yanked text       |
| `` `x ``    | Jump to mark x                          |
| `'x`        | Jump to mark line                       |

---

## UI & Toggles

| Key          | Action                                            |
|--------------|---------------------------------------------------|
| `<leader>us` | Toggle spell                                      |
| `<leader>uw` | Toggle wrap                                       |
| `<leader>ul` | Toggle relative numbers                           |
| `<leader>un` | Toggle line numbers                               |
| `<leader>uf` | Toggle fold                                       |
| `<leader>um` | Toggle mouse                                      |
| `<leader>ud` | Toggle inline diagnostics (enabled on LSP attach) |
| `<leader>uD` | Toggle diagnostics                                |
| `<leader>ug` | Toggle live git hunks view                        |
| `<leader>uh` | Toggle inlay hints                                |
| `<leader>uu` | Toggle reference underline                        |
| `<leader>uH` | Toggle reference background                       |
| `<leader>ui` | Inspect UI/highlights                             |
| `<leader>uT` | Toggle Treesitter buffer                          |
| `<leader>uI` | Toggle references buffer                          |
| `<leader>ut` | Color schemes                                     |
| `<leader>ua` | Toggle buffer auto-save                           |

---

## Tabs

A Neovim tab is a tab page: a layout containing one or more windows. It shares
the same global buffer list with every other tab.

| Key                  | Action    |
|----------------------|-----------|
| `[<tab>`             | Prev tab  |
| `]<tab>`             | Next tab  |
| `<leader><tab>]`     | Next tab  |
| `<leader><tab>[`     | Prev tab  |
| `<leader><tab>f`     | First tab |
| `<leader><tab>l`     | Last tab  |
| `<leader><tab><tab>` | New tab   |
| `<leader><tab>d`     | Close tab |

---

## Terminal Mode

### Toggleterm (floating terminal)

| Key     | Action                                                    |
|---------|-----------------------------------------------------------|
| `<A-a>` | Toggle floating terminal (normal/terminal modes)          |
| `<A-c>` | Hide Toggleterm from terminal mode; process keeps running |

### Inside terminal buffer

| Key          | Action                   |
|--------------|--------------------------|
| `<Esc>`      | Exit terminal mode       |
| `<C-\><C-n>` | Exit terminal mode (alt) |

**Note:** Terminal window navigation:

| Key     | Action             |
|---------|--------------------|
| `<C-h>` | Go to left window  |
| `<C-j>` | Go to lower window |
| `<C-k>` | Go to upper window |
| `<C-l>` | Go to right window |

---

## Go Development

### Running Go Programs

| Command                | Action                     |
|------------------------|----------------------------|
| `:term go run .`       | Run program in current dir |
| `:term go run main.go` | Run specific file          |
| `<leader>gr`           | Go run (keymap)            |
| `<leader>gR`           | Go run current file        |
| `<leader>gb`           | Go build                   |
| `<leader>gt`           | Go test all                |

### Go Struct Tags (Gopher.nvim)

| Key           | Action               |
|---------------|----------------------|
| `<leader>gsj` | Add JSON struct tags |
| `<leader>gsy` | Add YAML struct tags |
| `<leader>gsd` | Add DB struct tags   |
| `<leader>gie` | Add `if err != nil`  |

### Go Debugging

| Key           | Action             |
|---------------|--------------------|
| `<leader>dgt` | Debug Go test      |
| `<leader>dgl` | Debug last Go test |

---

## Python Development

### Python Virtual Environments

| Key          | Action                               |
|--------------|--------------------------------------|
| `<leader>ps` | Select Python venv                   |
| `<leader>pc` | Create project-local venv            |
| `<leader>pr` | Recreate project-local venv          |
| `<leader>pi` | Install default deps into active env |
| `<leader>pI` | Prompt for custom `pip install` args |

Commands:

```vim
:PythonVenvSelect
:PythonVenvCreate .venv
:PythonVenvCreate .venv-py312 python3.12
:PythonVenvRecreate .venv
:PythonVenvInstall
:PythonVenvInstall pytest ruff
:PythonVenvInstall -r requirements-dev.txt
```

Notes:

- `:PythonVenvCreate` and `:PythonVenvRecreate` create envs under the current Python project root.
- `:PythonVenvInstall` uses the active venv from `venv-selector.nvim`.
- With no args, `:PythonVenvInstall` installs `requirements.txt` if present, otherwise `pip install -e .`.
- New terminals opened after activation inherit the selected venv automatically.
- If `${project_root}/.env` exists, it is loaded on Python venv activation and inherited by new terminals and test runs.
- Project-local envs come from the plugin's default workspace/file discovery; repo-managed envs under `~/.local/share/nvim/python-venvs` are added by local
  config.
- Managed-env discovery is pinned to the resolved `fd`/`fdfind` binary path so `<leader>ps` does not depend on how Neovim's startup `PATH` was built.
- `:PyrightInfo` shows the exact `pyright-langserver` command/path used by the current Neovim session.
- `:PythonLspUseBasedPyright` switches Python buffers to BasedPyright for the current session; `:PythonLspUsePyright` switches back.
- Python formatting uses the standalone IntelliJ jar; Ruff provides linting.
- Use `<leader>tt` to run the current Python test target after selecting a venv. `neotest-python` resolves Python from the active venv and `.env`
  values loaded during venv activation are inherited by test runs.

---

## Miscellaneous

| Key          | Action                            |
|--------------|-----------------------------------|
| `<leader>fn` | New file                          |
| `<leader>U`  | Undotree toggle                   |
| `<leader>Pl` | Open Lazy                         |
| `<leader>Xh` | Rehighlight treesitter            |
| `<leader>XC` | Clear owning Java workspace index |
| `<leader>XJ` | Clear owning Java workspace index |

---

## Which-Key Groups

Press `<leader>` and wait to see all groups:

| Prefix          | Group             |
|-----------------|-------------------|
| `<leader>b`     | Buffer            |
| `<leader>c`     | Code              |
| `<leader>C`     | Conflict          |
| `<leader>d`     | Debug             |
| `<leader>dg`    | Debug Go          |
| `<leader>f`     | File/Find         |
| `<leader>g`     | Go                |
| `<leader>gi`    | Go Insert         |
| `<leader>gs`    | Go Struct Tags    |
| `<leader>G`     | Git               |
| `<leader>Gh`    | Hunks             |
| `<leader>h`     | Harpoon/Dirs      |
| `<leader>l`     | LSP               |
| `<leader>j`     | Java              |
| `<leader>O`     | Obsidian          |
| `<leader>p`     | Python            |
| `<leader>P`     | Plugins           |
| `<leader>q`     | Quit/Session      |
| `<leader>r`     | Replace           |
| `<leader>s`     | Search            |
| `<leader>S`     | Sessions          |
| `<leader>t`     | Test/Theme        |
| `<leader>u`     | UI                |
| `<leader>w`     | Windows           |
| `<leader>x`     | Diagnostics       |
| `<leader>X`     | Lists/Maintenance |
| `<leader><tab>` | Tabs              |
| `[`             | Previous          |
| `]`             | Next              |
| `g`             | Goto/Misc         |
| `gc`            | Comment           |
| `gs`            | Surround          |
| `z`             | Fold              |

---

## Tips

1. **Flash Jump**: Press `s`, enter search text, then choose a label
2. **Text Objects**: Use `i` for inside, `a` for around (e.g., `diw` = delete word)
3. **Dot Command**: `.` repeats the last change
4. **Registers**: `"ay` yanks to register `a`, `"ap` pastes from register `a`
5. **Macros**: `qa` records to `a`, `q` stops, `@a` plays, `@@` repeats last
6. **Marks**: Use uppercase marks (A-Z) for global marks across files
7. **Jumplist**: `<C-o>` and `<C-i>` to navigate back/forward in jump history

---

## Sessions

Sessions are saved per working directory and Git branch, excluding configured
suppressed directories (`~/`, `~/Downloads`, `/`, `/tmp`). Restores open files,
splits, and cursor positions. Non-startup restores stop attached LSP clients
before loading the saved workspace.
Auto-save also works when Neovim is launched with file arguments.
Pins and the arranged buffer order are saved separately for each directory/branch
and restored after restarting Neovim or returning to that branch. Use
`<leader>bp` to pin/unpin, then `<leader>Ss` to save immediately (normal exit and
branch switching also save automatically). Existing sessions acquire pin/order
metadata on their next save; older sessions cannot recover previously lost pins.
The Git watcher also runs when startup finds no saved session, including from
nested directories and worktrees. A new branch with no session keeps the current
buffers. Session selection with `<leader>Sf` restores editor state and does not
check out the selected session's Git branch.
Buffer auto-save starts enabled by default and writes normal file buffers even
when the current buffer has LSP errors. Conform still skips format-on-save when
errors exist. Toggle auto-save with `<leader>ua`.

| Key          | Action                   |
|--------------|--------------------------|
| `<leader>Ss` | Save session             |
| `<leader>Sr` | Restore session          |
| `<leader>Sd` | Delete session           |
| `<leader>Sf` | Find sessions            |
| `<leader>Sa` | Enable session auto-save |

---

## Obsidian (Notes)

Vault: `~/Obsidian`, resolved from your home. Obsidian integration applies inside
that vault. Ordinary Markdown keeps its local heading-link `<CR>` mapping.

### Navigation

| Key    | Action                                     |
|--------|--------------------------------------------|
| `<CR>` | Follow `[[wikilink]]` or `[text](#anchor)` |

### Note Management

| Key          | Action                                 |
|--------------|----------------------------------------|
| `<leader>Of` | Quick switch between notes (Telescope) |
| `<leader>Os` | Full-text search across vault          |
| `<leader>On` | New note                               |
| `<leader>Or` | Rename note (updates all links)        |
| `<leader>Oo` | Open current note in Obsidian app      |

### Links & Tags

| Key          | Action                    |
|--------------|---------------------------|
| `<leader>Ob` | Backlinks to current note |
| `<leader>Ol` | All links in current note |
| `<leader>Ot` | Browse tags               |

### Other

| Key          | Action                     |
|--------------|----------------------------|
| `<leader>Oc` | Toggle `- [ ]` checkbox    |
| `<leader>Od` | Daily notes                |
| `<leader>Op` | Paste image from clipboard |

---

## LeetCode

| Key                                        | Action                     |
|--------------------------------------------|----------------------------|
| `<leader>Ll`                               | Menu                       |
| `<leader>Lr` / `<leader>Ls`                | Run / submit               |
| `<leader>Ld` / `<leader>Ln`                | Daily / random problem     |
| `<leader>Lc` / `<leader>Li` / `<leader>Lt` | Console / info / tabs      |
| `<leader>Le` / `<leader>Lm` / `<leader>Lh` | Easy / medium / hard lists |
| `<leader>LR`                               | DSA roadmap picker         |
| `<leader>LU`                               | Refresh cookies            |

`:Leet`, `:LeetRoadmap`, and `:LeetCookies` also load the integration.
Java local debugging uses a project harness; see
[Java LeetCode debugging](../java/java-leetcode-debugging.md).

Runtime toggle preferences survive restarts through `persist-toggle.nvim`.
Use `:PersistToggleInfo` to inspect them; see [preferences](preferences.md) for
IDs and reset commands.
