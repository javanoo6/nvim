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

---

## Vim Basics

### Modes

| Key              | Action                             |
|------------------|------------------------------------|
| `i`              | Insert mode (before cursor)        |
| `a`              | Insert mode (after cursor)         |
| `I`              | Insert at beginning of line        |
| `A`              | Insert at end of line              |
| `o`              | Open new line below (enter insert) |
| `O`              | Open new line above (enter insert) |
| `ga`             | **Add line above** (stay normal)   |
| `gA`             | **Add line below** (stay normal)   |
| `v`              | Visual mode                        |
| `V`              | Visual line mode                   |
| `<C-v>`          | Visual block mode                  |
| `Esc` or `<C-[>` | Return to normal mode              |
| `:`              | Command mode                       |

**Visual block tip:** After `<C-v>`, you can edit multiple lines column-wise with `I` or `A`.
Type your text, then press `Esc` to apply it to every selected line.
Until you press `Esc`, it may look like only one line changed.

### Saving & Quitting

| Key           | Action              |
|---------------|---------------------|
| `:w`          | Save file           |
| `:q`          | Quit                |
| `:wq` or `ZZ` | Save and quit       |
| `:q!`         | Quit without saving |
| `<C-s>`       | Save (in any mode)  |
| `<leader>qq`  | Quit all            |

---

## Movement & Navigation

### Basic Movement

| Key             | Action                                |
|-----------------|---------------------------------------|
| `h` `j` `k` `l` | Left, Up, Down, Right                 |
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
- because this config swaps vertical movement, `j` means up and `k` means down

Examples:

| Keys   | Action                                    |
|--------|-------------------------------------------|
| `5j`   | Move up 5 lines                           |
| `5k`   | Move down 5 lines                         |
| `3w`   | Move forward 3 words                      |
| `10dd` | Delete 10 lines                           |
| `3yy`  | Yank 3 lines                              |
| `5>>`  | Indent 5 lines right                      |
| `d3w`  | Delete 3 words forward                    |
| `c2j`  | Change from cursor through 2 lines upward |
| `y4k`  | Yank through 4 lines downward             |
| `V5j`  | Select 5 lines upward in visual line mode |

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

| Key                    | Action                            |
|------------------------|-----------------------------------|
| `s`                    | Flash jump (type 2 chars to jump) |
| `S`                    | Flash treesitter (select node)    |
| `r` (operator)         | Remote flash                      |
| `R` (operator/visual)  | Treesitter search                 |
| `<C-s>` (command mode) | Toggle flash search               |

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

| Key     | Action                    |
|---------|---------------------------|
| `<C-h>` | Delete previous character |
| `<C-w>` | Delete previous word      |
| `<C-u>` | Delete to start of line   |
| `<C-a>` | Go to start of line r     |
| `<C-e>` | Go to end of line         |
| `<C-n>` | Next completion           |
| `<C-p>` | Previous completion       |

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
| `J`     | Join lines (keeps cursor position) |
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

| Key | Meaning                                                     |
|-----|-------------------------------------------------------------|
| `q` | Start recording into a register, or stop recording          |
| `Q` | Legacy Ex mode command; usually not part of normal workflow |

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

### Text Objects (Mini.ai)

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
| `<A-j>`                                 | Move line up   |
| `<A-k>`                                 | Move line down |
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
- `V5jgc` - Select 5 lines down, then comment all
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

### Replace (in-buffer)

| Key              | Action                           |
|------------------|----------------------------------|
| `:s/old/new/`    | Replace first occurrence in line |
| `:s/old/new/g`   | Replace all in line              |
| `:%s/old/new/g`  | Replace all in file              |
| `:%s/old/new/gc` | Replace all with confirmation    |

### Replace (project-wide — grug-far)

| Key          | Mode   | Action                                              |
|--------------|--------|-----------------------------------------------------|
| `<leader>rg` | normal | Open scoped to **current file** (Paths pre-filled)  |
| `<leader>rG` | normal | Open across **all files** (blank, full project)     |
| `<leader>rw` | normal | Open with word under cursor, scoped to current file |
| `<leader>rg` | visual | Open with selection, scoped to current file         |

**How to use grug-far:**

1. Open with one of the keys above
2. Fill in **Search** and **Replace** fields (`Tab` to move between them)
3. Results preview updates live as you type
4. Press `\r` (`<localleader>r`) to **apply** all replacements
5. Press `q` to close

**Tip:** Clear the **Paths** field to expand search to the whole project. Use glob patterns like `*.go` in Paths to scope by filetype.

### Replace (within visual selection)

| Key          | Mode   | Action                                       |
|--------------|--------|----------------------------------------------|
| `<leader>rw` | visual | `:s/\%V` — replace only within selected text |

**Tip:** After `<leader>rw` in visual mode, type your pattern and replacement: `old/new/g` then `<CR>`.

## Window Management

### Navigation

| Key     | Action             |
|---------|--------------------|
| `<C-h>` | Go to left window  |
| `<C-j>` | Go to up window    |
| `<C-k>` | Go to down window  |
| `<C-l>` | Go to right window |

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
| `<C-w>                   | Maximize width      |

---

## Buffer Management

| Key               | Action                      |
|-------------------|-----------------------------|
| `[b` / `]b`       | Prev / Next buffer          |
| `<S-h>` / `<S-l>` | Prev / Next buffer (alt)    |
| `<leader>bb`      | Alternate buffer            |
| `<leader>bd`      | Delete buffer               |
| `<leader>b-`      | Move current buffer below   |
| `<leader>b\|`     | Move current buffer right   |
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
| `<C-f>` | Scroll preview down                               |
| `<C-b>` | Scroll preview up                                 |
| `<C-v>` | Open in vertical split                            |
| `<C-x>` | Open in horizontal split                          |
| `<C-t>` | Open in new tab                                   |
| `a`     | Add file/folder                                   |
| `d`     | Delete                                            |
| `r`     | Rename                                            |
| `c`     | Copy                                              |
| `m`     | Move                                              |
| `H`     | Toggle hidden files                               |

**Tip:** Renaming or moving a Java file via `r` / `m` triggers LSP file operations — JDTLS automatically updates all imports and references
across the project. This may modify many buffers at once. Save them all with `:wall`.

**Preview tip:** `P` uses Neo-tree's native preview mode, so you can scan files without leaving the tree. Press `<Esc>` to close the preview.

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

---

## Telescope (Fuzzy Finder)

| Key               | Action                       |
|-------------------|------------------------------|
| `<leader><space>` | Find files from cwd          |
| `<leader>ff`      | Find files from cwd          |
| `<leader>fF`      | Find files from project root |
| `<leader>fg`      | Live grep from cwd           |
| `<leader>fG`      | Live grep from project root  |
| `<leader>fb`      | Buffers                      |
| `<leader>fR`      | Recent files                 |
| `<leader>fs`      | New scratch file             |
| `<leader>fS`      | Open scratch file            |
| `<leader>fi`      | Scratch path info            |
| `<leader>fN`      | New named scratch file       |
| `<leader>Hy`      | Yank history                 |
| `<leader>Hc`      | Command history              |
| `<leader>Hs`      | Search history               |
| `<leader>:`       | Command history              |
| `<leader>ss`      | Document symbols             |
| `<leader>sS`      | Workspace symbols            |
| `<leader>st`      | Search TODOs                 |
| `<leader>fe`      | Grep by file extension       |
| `<leader>fr`      | Resume last search           |

### Inside Telescope

| Key               | Action                                                       |
|-------------------|--------------------------------------------------------------|
| `<C-j>` / `<C-k>` | Previous / Next                                              |
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
  JDTLS can resolve project dependencies.

**Tip:** `<leader>fe` prompts for an extension (e.g. `java`, `go`, `py`) then opens live grep scoped to `*.{ext}` files only.

**Tip:** `<leader>fr` resumes the last Telescope search exactly where you left off — useful for returning to a search after editing a file.

### Workflow: Edit multiple files from a search

Use this when you need to rename variables or make targeted edits across many files one by one:

1. `<leader>ff` or `<leader>fe` — search for files
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

After `gd`, `gR`, `gy`, or `gI`, Glance opens a results list with a file preview.

| Key                 | Action                           |
|---------------------|----------------------------------|
| `j` / `<Up>`        | Previous result                  |
| `k` / `<Down>`      | Next result                      |
| `<Tab>` / `<S-Tab>` | Next / previous location         |
| `<C-u>` / `<C-d>`   | Scroll preview up / down         |
| `<CR>`              | Jump to selected result          |
| `v` / `s` / `t`     | Open in vsplit / split / new tab |
| `o`                 | Refresh preview                  |
| `<leader>l`         | Switch between list and preview  |
| `q` / `Q` / `<Esc>` | Close Glance                     |

### Documentation

| Key  | Action              |
|------|---------------------|
| `K`  | Hover documentation |
| `gK` | Signature help      |

### Code Actions

| Key                     | Action                                                     |
|-------------------------|------------------------------------------------------------|
| `<leader>ca` / `<A-CR>` | Code action                                                |
| `<leader>cr`            | Rename                                                     |
| `<leader>cp`            | Fix package declaration                                    |
| `<leader>ci`            | Java: import class under cursor, prompt if ambiguous       |
| `<leader>cI`            | Java: import unambiguous classes in buffer                 |
| `<leader>cf`            | Format (Java: IntelliJ formatter)                          |
| `<leader>cF`            | Format current file's directory, or prompt for a directory |

### Symbols & Outline

| Key          | Action                        |
|--------------|-------------------------------|
| `<leader>cs` | Symbols (Trouble)             |
| `<leader>cl` | Call hierarchy (Trouble)      |
| `<leader>cu` | Usages / references (Trouble) |

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

| Key          | Action                     |
|--------------|----------------------------|
| `<leader>db` | Toggle breakpoint          |
| `<leader>dB` | Breakpoint with condition  |
| `<leader>dc` | Continue / Start debugging |
| `<leader>dC` | Run to cursor              |
| `<leader>di` | Step into                  |
| `<leader>do` | Step out                   |
| `<leader>dO` | Step over                  |
| `<leader>dg` | Go to line (no execute)    |
| `<leader>dl` | Run last                   |
| `<leader>dp` | Pause                      |
| `<leader>dr` | Toggle REPL                |
| `<leader>dt` | Terminate                  |
| `<leader>ds` | Session info               |
| `<leader>dj` | Up (call stack)            |
| `<leader>dk` | Down (call stack)          |
| `<leader>dw` | Hover widgets              |
| `<leader>du` | Toggle DAP UI              |
| `<leader>de` | Evaluate expression        |

---

## Testing (Neotest)

| Key          | Action                      |
|--------------|-----------------------------|
| `<leader>tt` | Run file                    |
| `<leader>tT` | Run all test files          |
| `<leader>tr` | Run nearest test            |
| `<leader>tp` | Run package                 |
| `<leader>tq` | Run file tests sequentially |
| `<leader>tl` | Run last                    |
| `<leader>tF` | Run failed tests            |
| `<leader>ts` | Toggle summary              |
| `<leader>to` | Show output                 |
| `<leader>tO` | Toggle output panel         |
| `<leader>tS` | Stop (interactive)          |
| `<leader>tw` | Toggle watch                |

### Java-specific

| Key          | Action              |
|--------------|---------------------|
| `<leader>jr` | Run Main            |
| `<leader>jc` | Stop Main           |
| `<leader>jt` | Test Current Class  |
| `<leader>jm` | Test Current Method |
| `<leader>jv` | View Test Report    |

### Java Code Actions

Java refactors and generate actions come from JDTLS code actions.
Use `<leader>ca` or `<A-CR>` to open the code action list in
`actions-preview.nvim`.

Important limitation:

- edit-backed actions usually show a real diff preview before apply
- many Java refactors are command-only JDTLS actions, so they cannot be
  diff-previewed and may show the fallback “Preview is not available” message

This is expected behavior, not a broken Neovim or LSP setup.

---

### Java Debugging

**How Java debugging works:** `nvim-java` orchestrates `jdtls` → `java-debug-adapter` → `nvim-dap`. When you start debugging, JDTLS compiles the project, starts
a debug server on a port, and nvim-dap connects to it.

#### Starting Debug Sessions

| Command                       | Action                           |
|-------------------------------|----------------------------------|
| `:JavaTestDebugCurrentMethod` | Debug test method under cursor   |
| `:JavaTestDebugCurrentClass`  | Debug entire test class          |
| `:JavaTestDebugAllTests`      | Debug all tests in workspace     |
| `<leader>jd`                  | Debug main class/Spring Boot app |

**Via Lua API** (if you want custom keybindings):

```lua
require('java').test.debug_current_method()    -- Debug method
require('java').test.debug_current_class()     -- Debug class
require('util.java_debug').debug_main()        -- Debug main
```

#### Workflow Example

1. **Open test file** (e.g., `UserControllerTest.java`) and place cursor on test method
2. **Set breakpoints** with `<leader>db` on lines where you expect the bug
3. **Start debugging**: `:JavaTestDebugCurrentMethod`
4. **Wait 5-10s** for JDTLS to compile and DAP UI to open automatically
5. **Use DAP controls**:
    - `<leader>dc` — Continue to breakpoint
    - `<leader>di` — Step into method
    - `<leader>dO` — Step over method
    - `<leader>de` — Select expression and evaluate (e.g., `user.getName()`)
    - `<leader>du` — Toggle DAP UI (variables, call stack, REPL)
6. **Fix and re-run** or terminate with `<leader>dt`

#### Troubleshooting

| Issue                    | Fix                                                                                                 |
|--------------------------|-----------------------------------------------------------------------------------------------------|
| "No debug session found" | Run `:JavaInfo` or `:LspInfo` — ensure JDTLS is attached                                            |
| "Failed to start"        | Wait for JDTLS to load, or `:Lazy java` to reload                                                   |
| "Port already in use"    | Stale session — close nvim or `killall java`                                                        |
| Breakpoints not hitting  | Check `:LspInfo` for compilation errors, or check logs: `tail -f ~/.local/state/nvim/nvim-java.log` |

**See also:** `~/.config/nvim/JAVA_DEBUGGING.md` for complete reference.

---

## Git Integration

### LazyGit

| Key          | Action       |
|--------------|--------------|
| `<leader>Gg` | Open LazyGit |

**Inside LazyGit window:**

| Key     | Action                            |
|---------|-----------------------------------|
| `<esc>` | Back / Cancel                     |
| `q`     | Quit lazygit                      |
| `<C-q>` | Exit terminal mode (back to nvim) |

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
- These commands are loaded by `lazygit.nvim` from `~/.config/nvim/lazygit/config.yml`.

### Diffview

| Key          | Action                   |
|--------------|--------------------------|
| `<leader>GD` | Repo diff (DiffviewOpen) |
| `<leader>GF` | File history             |
| `<leader>GH` | Repo history             |
| `<leader>GL` | Line history (normal)    |
| `<leader>GL` | Range history (visual)   |
| `<leader>Gt` | Open `git mergetool`     |
| `<leader>GQ` | Finish `git mergetool`   |
| `<leader>GA` | Abort `git mergetool`    |
| `<leader>Gm` | Diff vs main/master      |
| `<leader>GM` | Diff vs origin/main      |
| `<leader>Gq` | Close Diffview           |

Keep the Diffview lhs definitions only in `lua/config/keymaps.lua`. If the same
lhs is duplicated in a lazy.nvim plugin `keys` list, lazy.nvim can delete the
real mapping on first use and it will not be restored for command-only plugins.

**Inside Diffview:**

| Key          | Action                   |
|--------------|--------------------------|
| `q`          | Close panel / quit       |
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

| Key          | Action                           |
|--------------|----------------------------------|
| `]x`         | Jump to next diff conflict       |
| `[x`         | Jump to prev diff conflict       |
| `<leader>Co` | Copy `LOCAL` hunk into `MERGED`  |
| `<leader>Ct` | Copy `REMOTE` hunk into `MERGED` |
| `<leader>Cl` | Focus `LOCAL` window             |
| `<leader>Cr` | Focus `REMOTE` window            |
| `<leader>Cm` | Focus `MERGED` window            |
| `<leader>GQ` | Write all and quit (`:wqa`)      |
| `<leader>GA` | Abort merge tool (`:cq`)         |

Notes:

- `BASE` is not present in this 3-window `nvimdiff` mergetool layout.
- Use Diffview only when you need common-ancestor context.
- Do your edits in `MERGED`. `LOCAL` and `REMOTE` are reference panes.

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
nvimdiff mergetool         →  <leader>Co / Ct pull LOCAL/REMOTE into MERGED
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

| Key         | Action                     |
|-------------|----------------------------|
| `mx`        | Toggle mark x (a-z)        |
| `dmx`       | Delete mark x              |
| `dm-`       | Delete all marks in line   |
| `dm<space>` | Delete all marks in buffer |
| `]'`        | Next mark                  |
| `['`        | Prev mark                  |
| `` `x ``    | Jump to mark x             |
| `'x`        | Jump to mark line          |

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
| `<leader>uh` | Toggle inlay hints                                |
| `<leader>uu` | Toggle reference underline                        |
| `<leader>uH` | Toggle reference background                       |
| `<leader>ui` | Inspect UI/highlights                             |
| `<leader>uT` | Toggle Treesitter buffer                          |
| `<leader>uI` | Toggle references buffer                          |
| `<leader>ut` | Color schemes                                     |

---

## Tabs

| Key                  | Action    |
|----------------------|-----------|
| `<leader><tab>]`     | Next tab  |
| `<leader><tab>[`     | Prev tab  |
| `<leader><tab>f`     | First tab |
| `<leader><tab>l`     | Last tab  |
| `<leader><tab><tab>` | New tab   |
| `<leader><tab>d`     | Close tab |

---

## Terminal Mode

### Toggleterm (floating terminal)

| Key     | Action                                |
|---------|---------------------------------------|
| `<A-a>` | Open / show terminal                  |
| `<A-c>` | Hide terminal (process keeps running) |

### Inside terminal buffer

| Key          | Action                   |
|--------------|--------------------------|
| `<Esc>`      | Exit terminal mode       |
| `<C-\><C-n>` | Exit terminal mode (alt) |

**Note:** Terminal window navigation:

| Key     | Action             |
|---------|--------------------|
| `<C-h>` | Go to left window  |
| `<C-j>` | Go to upper window |
| `<C-k>` | Go to lower window |
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
- Java class completion items can add imports through JDTLS completion edits. For pasted unresolved class names, use `<leader>ci` for the symbol under the
  cursor, or `<leader>cI` to walk the current buffer: one-candidate imports are applied automatically, and ambiguous imports are shown in a picker. Bulk Java
  organize-import cleanup is handled by the IntelliJ formatter bridge.
- Use `<leader>tt` to run the current Python test file/package after selecting a venv. `neotest-python` resolves Python from the active venv and `.env`
  values loaded during venv activation are inherited by test runs.

---

## Miscellaneous

| Key          | Action                 |
|--------------|------------------------|
| `<leader>fn` | New file               |
| `<leader>U`  | Undotree toggle        |
| `<leader>Pl` | Open Lazy              |
| `<leader>Xh` | Rehighlight treesitter |
| `<leader>XC` | Clean JDTLS workspace  |

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

1. **Flash Jump**: Press `s` then type 2 characters to jump anywhere
2. **Text Objects**: Use `i` for inside, `a` for around (e.g., `diw` = delete word)
3. **Dot Command**: `.` repeats the last change
4. **Registers**: `"ay` yanks to register `a`, `"ap` pastes from register `a`
5. **Macros**: `qa` records to `a`, `q` stops, `@a` plays, `@@` repeats last
6. **Marks**: Use uppercase marks (A-Z) for global marks across files
7. **Jumplist**: `<C-o>` and `<C-i>` to navigate back/forward in jump history

---

## Sessions

Auto-saved per project directory. Restores open files, splits, and cursor positions.
Auto-save also works when Neovim is launched with file arguments.
Buffer auto-save starts enabled by default and is blocked when the current
buffer has LSP errors. Toggle it with `<leader>ua`.

| Key          | Action           |
|--------------|------------------|
| `<leader>Ss` | Save session     |
| `<leader>Sr` | Restore session  |
| `<leader>Sd` | Delete session   |
| `<leader>Sf` | Find sessions    |
| `<leader>Sa` | Enable auto-save |

---

## Obsidian (Notes)

Vault: `~/Obsidian`. Active only in `.md` files.

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

_Generated for your Neovim setup_
