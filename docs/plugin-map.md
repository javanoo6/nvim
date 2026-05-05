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
| ----------------------------- | ---------------------------------- | ---------------------- |
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
  └── mason-tool-installer.nvim  ── auto-installs: stylua, gopls,
                                    gofumpt, goimports-reviser, golines,
                                    golangci-lint, black, delve, LSP servers

nvim-lspconfig  ─────────────────────────────────── LSP config (lsp.lua)
  ├── cmp-nvim-lsp            ── exposes LSP completions to cmp
  ├── nvim-lsp-file-operations ── rename file → updates LSP imports
  │     └── neo-tree.nvim     ── (tree triggers file ops)
  ├── fidget.nvim             ── LSP progress spinner (bottom-right)
  ├── Glance (glance.lua)     ── preview pane for gd / gR / gy / gI
  ├── actions-preview.nvim    ── code action picker with diff preview (<leader>ca)
  └── tiny-inline-diagnostic.nvim  ── inline diagnostics with wrapping (off by default, <leader>ud toggle)
```

**LSP servers auto-installed:** `lua_ls`, `bashls`, `jsonls`, `yamlls`, `gopls`, `pyright`
**Java LSP:** handled separately by `nvim-java` (jdtls) — see Java section.

**Key LSP keymaps** (set on LspAttach in lsp.lua):

| Key                | Action                    |
| ------------------ | ------------------------- |
| `gd`               | Glance definitions        |
| `gR`               | Glance references         |
| `gy`               | Glance type definitions   |
| `gI`               | Glance implementations    |
| `gD`               | Native declaration        |
| `K`                | Hover                     |
| `gK`               | Signature help            |
| `<leader>ca`       | Code action               |
| `<leader>cr`       | Rename                    |
| `<leader>uh`       | Toggle inlay hints        |
| `<leader>lr/li/ll` | Restart / Info / Log      |
| `<leader>cd`       | Goto definition in vsplit |

---

### 3. Completion

```
nvim-cmp  (completion.lua)
  ├── LuaSnip                        ── snippet engine
  │     └── friendly-snippets        ── VSCode-style snippet library
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

**Completion keymaps:**

| Key                 | Action                    |
| ------------------- | ------------------------- |
| `<C-n>` / `<C-p>`   | Next / prev item          |
| `<Tab>` / `<S-Tab>` | Next item or jump snippet |
| `<CR>`              | Confirm                   |
| `<C-Space>`         | Trigger completion        |
| `<C-e>`             | Abort                     |
| `<C-b>` / `<C-f>`   | Scroll docs               |

---

### 4. Treesitter

```
nvim-treesitter  (treesitter.lua)  — highlight, indent, incremental selection
  ├── nvim-treesitter-textobjects  — af/if (function), ac/ic (class),
  │                                  aa/ia (param), al/il (loop), ai/ii (cond)
  │                                  Keymaps live in config/keymaps.lua
  └── rainbow-delimiters.nvim      — colorized bracket pairs

nvim-treehopper  (motion.lua)
  └── nvim-treesitter              — `m` in v/o to pick treesitter node
```

**Installed grammars:** bash, c, go, gomod, gowork, gotmpl, html, java, javascript, json, lua, markdown, python, query, vim, vimdoc, yaml, xml, groovy, kotlin

**Incremental selection** (visual mode only): `<CR>` start, `<Tab>` expand, `<S-Tab>` shrink, `<BS>` scope

---

### 5. Formatting & Linting

```
conform.nvim  (formatting.lua)
  — format on save (BufWritePre), also <leader>cf and <leader>cI
  Formatters by filetype:
    lua        → stylua
    go         → gofumpt → goimports-reviser → golines
    python     → black
    json/yaml/markdown → prettier
    java       → idea_formatter
  Note: Go skips format-on-save (done via LSP/manual); <leader>cI runs the IntelliJ formatter JAR directly

nvim-lint  (linting.lua)
  — lints on BufWritePost / BufReadPost
    go     → golangcilint
    python → ruff
```

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
  └── themery.nvim      ── switcher UI  →  <leader>tc

ui.lua
  ├── lualine.nvim      ── statusline (mode, branch, diagnostics, root, diff, clock)
  ├── bufferline.nvim   ── buffer tabs, LSP diagnostics badges
  │                        <S-h>/<S-l> cycle buffers, <leader>b* manage buffers
  ├── indent-blankline.nvim  ── │ indent guides
  ├── nvim-notify       ── notification popups (replaces vim.notify)
  ├── dressing.nvim     ── better vim.ui.select / vim.ui.input
  ├── which-key.nvim    ── key-binding popup (groups defined here)
  └── vim-illuminate    ── highlight all occurrences of word under cursor
                           Colors set in autocmds.lua (IlluminatedWord*)

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
  │     — `-` open parent dir, `<leader>-` open cwd
  │     — edit filenames like a buffer, `:w` to apply; `g.` toggle hidden
  │
  ├── telescope.nvim          ── fuzzy finder (<leader><space>, <leader>f*, <leader>s*)
  │     └── telescope-fzf-native.nvim  ── faster sorter (requires make)
  │
  ├── neo-tree.nvim           ── file explorer (<leader>e root, <leader>E cwd)
  │     ├── nvim-window-picker  ── `s` in tree = pick window to open file in
  │     └── nvim-lsp-file-operations  ── rename updates imports
  │
  ├── lazygit.nvim            ── LazyGit TUI  →  <leader>Gg
  │
  └── harpoon                 ── file bookmarks  →  <leader>ha add, <leader>hh menu
                                  <leader>h1-4 jump to slot

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
                             co/ct/cb/c0 pick ours/theirs/both/none, ]x/[x navigate
```

**Gitsigns keymaps:**

| Key                   | Action                                |
| --------------------- | ------------------------------------- |
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
| ------------ | ------------------------ |
| `<leader>GD` | DiffviewOpen (repo diff) |
| `<leader>GF` | File history             |
| `<leader>GH` | Repo history             |
| `<leader>GL` | Line/range history       |
| `<leader>Gm` | Diff vs main/master      |
| `<leader>GM` | Diff vs origin/main      |
| `<leader>Gq` | Close Diffview           |

Keep these mappings only in `lua/config/keymaps.lua`. Duplicating the same lhs in a lazy.nvim plugin `keys` list can make lazy.nvim delete the real mapping on first use.

---

### 9. Debugging (DAP)

```
dap.lua
  nvim-dap  ── core debugger
    ├── nvim-dap-ui           ── debug UI panels  →  <leader>du toggle, <leader>de eval
    │     └── nvim-nio        ── async I/O
    ├── nvim-dap-virtual-text ── inline variable values (masks secrets)
    ├── nvim-dap-go           ── Go adapter (delve)  →  <leader>dgt, <leader>dgl
    └── nvim-dap-python       ── Python adapter

Java DAP is provided by nvim-java (java_debug_adapter = true)
```

**DAP keymaps** (`<leader>d*`): b/B breakpoint, c continue, i step-into, O step-over, o step-out, r REPL, u UI, e eval, t terminate

---

### 10. Testing

```
neotest.lua
  neotest
    ├── neotest-java    ── Maven/Gradle test runner
    ├── neotest-go      ── Go test runner
    └── neotest-python  ── Python test runner
```

**Neotest keymaps** (`<leader>t*`): tt run file, tT run all, tr nearest, tl last, ts summary, to output, tO output panel, tS stop (interactive picker), tw watch

---

### 11. Java

```
nvim-java.lua
  nvim-java  ── manages jdtls (Java LSP) entirely
    ├── lombok             ── annotation processor support
    ├── java_test          ── JUnit test runner integration
    ├── java_debug_adapter ── DAP adapter for Java
    └── spring_boot_tools  ── Spring Boot tooling

lsp.lua excludes jdtls from mason-lspconfig (nvim-java owns it)
vim.g.lspconfig_jdtls_enabled = false  (options.lua)
JVM: -Xms1g / -Xmx4g  (prevents OOM on refactoring)
```

**Java keymaps** (`<leader>j*`): jr run main, jc stop, jt test class, jm test method, jv view report

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
  ├── mini.comment    ── gc / gcc toggle comments
  │     └── nvim-ts-context-commentstring  ── context-aware commentstring (JSX, HTML embeds, etc.)
  ├── mini.surround   ── gsa/gsd/gsr/gsf add/delete/replace/find surrounding
  ├── mini.ai         ── enhanced text objects (af, if, ac, ic, ao, io, t=tag)
  └── yanky.nvim      ── yank history ring (p/P yanky-aware, <C-p>/<C-n> cycle)
                          <leader>Hy open yank history picker

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
    Vault path: ~/Obsidian/personal
    Keymaps: <leader>on new, <leader>oo open, <leader>of find,
             <leader>os search, <leader>ob backlinks, <leader>ol links,
             <leader>ot tags, <leader>od dailies, <leader>or rename,
             <leader>op paste image, <leader>oc toggle checkbox

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
  project.nvim  ── project root detection + history
    └── telescope.nvim  ── <leader>fp to open project picker

terminal.lua
  toggleterm.nvim  ── floating terminal, <A-a> toggle, <A-c> hide
```

---

### 16. LeetCode

```
leetcode.lua
  leetcode.nvim  ── LeetCode integration (lazy, cmd=Leet*)
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
    Keymaps: <leader>xx workspace diag, <leader>xX buffer diag,
             <leader>cs symbols, <leader>cl LSP defs/refs,
             <leader>xL loclist, <leader>xQ quickfix
             ]q / [q next/prev trouble item

quicker.lua
  quicker.nvim  ── editable quickfix list  →  <leader>xq
                   > / < expand/collapse context

keymaps.lua (diagnostic):
  [d / ]d  — prev/next diagnostic
  <leader>xd  — line diagnostics float
  <leader>xl  — diagnostics to loclist
  <leader>ud  — toggle tiny-inline-diagnostic on/off
  <leader>uD  — enable/disable all diagnostics entirely
```

---

### 18. Misc utilities

```
todo-comments.lua
  todo-comments.nvim  ── highlight TODO/FIXME/NOTE/HACK/WARN/PERF/TEST
    └── plenary.nvim
    ]t / [t  — next/prev todo
    <leader>xt/xT  — open in Trouble
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
  auto-save.nvim  ── opt-in auto-save (disabled by default, <leader>ua toggle)
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
│   ├── neo-tree.nvim → nvim-window-picker
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
│   ├── mini.comment → nvim-ts-context-commentstring
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

| Prefix          | Group          | Main plugins involved                                                     |
| --------------- | -------------- | ------------------------------------------------------------------------- |
| `<leader>b`     | buffer         | bufferline                                                                |
| `<leader>c`     | code           | LSP, conform, trouble                                                     |
| `<leader>d`     | debug          | nvim-dap                                                                  |
| `<leader>dg`    | debug go       | nvim-dap-go                                                               |
| `<leader>e/E`   | explorer       | neo-tree                                                                  |
| `-` / `<leader>-` | oil          | oil.nvim                                                                  |
| `<leader>f`     | file/find      | telescope, yanky                                                          |
| `<leader>g`     | go             | gopls, gopher                                                             |
| `<leader>gi`    | go insert      | gopher                                                                    |
| `<leader>gs`    | go struct tags | gopher                                                                    |
| `<leader>G`     | git            | gitsigns, diffview, lazygit                                               |
| `<leader>Gh`    | hunks          | gitsigns                                                                  |
| `<leader>h`     | harpoon        | harpoon                                                                   |
| `<leader>j`     | java           | nvim-java                                                                 |
| `<leader>L`     | leetcode       | leetcode.nvim                                                             |
| `<leader>l`     | lsp            | nvim-lspconfig                                                            |
| `<leader>o`     | obsidian       | obsidian.nvim                                                             |
| `<leader>p`     | plugins        | lazy                                                                      |
| `<leader>q`     | quit/session   | auto-session                                                              |
| `<leader>r`     | replace        | grug-far                                                                  |
| `<leader>s`     | search         | telescope, todo-comments                                                  |
| `<leader>S`     | sessions       | auto-session                                                              |
| `<leader>t`     | test/theme     | neotest, themery                                                          |
| `<leader>u`     | ui             | toggles (spell, wrap, numbers, fold, diagnostics, inlay hints, auto-save) |
| `<leader>w`     | windows        | splits                                                                    |
| `<leader>x`     | diagnostics/qf | trouble, quicker, todo-comments                                           |
| `<leader><tab>` | tabs           | vim tabs                                                                  |
| `g`             | goto/misc      | LSP, glance, splits                                                       |
| `gc`            | comment        | mini.comment                                                              |
| `gs`            | surround       | mini.surround                                                             |

---

## Notes & known issues

- **Java LSP:** `nvim-java` owns jdtls entirely. `lspconfig` + `mason-lspconfig` are explicitly told to skip it (`server_name ~= "jdtls"`, `vim.g.lspconfig_jdtls_enabled = false`).
- **Auto-save:** Disabled by default (`enabled = false`). Toggle with `<leader>ua`. Blocked when LSP errors exist. Triggers format after save.
- **Go format on save:** Skipped in `conform.format_on_save` for Go — formatting is done manually or via gopls.
- **noice hover/signature:** Disabled to avoid conflicts with inlay hints. Use `K` / `gK` natively.
- **Folding:** Globally disabled (`opt.foldenable = false`). Toggle with `<leader>uf`.
- **LazyFile event:** Custom event alias for `BufReadPost + BufNewFile + BufWritePre`, defined in `config/lazy.lua`.
