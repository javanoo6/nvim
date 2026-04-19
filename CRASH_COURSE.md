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
8. [File Explorer](#file-explorer)
9. [LSP & Code Navigation](#lsp--code-navigation)
10. [Debugging](#debugging)
11. [Testing](#testing)
12. [Git Integration](#git-integration)
13. [UI & Toggles](#ui--toggles)
14. [Telescope (Fuzzy Finder)](#telescope-fuzzy-finder)
15. [Harpoon (Quick File Switching)](#harpoon-quick-file-switching)
16. [Marks](#marks)
17. [Terminal Mode](#terminal-mode)
18. [Go Development](#go-development)
19. [Miscellaneous](#miscellaneous)
20. [Sessions](#sessions)
21. [Obsidian (Notes)](#obsidian-notes)

---

## Vim Basics

### Modes

| Key              | Action                             |
| ---------------- | ---------------------------------- |
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

### Saving & Quitting

| Key           | Action              |
| ------------- | ------------------- |
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
| --------------- | ------------------------------------- |
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

### Scrolling (Centered)

| Key     | Action                         |
| ------- | ------------------------------ |
| `<C-u>` | Scroll up half page (centered) |
| `<C-f>` | Scroll down full page          |
| `<C-b>` | Scroll up full page            |
| `zz`    | Center cursor on screen        |

### Fast Navigation (Flash.nvim)

| Key                    | Action                            |
| ---------------------- | --------------------------------- |
| `s`                    | Flash jump (type 2 chars to jump) |
| `S`                    | Flash treesitter (select node)    |
| `r` (operator)         | Remote flash                      |
| `R` (operator/visual)  | Treesitter search                 |
| `<C-s>` (command mode) | Toggle flash search               |

### Jump Lists

| Key     | Action       |
| ------- | ------------ |
| `<C-o>` | Jump back    |
| `<C-i>` | Jump forward |

### Buffer Navigation

| Key          | Action                       |
| ------------ | ---------------------------- |
| `[b`         | Previous buffer              |
| `]b`         | Next buffer                  |
| `<S-h>`      | Previous buffer (alt)        |
| `<S-l>`      | Next buffer (alt)            |
| `<leader>bb` | Alternate buffer (last used) |
| `<leader>bd` | Delete buffer                |

### Quickfix & Location List

| Key  | Action                    |
| ---- | ------------------------- |
| `]q` | Next trouble/quickfix     |
| `[q` | Previous trouble/quickfix |
| `[l` | Previous location list    |
| `]l` | Next location list        |

---

## Editing & Text Objects

### Insert Mode

| Key     | Action                    |
| ------- | ------------------------- |
| `<C-h>` | Delete previous character |
| `<C-w>` | Delete previous word      |
| `<C-u>` | Delete to start of line   |
| `<C-a>` | Go to start of line r     |
| `<C-e>` | Go to end of line         |
| `<C-n>` | Next completion           |
| `<C-p>` | Previous completion       |

### Operators (wait for motion)

| Key  | Action                          |
| ---- | ------------------------------- |
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
| ------- | ---------------------------------- |
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

### Text Objects (Mini.ai)

| Object        | Description                        |
| ------------- | ---------------------------------- |
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
| --------------------- | ---------------------- |
| `m` (visual/operator) | Select treesitter node |

### Treesitter Incremental Selection

| Key       | Action                         |
| --------- | ------------------------------ |
| `<cr>`    | Initialize/Increment selection |
| `<tab>`   | Increment node                 |
| `<S-tab>` | Decrement scope                |
| `<bs>`    | Scope increment                |

### Moving Lines

| Key                                     | Action         |
| --------------------------------------- | -------------- |
| `<A-j>`                                 | Move line up   |
| `<A-k>`                                 | Move line down |
| (Works in normal, insert, visual modes) |

### Duplicating Lines (IntelliJ-style)

| Key     | Mode   | Action                                                       |
| ------- | ------ | ------------------------------------------------------------ |
| `<C-d>` | normal | Duplicate current line below, cursor moves to the copy       |
| `<C-d>` | visual | Duplicate all lines in selection below, cursor on first copy |

### Surround (Mini.surround)

| Key   | Action                                                     |
| ----- | ---------------------------------------------------------- |
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
| --------------- | --------- | ----------------- |
| `viw` (word)    | `gsa"`    | `"word"`          |
| `V` (line)      | `gsa(`    | `(selected line)` |
| `viw`           | `gsa[`    | `[word]`          |
| `viw`           | `gsa{`    | `{word}`          |
| `viw`           | ``gsa` `` | `` `word` ``      |

---

## Commenting

| Key   | Action                                 |
| ----- | -------------------------------------- |
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
| ------- | ----------------------------------- |
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
| ---------------- | -------------------------------- |
| `:s/old/new/`    | Replace first occurrence in line |
| `:s/old/new/g`   | Replace all in line              |
| `:%s/old/new/g`  | Replace all in file              |
| `:%s/old/new/gc` | Replace all with confirmation    |

### Replace (project-wide — grug-far)

| Key          | Mode   | Action                                              |
| ------------ | ------ | --------------------------------------------------- |
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
| ------------ | ------ | -------------------------------------------- |
| `<leader>rw` | visual | `:s/\%V` — replace only within selected text |

**Tip:** After `<leader>rw` in visual mode, type your pattern and replacement: `old/new/g` then `<CR>`.

### Refactoring (refactoring.nvim — treesitter-based)

Select code visually first, then:

| Key          | Mode   | Action                   |
| ------------ | ------ | ------------------------ |
| `<leader>Re` | visual | Extract function         |
| `<leader>Rf` | visual | Extract function to file |
| `<leader>Rv` | visual | Extract variable         |
| `<leader>Ri` | n/v    | Inline variable          |
| `<leader>Rb` | normal | Extract block            |
| `<leader>RB` | normal | Extract block to file    |

**Tip:** For extract function/variable, visually select the expression or block first, then press the key. Supports Go, Java, Python, Lua, JS/TS.

---

## Window Management

### Navigation

| Key     | Action             |
| ------- | ------------------ |
| `<C-h>` | Go to left window  |
| `<C-j>` | Go to down window  |
| `<C-k>` | Go to up window    |
| `<C-l>` | Go to right window |

### Move Buffer to Split

| Key          | Action                      |
| ------------ | --------------------------- |
| `<leader>wj` | Move buffer to bottom split |
| `<leader>wl` | Move buffer to right split  |

### Splitting

| Key          | Action                          |
| ------------ | ------------------------------- |
| `<leader>-`  | Split horizontally (below)      |
| `<leader>\|` | Split vertically (right)        |
| `<C-w>s`     | Split horizontal                |
| `<C-w>v`     | Split vertical                  |
| `<C-w>c`     | Close window                    |
| `<C-w>o`     | Only this window (close others) |
| `<C-w>q`     | Quit window                     |

### Resizing

| Key                      | Action              |
| ------------------------ | ------------------- |
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
| ----------------- | --------------------------- |
| `[b` / `]b`       | Prev / Next buffer          |
| `<S-h>` / `<S-l>` | Prev / Next buffer (alt)    |
| `<leader>bb`      | Alternate buffer            |
| `<leader>bd`      | Delete buffer               |
| `<leader>b-`      | New buffer below            |
| `<leader>b\|`     | New buffer right            |
| `<leader>bp`      | Toggle pin                  |
| `<leader>bP`      | Delete non-pinned buffers   |
| `<leader>bo`      | Delete other buffers        |
| `<leader>br`      | Delete buffers to the right |
| `<leader>bl`      | Delete buffers to the left  |

---

## File Explorer (Neo-tree)

| Key         | Action                       |
| ----------- | ---------------------------- |
| `<leader>e` | Explorer (project root)      |
| `<leader>E` | Explorer (current directory) |

### Inside Neo-tree

| Key     | Action                                       |
| ------- | -------------------------------------------- |
| `<CR>`  | Open file / Expand folder (with auto-expand) |
| `o`     | Open file                                    |
| `h`     | Collapse folder / Go to parent               |
| `<bs>`  | Go to parent directory                       |
| `.`     | Set current folder as root                   |
| `s`     | **Open with window picker** (pick split)     |
| `<C-v>` | Open in vertical split                       |
| `<C-x>` | Open in horizontal split                     |
| `<C-t>` | Open in new tab                              |
| `a`     | Add file/folder                              |
| `d`     | Delete                                       |
| `r`     | Rename                                       |
| `c`     | Copy                                         |
| `m`     | Move                                         |
| `H`     | Toggle hidden files                          |

**Tip:** Renaming or moving a Java file via `r` / `m` triggers LSP file operations — JDTLS automatically updates all imports and references
across the project. This may modify many buffers at once. Save them all with `:wall`.

---

## Quick Directory Navigation

| Key          | Action                                    |
| ------------ | ----------------------------------------- |
| `-`          | Open **Oil** (parent dir of current file) |
| `<leader>-`  | Open **Oil** in cwd                       |
| `<leader>fp` | Switch project (Telescope)                |

### Inside Oil (stevearc/oil.nvim)

Oil treats the directory as a buffer — **edit filenames directly and `:w` to apply**.

| Key     | Action                   |
| ------- | ------------------------ |
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
| ------ | ------------------------------------------------------ |
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

| Key       | Action                                          |
| --------- | ----------------------------------------------- |
| `<Tab>`   | Next completion item                            |
| `<S-Tab>` | Previous completion item                        |
| `<C-y>`   | **Confirm selection** (stay in cmdline)         |
| `<C-e>`   | Cancel completion                               |
| `<CR>`    | Confirm and execute (use `<C-y>` to avoid this) |

---

## Telescope (Fuzzy Finder)

| Key               | Action                      |
| ----------------- | --------------------------- |
| `<leader><space>` | Find files                  |
| `<leader>ff`      | Find files                  |
| `<leader>fg`      | Live grep (search in files) |
| `<leader>fb`      | Buffers                     |
| `<leader>fR`      | Recent files                |
| `<leader>Hy`      | Yank history                |
| `<leader>Hc`      | Command history             |
| `<leader>Hs`      | Search history              |
| `<leader>:`       | Command history             |
| `<leader>ss`      | Document symbols            |
| `<leader>sS`      | Workspace symbols           |
| `<leader>st`      | Search TODOs                |
| `<leader>fe`      | Grep by file extension      |
| `<leader>fr`      | Resume last search          |

### Inside Telescope

| Key               | Action                                                       |
| ----------------- | ------------------------------------------------------------ |
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

**Tip:** `<leader>fe` prompts for an extension (e.g. `java`, `go`, `py`) then opens live grep scoped to `*.{ext}` files only.

**Tip:** `<leader>fr` resumes the last Telescope search exactly where you left off — useful for returning to a search after editing a file.

### Workflow: Edit multiple files from a search

Use this when you need to rename variables or make targeted edits across many files one by one:

1. `<leader>ff` or `<leader>fe` — search for files
2. `<Tab>` to select specific files, or skip to send all results
3. `<C-q>` — send to quickfix list
4. `<leader>xQ` — open quickfix as a persistent Trouble sidebar
5. `<CR>` on a file in the sidebar — jump to it and edit
6. `]q` / `[q` — jump to next/prev file without leaving the sidebar
7. Repeat until done, then `<leader>xQ` to close

---

## LSP & Code Navigation

### Go To

| Key  | Action                         |
| ---- | ------------------------------ |
| `gd` | Go to definition (Glance)      |
| `gR` | Go to references (Glance)      |
| `gy` | Go to type definition (Glance) |
| `gI` | Go to implementation (Glance)  |
| `gD` | Go to declaration (native LSP) |

### Documentation

| Key  | Action              |
| ---- | ------------------- |
| `K`  | Hover documentation |
| `gK` | Signature help      |

### Code Actions

| Key          | Action                  |
| ------------ | ----------------------- |
|| `<leader>ca` | Code action             |
|| `<leader>cr` | Rename                  |
|| `<leader>ci` | Organize imports        |
|| `<leader>cp` | Fix package declaration |
|| `<leader>cf` | Format                  |
|| `<leader>cI` | IntelliJ format         |

### Symbols & Outline

| Key          | Action                               |
| ------------ | ------------------------------------ |
| `<leader>co` | Aerial (Symbols outline)             |
| `<leader>cO` | Aerial Nav                           |
| `<leader>cs` | Symbols (Trouble)                    |
| `<leader>cl` | LSP definitions/references (Trouble) |

### LSP Server Management

| Key          | Action      |
| ------------ | ----------- |
| `<leader>lr` | Restart LSP |
| `<leader>li` | LSP info    |
| `<leader>ll` | LSP log     |

### Diagnostics

| Key          | Action                       |
| ------------ | ---------------------------- |
| `[d`         | Prev diagnostic              |
| `]d`         | Next diagnostic              |
| `<leader>xd` | Line diagnostics (float)     |
| `<leader>xl` | Diagnostics to loclist       |
| `<leader>xx` | Diagnostics (Trouble)        |
| `<leader>xX` | Buffer diagnostics (Trouble) |
| `<leader>xL` | Location list (Trouble)      |
| `<leader>xQ` | Quickfix list (Trouble)      |

### Todos

| Key          | Action                   |
| ------------ | ------------------------ |
| `]t`         | Next TODO comment        |
| `[t`         | Previous TODO comment    |
| `<leader>xt` | TODOs (Trouble)          |
| `<leader>xT` | TODO/FIX/FIXME (Trouble) |

---

## Debugging (DAP)

| Key          | Action                     |
| ------------ | -------------------------- |
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

| Key          | Action              |
| ------------ | ------------------- |
| `<leader>tt` | Run file            |
| `<leader>tT` | Run all test files  |
| `<leader>tr` | Run nearest test    |
| `<leader>tl` | Run last            |
| `<leader>ts` | Toggle summary      |
| `<leader>to` | Show output         |
| `<leader>tO` | Toggle output panel |
| `<leader>tS` | Stop (interactive)  |
| `<leader>tw` | Toggle watch        |

### Java-specific

| Key          | Action                                |
| ------------ | ------------------------------------- |
| `<leader>jr` | Run Main                              |
| `<leader>jc` | Stop Main                             |
| `<leader>jt` | Test Current Class                    |
| `<leader>jm` | Test Current Method                   |
| `<leader>jv` | View Test Report                      |
| `<leader>ci` | Organize imports (silent, auto-apply) |

### Java Refactor (`<leader>jR`)

jdtls code actions — open actions-preview picker with diff before applying.

| Key           | Action              |
| ------------- | ------------------- |
| `<leader>jRe` | Extract function    |
| `<leader>jRv` | Extract variable    |
| `<leader>jRc` | Extract constant    |
| `<leader>jRf` | Extract field       |
| `<leader>jRi` | Extract interface   |
| `<leader>jRp` | Introduce parameter |
| `<leader>jRs` | Change signature    |
| `<leader>jRm` | Move                |
| `<leader>jRa` | Assign variable     |
| `<leader>jRq` | Quick assist        |

### Java Generate (`<leader>jg`)

| Key           | Action              |
| ------------- | ------------------- |
| `<leader>jga` | Accessors (get/set) |
| `<leader>jgc` | Constructors        |
| `<leader>jgd` | Delegate methods    |
| `<leader>jgf` | Final modifiers     |
| `<leader>jgh` | hashCode / equals   |
| `<leader>jgt` | toString            |
| `<leader>jgo` | Override methods    |
| `<leader>jgs` | Sort members        |

---

### Java Debugging

**How Java debugging works:** `nvim-java` orchestrates `jdtls` → `java-debug-adapter` → `nvim-dap`. When you start debugging, JDTLS compiles the project, starts a debug server on a port, and nvim-dap connects to it.

#### Starting Debug Sessions

| Command | Action |
|---------|--------|
| `:JavaTestDebugCurrentMethod` | Debug test method under cursor |
| `:JavaTestDebugCurrentClass` | Debug entire test class |
| `:JavaTestDebugAllTests` | Debug all tests in workspace |
| `:JavaDebugCurrentFile` | Debug main class/Spring Boot app |

**Via Lua API** (if you want custom keybindings):
```lua
require('java').test.debug_current_method()    -- Debug method
require('java').test.debug_current_class()     -- Debug class
require('java').debug.debug_current_file()     -- Debug main
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

| Issue | Fix |
|-------|-----|
| "No debug session found" | Run `:JavaInfo` or `:LspInfo` — ensure JDTLS is attached |
| "Failed to start" | Wait for JDTLS to load, or `:Lazy java` to reload |
| "Port already in use" | Stale session — close nvim or `killall java` |
| Breakpoints not hitting | Check `:LspInfo` for compilation errors, or check logs: `tail -f ~/.local/state/nvim/nvim-java.log` |

**See also:** `~/.config/nvim/JAVA_DEBUGGING.md` for complete reference.

---

## Git Integration

### LazyGit

| Key          | Action       |
| ------------ | ------------ |
| `<leader>Gg` | Open LazyGit |

**Inside LazyGit window:**

| Key     | Action                            |
| ------- | --------------------------------- |
| `<esc>` | Back / Cancel                     |
| `q`     | Quit lazygit                      |
| `<C-q>` | Exit terminal mode (back to nvim) |

### Diffview

| Key          | Action                   |
| ------------ | ------------------------ |
| `<leader>GD` | Repo diff (DiffviewOpen) |
| `<leader>GF` | File history             |
| `<leader>GH` | Repo history             |
| `<leader>GL` | Line history (normal)    |
| `<leader>GL` | Range history (visual)   |
| `<leader>Gm` | Diff vs main/master      |
| `<leader>GM` | Diff vs origin/main      |

**Inside Diffview:**

| Key          | Action                   |
| ------------ | ------------------------ |
| `q`          | Close panel / quit       |
| `<tab>`      | Next changed file        |
| `<S-tab>`    | Prev changed file        |
| `[x` / `]x`  | Prev / Next conflict     |
| `<leader>co` | Choose ours (conflict)   |
| `<leader>ct` | Choose theirs (conflict) |
| `<leader>cb` | Choose base (conflict)   |
| `<leader>ca` | Choose all (conflict)    |
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

**Step 4 — Navigate conflicts**

| Key   | Action               |
| ----- | -------------------- |
| `]x`  | Jump to next conflict |
| `[x`  | Jump to prev conflict |

**Step 5 — Resolve each conflict**

For simple conflicts (pick one side or both):

| Key  | Action                                    |
| ---- | ----------------------------------------- |
| `co` | Keep **ours** (current branch, HEAD)      |
| `ct` | Keep **theirs** (incoming branch)         |
| `cb` | Keep **both** (ours first, theirs second) |
| `c0` | Keep **neither** (delete both sides)      |

After pressing one of these, the markers disappear and the chosen content stays. Move to the next conflict with `]x` and repeat.

For complex conflicts (you need to hand-edit the result):
- Delete the marker lines manually (`<<<<<<< HEAD`, `=======`, `>>>>>>> ...`)
- Edit the remaining code however you need
- Save with `<C-s>`

**Step 6 — Need more context? Use Diffview 3-way view**

If a conflict is hard to understand from the inline markers alone, open the full 3-way merge view:

```
:DiffviewOpen
```

This shows 4 panels: **OURS** (left) | **BASE** (middle, common ancestor) | **THEIRS** (right) | **RESULT** (bottom).

| Key          | Action in Diffview merge view          |
| ------------ | -------------------------------------- |
| `]x` / `[x`  | Next / prev conflict                   |
| `<leader>co` | Accept ours into result                |
| `<leader>ct` | Accept theirs into result              |
| `<leader>cb` | Accept base into result                |
| `<leader>ca` | Accept all from one side               |
| `dx`         | Delete conflict region                 |
| `q`          | Close panel                            |

When done: `:DiffviewClose`

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
co / ct / cb / c0          →  resolve inline (ours/theirs/both/none)
:DiffviewOpen              →  3-way view for complex cases
stage file in lazygit      →  <space>
git commit                 →  finalize merge
```

### Gitsigns (in-buffer)

| Key           | Action            |
| ------------- | ----------------- |
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
| ------------ | ----------------------------------- |
| `p` / `P`    | Paste after / before (yanky-aware)  |
| `<C-p>`      | Cycle forward through yank history  |
| `<C-n>`      | Cycle backward through yank history |
| `<leader>Hy` | Open yank history picker            |

**Tip:** paste with `p`, then keep pressing `<C-p>` to replace the pasted text with earlier yanks.

---

## Harpoon (Quick File Switching)

| Key          | Action              |
| ------------ | ------------------- |
| `<leader>ha` | Add file to harpoon |
| `<leader>hh` | Open harpoon menu   |
| `<leader>h1` | Go to file 1        |
| `<leader>h2` | Go to file 2        |
| `<leader>h3` | Go to file 3        |
| `<leader>h4` | Go to file 4        |

---

## Marks

| Key         | Action                     |
| ----------- | -------------------------- |
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

| Key          | Action                                                      |
| ------------ | ----------------------------------------------------------- |
| `<leader>us` | Toggle spell                                                |
| `<leader>uw` | Toggle wrap                                                 |
| `<leader>ul` | Toggle relative numbers                                     |
| `<leader>un` | Toggle line numbers                                         |
| `<leader>uf` | Toggle fold                                                 |
| `<leader>ud` | Toggle diagnostic virtual lines                             |
| `<leader>uD` | Toggle diagnostic messages (hide all msgs, keep underlines) |
| `<leader>uh` | Toggle inlay hints                                          |
| `<leader>ut` | Color schemes                                               |
| `<leader>un` | Dismiss notifications                                       |

---

## Tabs

| Key                  | Action    |
| -------------------- | --------- |
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
| ------- | ------------------------------------- |
| `<A-a>` | Open / show terminal                  |
| `<A-c>` | Hide terminal (process keeps running) |

### Inside terminal buffer

| Key          | Action                   |
| ------------ | ------------------------ |
| `<Esc>`      | Exit terminal mode       |
| `<C-\><C-n>` | Exit terminal mode (alt) |

**Note:** Terminal window navigation:

| Key     | Action             |
| ------- | ------------------ |
| `<C-h>` | Go to left window  |
| `<C-j>` | Go to lower window |
| `<C-k>` | Go to upper window |
| `<C-l>` | Go to right window |

---

## Go Development

### Running Go Programs

| Command                | Action                     |
| ---------------------- | -------------------------- |
| `:term go run .`       | Run program in current dir |
| `:term go run main.go` | Run specific file          |
| `<leader>gr`           | Go run (keymap)            |
| `<leader>gR`           | Go run current file        |
| `<leader>gb`           | Go build                   |
| `<leader>gt`           | Go test all                |

### Go Struct Tags (Gopher.nvim)

| Key           | Action               |
| ------------- | -------------------- |
| `<leader>gsj` | Add JSON struct tags |
| `<leader>gsy` | Add YAML struct tags |
| `<leader>gsd` | Add DB struct tags   |
| `<leader>gie` | Add `if err != nil`  |

### Go Debugging

| Key           | Action             |
| ------------- | ------------------ |
| `<leader>dgt` | Debug Go test      |
| `<leader>dgl` | Debug last Go test |

---

## Miscellaneous

| Key          | Action                 |
| ------------ | ---------------------- |
| `<leader>fn` | New file               |
| `<leader>U`  | Undotree toggle        |
| `<leader>pl` | Open Lazy              |
| `Q`          | Record macro to q      |
| `q`          | Play macro q           |
| `<leader>xh` | Rehighlight treesitter |
| `<leader>xc` | Clear JDTLS cache      |

---

## Which-Key Groups

Press `<leader>` and wait to see all groups:

| Prefix          | Group                |
| --------------- | -------------------- |
| `<leader>b`     | Buffer               |
| `<leader>c`     | Code                 |
| `<leader>co`    | Outline              |
| `<leader>d`     | Debug                |
| `<leader>dg`    | Debug Go             |
| `<leader>f`     | File/Find            |
| `<leader>g`     | Go                   |
| `<leader>gi`    | Go Insert            |
| `<leader>gs`    | Go Struct Tags       |
| `<leader>G`     | Git                  |
| `<leader>Gh`    | Hunks                |
| `<leader>h`     | Harpoon              |
| `<leader>l`     | LSP                  |
| `<leader>j`     | Java                 |
| `<leader>o`     | Obsidian             |
| `<leader>p`     | Plugins              |
| `<leader>q`     | Quit/Session         |
| `<leader>r`     | Replace              |
| `<leader>s`     | Search               |
| `<leader>S`     | Sessions             |
| `<leader>t`     | Test/Theme           |
| `<leader>u`     | UI                   |
| `<leader>w`     | Windows              |
| `<leader>x`     | Diagnostics/Quickfix |
| `<leader><tab>` | Tabs                 |
| `[`             | Previous             |
| `]`             | Next                 |
| `g`             | Goto/Misc            |
| `gc`            | Comment              |
| `gs`            | Surround             |
| `z`             | Fold                 |

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

| Key          | Action           |
| ------------ | ---------------- |
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
| ------ | ------------------------------------------ |
| `<CR>` | Follow `[[wikilink]]` or `[text](#anchor)` |

### Note Management

| Key          | Action                                 |
| ------------ | -------------------------------------- |
| `<leader>of` | Quick switch between notes (Telescope) |
| `<leader>os` | Full-text search across vault          |
| `<leader>on` | New note                               |
| `<leader>or` | Rename note (updates all links)        |
| `<leader>oo` | Open current note in Obsidian app      |

### Links & Tags

| Key          | Action                    |
| ------------ | ------------------------- |
| `<leader>ob` | Backlinks to current note |
| `<leader>ol` | All links in current note |
| `<leader>ot` | Browse tags               |

### Other

| Key          | Action                     |
| ------------ | -------------------------- |
| `<leader>oc` | Toggle `- [ ]` checkbox    |
| `<leader>od` | Daily notes                |
| `<leader>op` | Paste image from clipboard |

---

_Generated for your Neovim setup_
