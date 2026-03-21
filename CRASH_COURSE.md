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

| Key     | Action                           |
| ------- | -------------------------------- |
| `<C-d>` | Scroll down half page (centered) |
| `<C-u>` | Scroll up half page (centered)   |
| `<C-f>` | Scroll down full page            |
| `<C-b>` | Scroll up full page              |
| `zz`    | Center cursor on screen          |

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

| Key          | Mode   | Action                              |
| ------------ | ------ | ----------------------------------- |
| `<leader>rg` | normal | Open search & replace panel (blank) |
| `<leader>rw` | normal | Open with word under cursor         |
| `<leader>rg` | visual | Open with selection as search term  |

**Tip:** Inside grug-far you can scope to specific paths/globs, preview all matches before replacing, and undo all replacements at once.

### Replace (within visual selection)

| Key          | Mode   | Action                                       |
| ------------ | ------ | -------------------------------------------- |
| `<leader>rw` | visual | `:s/\%V` — replace only within selected text |

**Tip:** After `<leader>rw` in visual mode, type your pattern and replacement: `old/new/g` then `<CR>`.

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

| Key          | Action                                  |
| ------------ | --------------------------------------- |
| `-`          | Open **Oil** (edit directory like text) |
| `<leader>-`  | Open **Oil** in cwd                     |
| `<leader>fp` | Switch project (Telescope)              |

### Inside Oil

| Key    | Action                 |
| ------ | ---------------------- |
| `<CR>` | Open file / Enter dir  |
| `-`    | Go to parent directory |
| `q`    | Close Oil              |

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
| `<leader>fh`      | Yank history                |
| `<leader>fH`      | Command history             |
| `<leader>fS`      | Search history              |
| `<leader>:`       | Command history             |
| `<leader>ss`      | Document symbols            |
| `<leader>sS`      | Workspace symbols           |
| `<leader>st`      | Search TODOs                |
| `<leader>fe`      | Grep by file extension      |
| `<leader>fr`      | Resume last search          |

### Inside Telescope

| Key               | Action                                  |
| ----------------- | --------------------------------------- |
| `<C-j>` / `<C-k>` | Next / Previous                         |
| `<C-n>` / `<C-p>` | Next / Previous in history              |
| `<C-d>` / `<C-u>` | Scroll preview down / up                |
| `<CR>`            | Open                                    |
| `<C-x>`           | Open in horizontal split                |
| `<C-v>`           | Open in vertical split                  |
| `<C-t>`           | Open in tab                             |
| `<Tab>`           | Multi-select entry                      |
| `<C-q>`           | Send selected (or all) to quickfix list |
| `<Esc>`           | Close                                   |

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
| `<leader>ca` | Code action             |
| `<leader>cr` | Rename                  |
| `<leader>ci` | Organize imports        |
| `<leader>cp` | Fix package declaration |
| `<leader>cf` | Format                  |

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
| `<leader>tS` | Stop                |
| `<leader>tw` | Toggle watch        |

### Java-specific

| Key          | Action              |
| ------------ | ------------------- |
| `<leader>jr` | Run Main            |
| `<leader>jc` | Stop Main           |
| `<leader>jt` | Test Current Class  |
| `<leader>jm` | Test Current Method |
| `<leader>jv` | View Test Report    |

---

## Git Integration

### LazyGit

| Key          | Action       |
| ------------ | ------------ |
| `<leader>gg` | Open LazyGit |

**Inside LazyGit window:**

| Key     | Action                            |
| ------- | --------------------------------- |
| `<esc>` | Back / Cancel                     |
| `q`     | Quit lazygit                      |
| `<C-q>` | Exit terminal mode (back to nvim) |

### Diffview

| Key          | Action                   |
| ------------ | ------------------------ |
| `<leader>gD` | Repo diff (DiffviewOpen) |
| `<leader>gF` | File history             |
| `<leader>gH` | Repo history             |
| `<leader>gL` | Line history (normal)    |
| `<leader>gL` | Range history (visual)   |
| `<leader>gm` | Diff vs main/master      |
| `<leader>gM` | Diff vs origin/main      |

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

### Merge Conflict Resolution (with Diffview)

1. In lazygit — conflicts show as `AA` in Files panel
2. Press `e` on conflicted file → opens in nvim
3. Run `:DiffviewOpen` → 3-way merge view opens
4. Use `[x` / `]x` to navigate between conflicts
5. Use `<leader>co/ct/cb` to pick ours/theirs/base, or edit manually
6. Save with `<C-s>`, then `:DiffviewClose`
7. Back in lazygit — stage the file (`<space>`) → commit (`c`)

**Manual resolution (without Diffview):**

Conflict marker anatomy:

```
<<<<<<< HEAD
your changes (current branch)
=======
their changes (incoming branch)
>>>>>>> feature-branch
```

| Goal            | What to do                                                           |
| --------------- | -------------------------------------------------------------------- |
| Keep **ours**   | Delete the `=======` → `>>>>>>> ...` block + the `<<<<<<< HEAD` line |
| Keep **theirs** | Delete the `<<<<<<< HEAD` → `=======` block + the `>>>>>>> ...` line |
| Keep **both**   | Delete only the three marker lines (`<<<<<<<`, `=======`, `>>>>>>>`) |

### Gitsigns (in-buffer)

| Key           | Action            |
| ------------- | ----------------- |
| `]h` / `[h`   | Next / Prev hunk  |
| `<leader>ghs` | Stage hunk        |
| `<leader>ghr` | Reset hunk        |
| `<leader>ghS` | Stage buffer      |
| `<leader>ghR` | Reset buffer      |
| `<leader>ghu` | Undo stage hunk   |
| `<leader>ghp` | Preview hunk      |
| `<leader>ghb` | Blame line (full) |
| `<leader>ghB` | Toggle blame      |
| `<leader>ghd` | Diff this         |
| `<leader>ghw` | Toggle word diff  |
| `<leader>ghl` | Toggle line hl    |
| `<leader>ghv` | Toggle deleted    |
| `ih`          | Text object: hunk |

---

## Yank History (Yanky)

| Key          | Action                              |
| ------------ | ----------------------------------- |
| `p` / `P`    | Paste after / before (yanky-aware)  |
| `<C-p>`      | Cycle forward through yank history  |
| `<C-n>`      | Cycle backward through yank history |
| `<leader>fh` | Open yank history picker            |

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
| `<leader>tc` | Color schemes                                               |
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
| `<leader>g`     | Git                  |
| `<leader>gh`    | Hunks                |
| `<leader>gi`    | Go Insert            |
| `<leader>gs`    | Go Struct Tags       |
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

| Key          | Action           |
| ------------ | ---------------- |
| `<leader>Ss` | Save session     |
| `<leader>Sr` | Restore session  |
| `<leader>Sd` | Delete session   |
| `<leader>Sf` | Find sessions    |
| `<leader>Sa` | Toggle auto-save |

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
