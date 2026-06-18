# Neovim Config — Plugin Map

> **Purpose:** Complete reference of every plugin and how pieces relate to each other.

---

## Boot sequence

```
init.lua
├── config/options.lua   — vim.opt settings, leader key, sessionoptions
├── config/lazy.lua      — lazy.nvim bootstrap + loads lua/plugins/**
├── config/keymaps.lua   — global keymaps + Treesitter text-object maps
└── config/autocmds.lua  — highlight-on-yank, resize, close-with-q, etc.

lua/util/init.lua        — shared helpers (map, augroup, toggle, get_root,
                           format, M.icons) used by keymaps + plugins
```

---

## Plugin categories

### 1. Infrastructure (shared deps, always loaded)

| Plugin                        | Role                               | File                   |
|-------------------------------|------------------------------------|------------------------|
| `folke/lazy.nvim`             | Plugin manager                     | config/lazy.lua        |
| `nvim-lua/plenary.nvim`       | Lua utilities (async, path, …)     | dep of many            |
| `MunifTanjim/nui.nvim`        | UI component library               | dep of neo-tree, noice |
| `nvim-tree/nvim-web-devicons` | File-type icons                    | dep of many            |
| `nvim-neotest/nvim-nio`       | Async I/O (dep of dap-ui, neotest) | dep                    |

---

### 2. LSP Stack

```
mason.nvim  ─────────────────────────────────────── package manager
  └── mason-lspconfig.nvim  ── bridges mason ↔ lspconfig
  └── mason-tool-installer.nvim  ── auto-installs: stylua, selene, gopls,
                                    gofumpt, goimports-reviser, golines,
                                    golangci-lint, ruff, prettier, shellcheck,
                                    markdownlint-cli2, yamllint, delve, LSP servers

nvim-lspconfig  ─────────────────────────────────── LSP config (lsp.lua)
  ├── cmp-nvim-lsp            ── exposes LSP completions to cmp
  ├── nvim-lsp-file-operations ── rename file → updates LSP imports
  │     └── neo-tree.nvim     ── (tree triggers file ops)
  ├── fidget.nvim             ── LSP progress spinner (bottom-right)
  ├── Glance (glance.lua)     ── preview pane for gd / gR / gy / gI
  ├── actions-preview.nvim    ── code action picker; shows diff previews for edit-backed actions (<leader>ca, <A-CR>)
  └── tiny-inline-diagnostic.nvim  ── inline diagnostics with wrapping (<leader>ud toggle)
```

Pyright note:

- `pyright` is configured through `vim.lsp.config("pyright", ...)` with a
  resolved Mason absolute binary path.
- `basedpyright` is configured but not enabled by default. Use
  `:PythonLspUseBasedPyright` to switch the current session to BasedPyright, or
  `:PythonLspUsePyright` to switch back.
- `mason-lspconfig` automatic-enable excludes `pyright` and `basedpyright` so
  repo-local command/switching policy is not bypassed.
- `:PyrightInfo` prints the exact command path for the current session.

**LSP servers auto-installed:** `lua_ls`, `bashls`, `helm_ls`, `jsonls`, `yamlls`, `gopls`, `pyright`, `basedpyright`
**Java LSP:** handled separately by `nvim-java` (jdtls) — see Java section.

**Key LSP keymaps** (set on LspAttach in lsp.lua):

| Key                     | Action                      |
|-------------------------|-----------------------------|
| `gd`                    | Glance definitions          |
| `gR`                    | Glance references           |
| `gy`                    | Glance type definitions     |
| `gI`                    | Glance implementations      |
| `gD`                    | Native declaration          |
| `K`                     | Hover                       |
| `gK`                    | Signature help              |
| `<leader>ca` / `<A-CR>` | Code action                 |
| `<leader>cr`            | Rename                      |
| `<leader>uh`            | Toggle inlay hints          |
| `<leader>uu`            | Toggle reference underline  |
| `<leader>uH`            | Toggle reference background |
| `<leader>lr/li/ll`      | Restart / Info / Log        |
| `<leader>cd`            | Goto definition in vsplit   |

---

### 3. Completion

```
nvim-cmp  (completion.lua)
  ├── LuaSnip                        ── snippet engine
  │     └── friendly-snippets        ── VSCode-style snippet library
  │     └── custom language snippets ── IntelliJ-style `main` snippets for
  │                                     Java, Go, and Python
  ├── cmp_luasnip                    ── LuaSnip → cmp source
  ├── cmp-nvim-lsp                   ── LSP → cmp source
  ├── cmp-nvim-lsp-signature-help    ── signature help source
  ├── cmp-buffer                     ── buffer words source
  ├── cmp-path                       ── filesystem paths source
  ├── cmp-cmdline                    ── cmdline completion (/ ? :)
  └── lspkind.nvim                   ── icons in popup (symbol_text mode)

nvim-autopairs  (coding.lua)
  └── nvim-cmp                       ── integrates: auto-closes pairs on confirm
```

Filetype source policy:

- Markdown/text/gitcommit: path + snippets first, then buffer words.
- Shell/YAML: LSP + path + snippets first, then buffer words.
- Python: LSP + signature help + snippets + path first, then buffer words.
- `cmp-buffer` ignores buffers larger than 512 KiB and starts at 4 characters.

**Completion keymaps:**

| Key                 | Action                    |
|---------------------|---------------------------|
| `<C-n>` / `<C-p>`   | Next / prev item          |
| `<Tab>` / `<S-Tab>` | Next item or jump snippet |
| `<CR>`              | Confirm                   |
| `<C-Space>`         | Trigger completion        |
| `<C-e>`             | Abort                     |
| `<C-b>` / `<C-f>`   | Scroll docs               |

**Custom snippet triggers:**

| Filetype | Trigger | Expansion                                                          |
|----------|---------|--------------------------------------------------------------------|
| `java`   | `main`  | `class Scratch { public static void main(String[] args) { ... } }` |
| `go`     | `main`  | `func main() { ... }`                                              |
| `python` | `main`  | `if __name__ == "__main__": main()`                                |

---

### 4. Treesitter

```
nvim-treesitter  (treesitter.lua)  — highlight, indent, incremental selection
  ├── nvim-treesitter-textobjects  — af/if (function), ac/ic (class),
  │                                  aa/ia (param), al/il (loop), ai/ii (cond)
  │                                  Keymaps live in config/keymaps.lua
  │                                  Markdown/YAML keep stock indentexpr
  └── rainbow-delimiters.nvim      — colorized bracket pairs

nvim-treehopper  (motion.lua)
  └── nvim-treesitter              — `m` in v/o to pick treesitter node
```

**Installed grammars:** bash, c, css, go, gomod, gowork, gotmpl, helm, html, java, javascript, json, lua, markdown, markdown_inline, python, query, sql, toml,
tsx, typescript, vim, vimdoc, yaml, xml, groovy, kotlin

**Incremental selection:** `<CR>` or `<A-o>` starts from normal mode; `<CR>`, `<Tab>`, or `<A-o>` expands in visual mode; `<S-Tab>` or `<A-i>` shrinks; `<BS>`
moves to the next sibling node.

---

### 5. Formatting & Linting

```
conform.nvim  (formatting.lua)
  — format on save (BufWritePre), also <leader>cf
  — <leader>cF formats the current buffer's directory recursively; if no file-backed buffer exists, it prompts for a directory
  — :FormatterInfo reports formatter executable/jar availability
  — directory formatting implementation lives in util/format_dir.lua and uses fd/fdfind with explicit skip patterns
  — auto-formatting enabled by default (disable with :FormatDisable)
  — format-on-save warns once per unchanged error state when skipped due to LSP errors
  — format-on-save uses 10000ms for IntelliJ-backed filetypes, 500ms otherwise
  Formatters by filetype:
    lua        → stylua
    go         → gofumpt → goimports-reviser → golines
    python     → idea_formatter
    json       → prettier
    yaml/markdown/java/xml/sh → idea_formatter
  Note: Go skips format-on-save (done via LSP/manual); format-on-save skips files with LSP errors

nvim-lint  (linting.lua)
  — lints immediately on BufWritePost and debounced on BufReadPost
    bash/zsh/sh → shellcheck
    go          → golangcilint
    lua         → selene
    markdown    → markdownlint-cli2
    python      → ruff
    yaml        → yamllint
  — missing linter executables are skipped instead of erroring on buffer open
  — Selene runs from the config root so `selene.toml` + `vim.yml` are applied
  — markdownlint-cli2 runs through BasedPyright's bundled Node when available
```

python-venv.lua
venv-selector.nvim
— activates Python envs per project and propagates them to terminals/LSP/DAP
— loads `${project_root}/.env` into Neovim's environment on venv activation
— extra managed-env search under `~/.local/share/nvim/python-venvs`
— pins `fd_binary_name` to the resolved `fd`/`fdfind` executable path so
discovery does not depend on the shell `PATH` that launched Neovim
— user commands:
:PythonVenvSelect
:PythonVenvCreate [name] [python]
:PythonVenvRecreate [name] [python]
:PythonVenvInstall [pip args]
— keymaps:
<leader>ps select env
<leader>pc create env
<leader>pr recreate env
<leader>pi install default deps
<leader>pI prompt for custom pip install args

---

### 6. UI

```
colorschemes.lua
  ├── tokyonight.nvim   ── ACTIVE (night style, loads eagerly, priority 1000)
  ├── kanagawa.nvim     ── lazy
  ├── jb.nvim           ── lazy (JetBrains theme)
  ├── oxocarbon.nvim    ── lazy
  ├── nordic.nvim       ── lazy
  ├── vague.nvim        ── lazy
  ├── onenord.nvim      ── lazy
  ├── evergarden        ── lazy
  ├── poimandres.nvim   ── lazy
  └── themery.nvim      ── switcher UI  →  <leader>ut

ui.lua
  ├── lualine.nvim      ── statusline (mode, branch, visible diagnostic/diff labels, root basename, clock)
  ├── bufferline.nvim   ── buffer tabs, LSP diagnostics badges
  │                        <S-h>/<S-l> cycle buffers, <leader>b* manage buffers
  ├── indent-blankline.nvim  ── │ indent guides
  ├── nvim-notify       ── notification popups (replaces vim.notify)
  ├── dressing.nvim     ── better vim.ui.select / vim.ui.input
  ├── which-key.nvim    ── key-binding popup (groups defined here)
  │                        Diffview close refreshes triggers through util/which_key_refresh.lua
  └── vim-illuminate    ── highlights references for symbol under cursor
                           Reference style is managed in util/init.lua and
                           reapplied from autocmds.lua

noice.nvim  (noice.lua)
  ├── nui.nvim          ── UI components
  └── nvim-notify       ── notification backend
  Overrides: cmdline UI, messages, LSP markdown rendering
  Note: hover/signature disabled (conflicts with inlay hints)
```

---

### 7. Navigation & Editor

```
editor.lua
  ├── oil.nvim                ── buffer-based file manager (rename/move/copy by editing text)
  │     — `-` open parent dir, `<leader>o` open cwd
  │     — edit filenames like a buffer, `:w` to apply; `g.` toggle hidden
  │
  ├── telescope.nvim          ── fuzzy finder (cwd on <leader><space>/<leader>ff/<leader>fg, root on <leader>fF/<leader>fG)
  │     └── telescope-fzf-native.nvim  ── faster sorter (requires make)
  │
  ├── scratch.nvim            ── persistent scratch files under `<leader>f`
  │     — `<leader>fs` new scratch, `<leader>fS` open scratch
  │     — `<leader>fi` / `:ScratchInfo` reports global and Java project-local scratch paths
  │     — `<leader>fN` create named scratch, files stored in stdpath("state")/scratch
  │     — Java is special-cased to open project-local `Scratch.java` inside
  │       Maven/Gradle source roots when available
  │
  ├── neo-tree.nvim           ── file explorer (<leader>e cwd, <leader>E root)
  │     ├── native preview mode  ── `P` float preview, `l` focus, `<C-f>`/`<C-b>` scroll
  │     ├── nvim-window-picker  ── `s` in tree = pick window to open file in
  │     ├── open mappings reveal current file by default; `<leader>ue` toggles that session-local behavior
  │     ├── `Y` copies absolute path with unnamed-register fallback when clipboard is unavailable
  │     └── nvim-lsp-file-operations  ── rename updates imports
  │
  ├── lazygit.nvim            ── LazyGit TUI  →  <leader>Gg
  │     ├── loads `~/.config/lazygit/config.yml` + repo `lazygit/config.yml`
  │     ├── `F` anywhere      ── fetch menu (all, prune, selected remote)
  │     ├── `U` anywhere      ── pull menu (`--rebase`, autostash, ff-only)
  │     └── `X` localBranches ── delete branches with gone upstream
  │
  └── harpoon                 ── file/workspace bookmarks  →  <leader>ha add, <leader>hh menu
                                            <leader>hm manual dirs, <leader>h1-4 jump to slot

motion.lua
  ├── flash.nvim              ── jump by label: s (jump), S (treesitter), r/R (remote)
  ├── nvim-spider             ── w/e/b respect camelCase/PascalCase
  └── nvim-treehopper         ── `m` pick treesitter node in o/v modes

glance.lua
  └── glance.nvim             ── split preview for LSP defs/refs (triggered by gd/gR/gy/gI)
                                  use_trouble_qf = true  →  sends to Trouble
```

---

### 8. Git

```
git.lua
  ├── gitsigns.nvim       ── hunk signs, blame, diff, stage/reset
  │                          Keymaps: ]h/[h, <leader>Gh* (buffer-local)
  ├── diffview.nvim       ── full diff viewer + file history + 3-way merge view
  │                          Keymaps in keymaps.lua: <leader>GD/GF/GH/GL/Gm/GM
  └── git-conflict.nvim   ── inline conflict resolution (auto-activates on conflict markers)
                             <leader>Co/Ct/Cb/CB/C0 pick ours/theirs/both/base/none,
                             ]x/[x navigate
```

**Gitsigns keymaps:**

| Key                   | Action                                |
|-----------------------|---------------------------------------|
| `]h` / `[h`           | Next / prev hunk                      |
| `<leader>Ghs/Ghr`     | Stage / reset hunk                    |
| `<leader>GhS/GhR`     | Stage / reset buffer                  |
| `<leader>Ghu`         | Undo stage                            |
| `<leader>Ghp`         | Preview hunk                          |
| `<leader>Ghb/GhB`     | Blame line / toggle                   |
| `<leader>Ghd`         | Diff this                             |
| `<leader>Ghw/Ghl/Ghv` | Word diff / line hl / deleted toggles |

**Diffview keymaps** (keymaps.lua):

| Key          | Action                   |
|--------------|--------------------------|
| `<leader>GD` | DiffviewOpen (repo diff) |
| `<leader>GF` | File history             |
| `<leader>GH` | Repo history             |
| `<leader>GL` | Line/range history       |
| `<leader>Gt` | Open `git mergetool`     |
| `<leader>GQ` | Finish `git mergetool`   |
| `<leader>GA` | Abort `git mergetool`    |
| `<leader>Gm` | Diff vs main/master      |
| `<leader>GM` | Diff vs origin/main      |
| `<leader>Gq` | Close Diffview           |

Keep these mappings only in `lua/config/keymaps.lua`. Duplicating the same lhs in a lazy.nvim plugin `keys` list can make lazy.nvim delete the real mapping on
first use.

---

### 9. Debugging (DAP)

```
dap.lua
  nvim-dap  ── core debugger
    ├── nvim-dap-ui           ── debug UI panels  →  <leader>du toggle, <leader>dU keep open, <leader>de eval
    │     └── nvim-nio        ── async I/O
    ├── nvim-dap-virtual-text ── inline variable values (masks secrets)
    ├── nvim-dap-go           ── Go adapter (delve)  →  <leader>dgt, <leader>dgl
    └── nvim-dap-python       ── Python adapter

Java DAP is provided by nvim-java (java_debug_adapter = true)
```

**DAP keymaps** (`<leader>d*`): b/B breakpoint, c continue, i step-into, O step-over, o step-out, r REPL, u UI, U keep UI open on exit, e eval, t terminate

---

### 10. Testing

```
neotest.lua
  neotest
    ├── neotest-java    ── Maven/Gradle test runner
    ├── neotest-go      ── Go test runner
    └── neotest-python  ── Python test runner
  util/neotest_scope.lua ── scoped discovery + file/package target helpers
```

**Neotest keymaps** (`<leader>t*`): tt run file, tT run all, tr nearest, tp run package, tq run file tests sequentially, tl last, tF run failed, ts summary, to
output, tO output panel, tS stop (interactive
picker), tw watch

---

### 11. Java

```
nvim-java.lua
  nvim-java  ── manages jdtls (Java LSP) entirely
    ├── lombok             ── annotation processor support
    ├── java_test          ── JUnit test runner integration
    ├── java_debug_adapter ── DAP adapter for Java
    └── spring_boot_tools  ── Spring Boot tooling

util/java_project_init.lua
  :JavaInitProject [dir] / <leader>ji
  └── local Maven/Gradle Java 21 starter templates

lsp.lua excludes jdtls from mason-lspconfig (nvim-java owns it)
vim.g.lspconfig_jdtls_enabled = false  (options.lua)
JVM: -Xms1g / -Xmx4g  (prevents OOM on refactoring)
```

**Java keymaps** (`<leader>j*`): ji init project, jr run main, jd debug main, jc stop, jl logs, ja attach remote, jt test class, jm test method, jv view report

---

### 12. Go

```
go-extras.lua
  gopher.nvim  ── Go struct tag helpers, iferr
    ├── plenary.nvim
    └── nvim-treesitter

go keymaps:
  <leader>gsj/gsy/gsd  — Add JSON/YAML/DB struct tags
  <leader>gie          — Add if err != nil block

keymaps.lua (global Go):
  <leader>gr/gR  — go run . / go run %
  <leader>gb     — go build .
  <leader>gt     — go test ./...

LSP (lsp.lua):  gopls with staticcheck, gofumpt, inlay hints, usePlaceholders
Formatting:     gofumpt → goimports-reviser → golines (120 char)
Linting:        golangcilint
```

---

### 13. Coding utilities

```
coding.lua
  ├── Comment.nvim    ── gc / gcc line comments, gb / gbc block comments
  │     └── nvim-ts-context-commentstring  ── context-aware commentstring (JSX, HTML embeds, etc.)
  ├── mini.surround   ── gsa/gsd/gsr/gsf add/delete/replace/find surrounding
  ├── mini.ai         ── enhanced text objects (af, if, ac, ic, ao, io, t=tag)
  └── yanky.nvim      ── yank history ring (p/P yanky-aware, <C-p>/<C-n> cycle)
                          <C-CR>/<leader>Hy open Telescope yank history
                          <C-A-CR> opens built-in ring history

editor.lua
  └── better-escape.nvim  ── smarter <Esc> handling in insert mode
```

---

### 14. Notes / Markdown

```
obsidian.lua
  obsidian.nvim  ── Obsidian vault integration (lazy, ft=markdown)
    └── plenary.nvim
    Uses Telescope as picker
    Vault path: ~/Obsidian
    Keymaps: <leader>On new, <leader>Oo open, <leader>Of find,
             <leader>Os search, <leader>Ob backlinks, <leader>Ol links,
             <leader>Ot tags, <leader>Od dailies, <leader>Or rename,
             <leader>Op paste image, <leader>Oc toggle checkbox

ftplugin/markdown.lua  ── per-buffer markdown settings
  ── wrap, spell, linebreak, j/k for wrapped lines
  ── <CR> follows [[wiki-links]] / #anchor links (unless obsidian loaded)
```

---

### 15. Session & Workspace

```
sessions.lua
  auto-session  ── auto save/restore on open/close
                   auto-save also when launched with file args
                   <leader>Ss/Sr/Sd/Sf/Sa (Sa enables auto-save)

projects.lua
  project.nvim  ── near-stock project detection + recent-project history
                   <leader>fp opens Telescope projects

util/frequent_roots.lua
  frequent roots  ── custom helper for manually managed dirs
                    custom project-tracking code retained but currently inactive
                    <leader>hm manage manual dirs (add/remove/list)

terminal.lua
  toggleterm.nvim  ── floating terminal, <A-a> toggle, <A-c> hide
```

---

### 16. LeetCode

```
leetcode.lua
  leetcode.nvim  ── LeetCode integration (lazy, cmd=Leet*)
  util/leetcode_roadmap.lua ── DSA roadmap topic/difficulty picker
    ├── nvim-lua/plenary.nvim
    ├── nvim-treesitter/nvim-treesitter
    ├── nvim-telescope/telescope.nvim
    ├── MunifTanjim/nui.nvim
    └── nvim-tree/nvim-web-devicons
    Keymaps: <leader>Ll menu, <leader>Lr run, <leader>Ls submit,
             <leader>Ld daily, <leader>Ln random, <leader>Lt tabs,
             <leader>Lp topic picker, <leader>LR DSA roadmap,
             <leader>LU update cookies
```

---

### 17. Diagnostics & Quickfix

```
trouble.lua
  trouble.nvim  ── better diagnostics/qf UI
    └── nvim-web-devicons
    Keymaps: <leader>xx root diag, <leader>xc cwd diag,
             <leader>xb buffer diag, <leader>cs symbols,
             <leader>cl call hierarchy, <leader>cu usages/refs,
             <leader>XL loclist, <leader>XQ quickfix
             ]q / [q next/prev trouble item

quicker.lua
  quicker.nvim  ── editable quickfix list  →  <leader>Xq
                   > / < expand/collapse context

keymaps.lua (diagnostic):
  [d / ]d  — prev/next diagnostic
  <leader>xd  — line diagnostics float
  <leader>xl  — diagnostics to loclist
  <leader>ud  — toggle tiny-inline-diagnostic on/off
  <leader>uD  — enable/disable all diagnostics entirely
  <leader>ui  — open UiInspect report for current cursor position
  <leader>uT  — toggle Treesitter highlighting for current buffer
  <leader>uI  — toggle vim-illuminate references for current buffer
  <leader>uJ  — toggle Java field usage counters
  <leader>uu  — toggle reference underline
  <leader>uH  — toggle reference background
  <leader>ci  — Java: import symbol at cursor; prompt if ambiguous
  <leader>cI  — Java: auto-import unambiguous diagnostics; prompt if ambiguous
```

---

Quality gate:
Makefile ── `make check` runs Mason `stylua --check` + `selene`
selene.toml / vim.yml ── local Selene config and minimal Neovim std

UI inspection:
util/ui_debug.lua ── :UiInspect, :UiToggleTreesitter, :UiToggleIlluminate
Reports `vim.inspect_pos()`, Treesitter captures,
parser state, diagnostics, conceal, colorscheme, and
related debug commands.

---

### 18. Misc utilities

```
todo-comments.lua
  todo-comments.nvim  ── highlight TODO/FIXME/NOTE/HACK/WARN/PERF/TEST
    └── plenary.nvim
    ]t / [t  — next/prev todo
    <leader>Xt/XT  — open in Trouble
    <leader>st  — search via Telescope

grug-far.lua
  grug-far.nvim  ── panel-based search & replace (ripgrep, fixed-strings by default)
    <leader>rg  — open (current file) / visual selection
    <leader>rG  — open (all files), fixed-strings mode
    <leader>rR  — open (all files), regex mode
    <leader>rw  — replace word under cursor

undotree.lua
  undotree  ── visual undo history tree  →  <leader>U

marks.lua
  marks.nvim  ── persistent marks with guttersigns, ]' / [' nav

auto-save.lua
  auto-save.nvim  ── auto-save enabled by default (<leader>ua toggle)
    — blocks save when LSP errors exist
    — triggers conform format after save
```

---

## Plugin dependency graph (condensed)

```
lazy.nvim
├── CORE DEPS (reused everywhere)
│   ├── plenary.nvim
│   ├── nui.nvim
│   └── nvim-web-devicons
│
├── LSP STACK
│   ├── mason.nvim
│   │   ├── mason-lspconfig.nvim
│   │   └── mason-tool-installer.nvim
│   ├── nvim-lspconfig
│   │   ├── fidget.nvim
│   │   └── nvim-lsp-file-operations → neo-tree
│   ├── glance.nvim
│   ├── actions-preview.nvim
│   └── tiny-inline-diagnostic.nvim
│
├── COMPLETION
│   └── nvim-cmp
│       ├── LuaSnip → friendly-snippets
│       ├── cmp-nvim-lsp ←── also used by nvim-lspconfig
│       ├── cmp-{buffer,path,cmdline,luasnip,signature-help}
│       └── lspkind.nvim
│
├── TREESITTER
│   └── nvim-treesitter
│       ├── nvim-treesitter-textobjects
│       ├── rainbow-delimiters.nvim
│       ├── nvim-treehopper  (motion.lua)
│       └── gopher.nvim  (go-extras.lua)
│
├── UI LAYER
│   ├── tokyonight.nvim (active) + 8 lazy colorschemes → themery.nvim
│   ├── lualine.nvim
│   ├── bufferline.nvim
│   ├── indent-blankline.nvim
│   ├── nvim-notify ←── also used by noice
│   ├── dressing.nvim
│   ├── which-key.nvim
│   ├── vim-illuminate
│   └── noice.nvim → nui.nvim + nvim-notify
│
├── NAVIGATION
│   ├── oil.nvim → nvim-web-devicons
│   ├── telescope.nvim → telescope-fzf-native
│   │   ├── project.nvim (projects.lua)
│   │   └── obsidian.nvim (uses telescope as picker)
│   ├── neo-tree.nvim → nvim-window-picker + native file preview
│   ├── harpoon
│   ├── flash.nvim
│   └── nvim-spider
│
├── GIT
│   ├── gitsigns.nvim
│   ├── diffview.nvim
│   ├── lazygit.nvim
│   └── git-conflict.nvim
│
├── DEBUGGING
│   └── nvim-dap
│       ├── nvim-dap-ui → nvim-nio
│       ├── nvim-dap-virtual-text
│       ├── nvim-dap-go
│       └── nvim-dap-python
│
├── TESTING
│   └── neotest
│       ├── neotest-java
│       ├── neotest-go
│       └── neotest-python
│
├── LEETCODE
│   └── leetcode.nvim → plenary + treesitter + telescope + nui + devicons
│
├── LANGUAGE-SPECIFIC
│   ├── nvim-java (Java / jdtls)
│   └── gopher.nvim (Go extras)
│
├── CODING HELPERS
│   ├── Comment.nvim → nvim-ts-context-commentstring
│   ├── mini.surround
│   ├── mini.ai → nvim-treesitter
│   ├── yanky.nvim
│   └── nvim-autopairs → nvim-cmp
│
└── MISC
    ├── auto-session
    ├── toggleterm.nvim
    ├── todo-comments.nvim
    ├── grug-far.nvim
    ├── trouble.nvim
    ├── quicker.nvim
    ├── undotree
    ├── marks.nvim
    ├── auto-save.nvim
    ├── better-escape.nvim
    └── obsidian.nvim
```

---

## Key-group cheat sheet (which-key groups)

| Prefix            | Group          | Main plugins involved                                                                      |
|-------------------|----------------|--------------------------------------------------------------------------------------------|
| `<leader>b`       | buffer         | bufferline                                                                                 |
| `<leader>c`       | code           | LSP, conform, trouble                                                                      |
| `<leader>d`       | debug          | nvim-dap                                                                                   |
| `<leader>dg`      | debug go       | nvim-dap-go                                                                                |
| `<leader>e/E`     | explorer       | neo-tree                                                                                   |
| `-` / `<leader>o` | oil            | oil.nvim                                                                                   |
| `<leader>f`       | file/find      | telescope, yanky                                                                           |
| `<leader>g`       | go             | gopls, gopher                                                                              |
| `<leader>gi`      | go insert      | gopher                                                                                     |
| `<leader>gs`      | go struct tags | gopher                                                                                     |
| `<leader>G`       | git            | gitsigns, diffview, lazygit                                                                |
| `<leader>Gh`      | hunks          | gitsigns                                                                                   |
| `<leader>h`       | harpoon/dirs   | harpoon                                                                                    |
| `<leader>j`       | java           | nvim-java, local Java helpers                                                              |
| `<leader>L`       | leetcode       | leetcode.nvim                                                                              |
| `<leader>l`       | lsp            | nvim-lspconfig                                                                             |
| `<leader>O`       | obsidian       | obsidian.nvim                                                                              |
| `<leader>p`       | python         | venv-selector.nvim, repo-local python venv commands                                        |
| `<leader>P`       | plugins        | lazy                                                                                       |
| `<leader>q`       | quit/session   | auto-session                                                                               |
| `<leader>r`       | replace        | grug-far                                                                                   |
| `<leader>s`       | search         | telescope, todo-comments                                                                   |
| `<leader>S`       | sessions       | auto-session                                                                               |
| `<leader>t`       | test/theme     | neotest, themery                                                                           |
| `<leader>u`       | ui             | toggles (spell, wrap, numbers, fold, diagnostics, inlay hints, reference style, auto-save) |
| `<leader>w`       | windows        | splits                                                                                     |
| `<leader>x`       | diagnostics    | trouble                                                                                    |
| `<leader>X`       | lists/maint    | trouble, quicker, todo-comments                                                            |
| `<leader><tab>`   | tabs           | vim tabs                                                                                   |
| `g`               | goto/misc      | LSP, glance, splits                                                                        |
| `gc`              | comment        | Comment.nvim                                                                               |
| `gs`              | surround       | mini.surround                                                                              |

---

## Notes & known issues

- **Java LSP:** `nvim-java` owns jdtls entirely. `lspconfig` + `mason-lspconfig` are explicitly told to skip it (`server_name ~= "jdtls"`,
  `vim.g.lspconfig_jdtls_enabled = false`).
- **Java code actions:** `<leader>ca` / `<A-CR>` still go through `actions-preview.nvim`, but many JDTLS refactors are command-only and cannot show a real diff
  preview.
- **Auto-save:** Enabled by default (`enabled = true`). Toggle with `<leader>ua`. Blocked when LSP errors exist. Triggers format after save.
- **Reference style:** Underline is enabled by default, reference background is disabled by default. Toggle them with `<leader>uu` and `<leader>uH`.
- **Go format on save:** Skipped in `conform.format_on_save` for Go — formatting is done manually or via gopls.
- **noice hover/signature:** Disabled to avoid conflicts with inlay hints. Use `K` / `gK` natively.
- **Folding:** Globally disabled (`opt.foldenable = false`). Toggle with `<leader>uf`.
- **LazyFile event:** Custom event alias for `BufReadPost + BufNewFile + BufWritePre`, defined in `config/lazy.lua`.
