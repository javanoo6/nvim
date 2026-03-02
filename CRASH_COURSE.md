# 🚀 Neovim Crash Course

nvim setup reference guide.

---

## 📋 Table of Contents

1. [Vim Basics](#vim-basics)
2. [Movement & Navigation](#movement--navigation)
3. [Editing & Text Objects](#editing--text-objects)
4. [Search & Replace](#search--replace)
5. [Window Management](#window-management)
6. [Buffer Management](#buffer-management)
7. [File Explorer](#file-explorer)
8. [LSP & Code Navigation](#lsp--code-navigation)
9. [Debugging](#debugging)
10. [Testing](#testing)
11. [Git Integration](#git-integration)
12. [UI & Toggles](#ui--toggles)
13. [Telescope (Fuzzy Finder)](#telescope-fuzzy-finder)
14. [Harpoon (Quick File Switching)](#harpoon-quick-file-switching)
15. [Marks](#marks)
16. [Terminal Mode](#terminal-mode)
17. [Go Development](#go-development)
18. [Miscellaneous](#miscellaneous)

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
| `^`             | First non-blank character             |
| `$`             | End of line                           |
| `gg`            | First line of file                    |
| `G`             | Last line of file                     |
| `:{n}`          | Go to line n                          |
| `H`             | Top of screen                         |
| `M`             | Middle of screen                      |
| `L`             | Bottom of screen                      |

### Scrolling (Centered)

| Key     | Action                           |
|---------|----------------------------------|
| `<C-d>` | Scroll down half page (centered) |
| `<C-u>` | Scroll up half page (centered)   |
| `<C-f>` | Scroll down full page            |
| `<C-b>` | Scroll up full page              |
| `zz`    | Center cursor on screen          |

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

| Key       | Action                         |
|-----------|--------------------------------|
| `<cr>`    | Initialize/Increment selection |
| `<S-tab>` | Increment scope                |
| `<bs>`    | Decrement selection            |

### Moving Lines

| Key                                     | Action         |
|-----------------------------------------|----------------|
| `<A-j>`                                 | Move line up   |
| `<A-k>`                                 | Move line down |
| (Works in normal, insert, visual modes) |

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

### Replace

| Key              | Action                                  |
|------------------|-----------------------------------------|
| `:s/old/new/`    | Replace first occurrence in line        |
| `:s/old/new/g`   | Replace all in line                     |
| `:%s/old/new/g`  | Replace all in file                     |
| `:%s/old/new/gc` | Replace all with confirmation           |
| `<leader>rw`     | Replace word under cursor (interactive) |

---

## Window Management

### Navigation

| Key     | Action             |
|---------|--------------------|
| `<C-h>` | Go to left window  |
| `<C-j>` | Go to down window  |
| `<C-k>` | Go to up window    |
| `<C-l>` | Go to right window |

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

| Key | Action |
| ------------------------ | ------------------- | -------------- |
| `<C-Up>`                 | Increase height |
| `<C-Down>`               | Decrease height |
| `<C-Left>`               | Decrease width |
| `<C-Right>`              | Increase width |
| `<M-Up>` / `<M-Down>`    | Resize height (alt) |
| `<M-Left>` / `<M-Right>` | Resize width (alt)  |
| `<C-w>=`                 | Equalize windows |
| `<C-w>_`                 | Maximize height |
| `<C-w>                   | `                   | Maximize width |

---

## Buffer Management

| Key               | Action                      |
|-------------------|-----------------------------|
| `[b` / `]b`       | Prev / Next buffer          |
| `<S-h>` / `<S-l>` | Prev / Next buffer (alt)    |
| `<leader>bb`      | Alternate buffer            |
| `<leader>bd`      | Delete buffer               |
| `<leader>bp`      | Toggle pin                  |
| `<leader>bP`      | Delete non-pinned buffers   |
| `<leader>bo`      | Delete other buffers        |
| `<leader>br`      | Delete buffers to the right |
| `<leader>bl`      | Delete buffers to the left  |

---

## File Explorer (Neo-tree)

| Key         | Action                       |
|-------------|------------------------------|
| `<leader>e` | Explorer (project root)      |
| `<leader>E` | Explorer (current directory) |

### Inside Neo-tree

| Key     | Action                                       |
|---------|----------------------------------------------|
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

---

## Quick Directory Navigation

| Key          | Action                                  |
|--------------|-----------------------------------------|
| `-`          | Open **Oil** (edit directory like text) |
| `<leader>-`  | Open **Oil** in cwd                     |
| `<leader>fp` | Switch project (Telescope)              |

### Inside Oil

| Key    | Action                 |
|--------|------------------------|
| `<CR>` | Open file / Enter dir  |
| `-`    | Go to parent directory |
| `q`    | Close Oil              |

---

## Command Line (Cmdline) Completion

When typing commands with `:` and autocomplete menu appears:

| Key       | Action                                          |
|-----------|-------------------------------------------------|
| `<Tab>`   | Next completion item                            |
| `<S-Tab>` | Previous completion item                        |
| `<C-y>`   | **Confirm selection** (stay in cmdline)         |
| `<C-e>`   | Cancel completion                               |
| `<CR>`    | Confirm and execute (use `<C-y>` to avoid this) |

---

## Telescope (Fuzzy Finder)

| Key               | Action                      |
|-------------------|-----------------------------|
| `<leader><space>` | Find files                  |
| `<leader>ff`      | Find files                  |
| `<leader>fg`      | Live grep (search in files) |
| `<leader>fb`      | Buffers                     |
| `<leader>fr`      | Recent files                |
| `<leader>fh`      | Help tags                   |
| `<leader>:`       | Command history             |
| `<leader>ss`      | Document symbols            |
| `<leader>sS`      | Workspace symbols           |
| `<leader>r`       | Registers (paste history)   |
| `<leader>st`      | Search TODOs                |

### Inside Telescope

| Key               | Action                     |
|-------------------|----------------------------|
| `<C-j>` / `<C-k>` | Next / Previous            |
| `<C-n>` / `<C-p>` | Next / Previous in history |
| `<CR>`            | Open                       |
| `<C-x>`           | Open in horizontal split   |
| `<C-v>`           | Open in vertical split     |
| `<C-t>`           | Open in tab                |
| `<Esc>`           | Close                      |

---

## LSP & Code Navigation

### Go To

| Key  | Action                         |
|------|--------------------------------|
| `gd` | Go to definition (Glance)      |
| `gr` | Go to references (Glance)      |
| `gy` | Go to type definition (Glance) |
| `gI` | Go to implementation (Glance)  |
| `gD` | Go to declaration (native LSP) |

### Documentation

| Key  | Action              |
|------|---------------------|
| `K`  | Hover documentation |
| `gK` | Signature help      |

### Code Actions

| Key          | Action                  |
|--------------|-------------------------|
| `<leader>ca` | Code action             |
| `<leader>cr` | Rename                  |
| `<leader>ci` | Organize imports        |
| `<leader>cp` | Fix package declaration |
| `<leader>cf` | Format                  |

### Symbols & Outline

| Key          | Action                               |
|--------------|--------------------------------------|
| `<leader>co` | Aerial (Symbols outline)             |
| `<leader>cO` | Aerial Nav                           |
| `<leader>cs` | Symbols (Trouble)                    |
| `<leader>cl` | LSP definitions/references (Trouble) |

### Diagnostics

| Key          | Action                       |
|--------------|------------------------------|
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
|--------------|--------------------------|
| `]t`         | Next TODO comment        |
| `[t`         | Previous TODO comment    |
| `<leader>xt` | TODOs (Trouble)          |
| `<leader>xT` | TODO/FIX/FIXME (Trouble) |

---

## Debugging (DAP)

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

| Key          | Action              |
|--------------|---------------------|
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
|--------------|---------------------|
| `<leader>jr` | Run Main            |
| `<leader>jc` | Stop Main           |
| `<leader>jt` | Test Current Class  |
| `<leader>jm` | Test Current Method |
| `<leader>jv` | View Test Report    |

---

## Git Integration

### LazyGit

| Key          | Action       |
|--------------|--------------|
| `<leader>gg` | Open LazyGit |

**Inside LazyGit window:**
| Key | Action |
|-----|--------|
| `<esc>` | Back / Cancel (works now!) |
| `q` | Quit lazygit |
| `<C-q>` | Exit terminal mode (back to nvim) |

### Merge Conflict Resolution

When lazygit shows conflicted files, press `e` to open the file in nvim.

**Conflict marker anatomy:**

```
<<<<<<< HEAD
your changes (current branch)
=======
their changes (incoming branch)
>>>>>>> feature-branch
```

**Navigate between conflicts:**

| Key       | Action                       |
|-----------|------------------------------|
| `/<<<`    | Jump to next conflict marker |
| `n` / `N` | Next / Prev match            |

**Resolve a conflict (place cursor anywhere inside it):**

| Goal            | What to do                                                           |
|-----------------|----------------------------------------------------------------------|
| Keep **ours**   | Delete the `=======` → `>>>>>>> ...` block + the `<<<<<<< HEAD` line |
| Keep **theirs** | Delete the `<<<<<<< HEAD` → `=======` block + the `>>>>>>> ...` line |
| Keep **both**   | Delete only the three marker lines (`<<<<<<<`, `=======`, `>>>>>>>`) |

**Practical workflow:**

1. In lazygit — conflicts show as `AA` (both modified) in the Files panel
2. Press `e` on a conflicted file → opens in nvim
3. Search `/<<<` to find each conflict, resolve manually, repeat
4. Save with `<C-s>` and close the buffer
5. Back in lazygit — stage the file (`<space>`) → conflict is marked resolved
6. Continue with commit (`c`) when all conflicts are resolved

**Tip:** Use `:%s/<<<<<<< HEAD\n.*\n=======\n//g` carefully for bulk keep-theirs — but manual is safer.

### Gitsigns (in-buffer)

| Key           | Action            |
|---------------|-------------------|
| `]h`          | Next hunk         |
| `[h`          | Prev hunk         |
| `<leader>ghs` | Stage hunk        |
| `<leader>ghr` | Reset hunk        |
| `<leader>ghS` | Stage buffer      |
| `<leader>ghu` | Undo stage hunk   |
| `<leader>ghR` | Reset buffer      |
| `<leader>ghp` | Preview hunk      |
| `<leader>ghb` | Blame line (full) |
| `<leader>ghd` | Diff this         |

---

## Harpoon (Quick File Switching)

| Key          | Action              |
|--------------|---------------------|
| `<leader>ha` | Add file to harpoon |
| `<leader>hh` | Open harpoon menu   |
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

| Key          | Action                  |
|--------------|-------------------------|
| `<leader>us` | Toggle spell            |
| `<leader>uw` | Toggle wrap             |
| `<leader>ul` | Toggle relative numbers |
| `<leader>un` | Toggle line numbers     |
| `<leader>uf` | Toggle fold             |
| `<leader>tc` | Color schemes           |
| `<leader>un` | Dismiss notifications   |

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

## Miscellaneous

| Key          | Action                 |
|--------------|------------------------|
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
|-----------------|----------------------|
| `<leader>b`     | Buffer               |
| `<leader>c`     | Code                 |
| `<leader>d`     | Debug                |
| `<leader>f`     | File/Find            |
| `<leader>g`     | Git                  |
| `<leader>h`     | Harpoon              |
| `<leader>j`     | Java                 |
| `<leader>q`     | Quit/Session         |
| `<leader>s`     | Search               |
| `<leader>t`     | Test/Theme           |
| `<leader>u`     | UI                   |
| `<leader>w`     | Windows              |
| `<leader>x`     | Diagnostics/Quickfix |
| `<leader><tab>` | Tabs                 |
| `[`             | Previous             |
| `]`             | Next                 |
| `g`             | Go to                |
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

_Generated for your Neovim setup_
