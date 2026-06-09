# Lua Learning Plan For Neovim Plugins

> Purpose: learn enough Lua and Neovim config structure to read plugin docs,
> understand what each setting does, and change this repo without cargo-culting.

---

## End Goal

You should be able to:

- read a plugin `setup({ ... })` block and explain what each field means
- trace where a setting comes from and what code consumes it
- understand the difference between plugin-manager settings and plugin settings
- change mappings, hooks, callbacks, and nested option tables confidently
- read upstream plugin docs and map them onto this repo

## Progressive Overload Map

This is the intended path from "I do not understand plugin config" to "I can
write and maintain repo-local plugin support".

| Level | Skill | Proof |
|-------|-------|-------|
| 1 | read Lua tables/functions | explain one `setup({ ... })` table |
| 2 | separate Lua vs lazy.nvim vs plugin config | classify every field in one plugin spec |
| 3 | trace a setting | find where it is set and who reads it |
| 4 | debug runtime behavior | add/remove `vim.notify()` and explain output |
| 5 | write a tiny local plugin | complete `docs/learn-plugin.md` |
| 6 | use Neovim APIs | add command, keymap, autocmd, user input |
| 7 | write safe plugin behavior | validate options and protect callbacks with `pcall` |
| 8 | support this repo | add docs, which-key group, helper module, and verification |

Do not skip levels. If a level feels boring, prove it quickly and move on.

## Start Here

Do not begin with abstract Lua study.

Begin with the teaching plugin in this repo:

- [docs/learn-plugin.md](/home/konkov/.config/nvim/docs/learn-plugin.md:1)

The fastest path is:

1. write one small piece of the plugin
2. trigger the plugin
3. inspect runtime output
4. explain what changed

That loop will teach plugin writing faster than reading Lua in isolation.

Useful external Lua references from Fabio Mascarenhas' course:

- [Data Structures](https://ic.ufrj.br/~fabiom/lua/05DataStructures.pdf) for tables as arrays, maps, records, and mutable references
- [Functions](https://ic.ufrj.br/~fabiom/lua/04Functions.pdf) for callbacks and functions-as-values
- [Modules](https://ic.ufrj.br/~fabiom/lua/09Modules.pdf) for `require`, returned module tables, `package.path`, and `package.loaded`
- [Handling Errors](https://ic.ufrj.br/~fabiom/lua/08HandlingErrors.pdf) for `pcall` and safe callback execution

---

## Mental Model First

Before syntax, keep this model in your head:

1. `lazy.nvim` loads a plugin spec
2. the spec may define `event`, `keys`, `dependencies`, `opts`, `config`
3. once loaded, plugin Lua code exposes functions like `require("plugin").setup({...})`
4. your config passes a Lua table into that setup call
5. the plugin reads that table and changes behavior

So most plugin config is just:

- Lua tables
- functions
- strings
- booleans
- lists
- nested options

The hard part is usually not Lua syntax. It is knowing:

- who reads a setting
- when it is read
- whether it belongs to `lazy.nvim` or to the plugin itself

---

## Phase 1: Minimal Lua You Actually Need

Learn these first. Ignore the rest until needed.

### 1. Tables

This is the core syntax of plugin config.

```lua
{
  enabled = true,
  filetypes = { "lua", "go", "java" },
  window = {
    border = "rounded",
  },
}
```

Know the difference between:

- map/object style: `{ enabled = true }`
- list/array style: `{ "lua", "go", "java" }`
- nested tables: `{ window = { border = "rounded" } }`

### 2. Functions

You see them everywhere in plugin config.

```lua
config = function()
  require("scratch").setup({})
end
```

```lua
function my_func()
  print("hello")
end
```

Know:

- anonymous function: `function() ... end`
- named function: `local function x() ... end`
- function call: `x()`

### 3. Locals

```lua
local cmp = require("cmp")
local opts = { enabled = true }
```

Use `local` almost always.

### 4. Module loading

```lua
local telescope = require("telescope")
```

This loads another Lua module and returns whatever it exports.

For plugin work, remember:

- a module usually returns a table
- `require("learn")` returns the table from `lua/learn/init.lua`
- Lua caches modules after the first `require`
- for experiments only, clear the cache with `package.loaded.learn = nil`

Reference:

- [Modules](https://ic.ufrj.br/~fabiom/lua/09Modules.pdf)

### 5. Conditionals

```lua
if ft == "java" then
  open_java_scratch()
else
  require("scratch").scratchByType(ft)
end
```

### 6. Method-style vs function-style calls

You will see both:

```lua
vim.notify("hello")
```

```lua
list:push("x")
```

`obj:method(x)` is shorthand for `obj.method(obj, x)`.

### 7. Tables are mutable references

This matters for plugin defaults.

Bad pattern:

```lua
local config = defaults
config.message = "changed"
```

That mutates the same table `defaults` points at.

Safer pattern:

```lua
local config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
```

Use this when merging plugin options.

Reference:

- [Data Structures](https://ic.ufrj.br/~fabiom/lua/05DataStructures.pdf)

---

## Phase 2: Learn The Shape Of A Plugin Spec

Use this repo as the primary reference.

Study:

- [lua/plugins/completion.lua](/home/konkov/.config/nvim/lua/plugins/completion.lua:1)
- [lua/plugins/editor.lua](/home/konkov/.config/nvim/lua/plugins/editor.lua:1)
- [lua/plugins/ui.lua](/home/konkov/.config/nvim/lua/plugins/ui.lua:1)
- [lua/plugins/scratch.lua](/home/konkov/.config/nvim/lua/plugins/scratch.lua:1)

### Common fields in this repo

#### `event`

```lua
event = "VeryLazy"
```

This belongs to `lazy.nvim`, not to the plugin.
It controls when the plugin loads.

#### `keys`

```lua
keys = {
  { "<leader>fs", select_scratch_type, desc = "Scratch" },
}
```

Also belongs to `lazy.nvim`.
It defines mappings and may lazy-load the plugin on use.

#### `dependencies`

```lua
dependencies = {
  "nvim-telescope/telescope.nvim",
}
```

Also `lazy.nvim` territory.
It declares plugin dependencies.

#### `opts`

```lua
opts = {
  enabled = true,
}
```

Usually plugin options, but passed through `lazy.nvim`.
Many plugins support `opts = {}` directly.

Repo rule:

- use `opts` for simple static option tables
- use `config = function(_, opts) ... end` when setup needs code, local helpers,
  side effects, or command/keymap/autocmd registration

#### `config`

```lua
config = function()
  require("scratch").setup({
    filetypes = { "lua", "js" },
  })
end
```

This is your executable setup code.
Usually this is where plugin settings are actually applied.

---

## Phase 3: Learn To Separate Three Different Layers

This is where most confusion comes from.

### Layer 1: Lua language

Examples:

- tables
- functions
- `if`
- `local`
- `require`

Question: "Is this valid Lua syntax?"

### Layer 2: `lazy.nvim` plugin-manager spec

Examples:

- `event`
- `keys`
- `dependencies`
- `cmd`
- `version`

Question: "When does the plugin load?"

### Layer 3: plugin-specific config

Examples:

- `require("scratch").setup({ scratch_file_dir = ... })`
- `require("telescope").setup({ defaults = ... })`
- `require("which-key").setup(opts)`

Question: "What behavior does this plugin expose?"

Rule:

- if the setting is outside `setup({})`, it is often `lazy.nvim`
- if the setting is inside `setup({})`, it usually belongs to that plugin

---

## Phase 4: Learn To Read Option Tables

When you see:

```lua
require("telescope").setup({
  defaults = {
    file_ignore_patterns = { "%.git/", "node_modules/" },
    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
      },
    },
  },
})
```

Read it like this:

- `defaults` is a top-level Telescope option group
- `file_ignore_patterns` configures filtering
- `mappings` configures picker keymaps
- `i` means insert mode inside Telescope
- `["<C-j>"] = ...` binds a key to an action

Always ask:

1. what module is being configured?
2. what top-level option group am I inside?
3. is this scalar, list, nested table, or function callback?
4. what code path reads this field?

---

## Phase 5: Learn Callback-Based Config

Many important settings are functions, not plain values.

Example:

```lua
condition = function(buf)
  local diagnostics = vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR })
  return #diagnostics == 0
end
```

This means:

- the plugin will call your function later
- the function returns a decision
- the plugin behavior depends on that result

Study these files for callbacks:

- [lua/plugins/auto-save.lua](/home/konkov/.config/nvim/lua/plugins/auto-save.lua:1)
- [lua/plugins/editor.lua](/home/konkov/.config/nvim/lua/plugins/editor.lua:1)
- [lua/plugins/scratch.lua](/home/konkov/.config/nvim/lua/plugins/scratch.lua:1)

You need to understand:

- callback input parameters
- callback return value
- when the callback runs
- what side effects it has

### Callback safety

When your plugin calls user-provided callbacks, protect the call:

```lua
local ok, err = pcall(config.on_hello, ctx)
if not ok then
  vim.notify("callback failed: " .. tostring(err), vim.log.levels.ERROR)
end
```

Why:

- callbacks are user code
- user code can throw
- one bad callback should not break the whole plugin

Reference:

- [Handling Errors](https://ic.ufrj.br/~fabiom/lua/08HandlingErrors.pdf)

---

## Phase 6: Learn Neovim API Basics

You do not need all of `vim.*`. Start with these:

### File and path

- `vim.fs.find`
- `vim.fs.dirname`
- `vim.fs.basename`
- `vim.fn.filereadable`
- `vim.fn.isdirectory`
- `vim.fn.mkdir`

### Buffer/window

- `vim.api.nvim_get_current_buf()`
- `vim.api.nvim_buf_get_name(bufnr)`
- `vim.api.nvim_buf_set_lines(...)`
- `vim.api.nvim_win_set_cursor(...)`

### UI

- `vim.ui.select`
- `vim.ui.input`
- `vim.notify`

### Commands

- `vim.cmd("edit file")`
- `vim.api.nvim_create_autocmd(...)`
- `vim.keymap.set(...)`

### Plugin support APIs used in this repo

- `vim.api.nvim_create_user_command(...)`
- `vim.api.nvim_create_augroup(...)`
- `vim.api.nvim_create_autocmd(...)`
- `vim.keymap.set(...)`
- `vim.ui.select(...)`
- `vim.ui.input(...)`
- `vim.notify(...)`
- `vim.inspect(...)`
- `vim.lsp.get_clients(...)`
- `vim.diagnostic.get(...)`

---

## Phase 7: Understand Settings By Tracing Them

This is the real skill.

For any setting you want to understand, use this workflow:

### Example: `scratch_file_dir`

1. find where it is set
    - [lua/plugins/scratch.lua](/home/konkov/.config/nvim/lua/plugins/scratch.lua:1)
2. find who reads it
    - plugin source under `~/.local/share/nvim/lazy/scratch.nvim`
3. inspect the code path
    - search for `scratch_file_dir`
4. state the behavior in plain English
    - "this is the base directory where scratch.nvim stores global scratch files"

Do this repeatedly.

Best command for it:

```sh
rg -n "scratch_file_dir|filetypes|window_cmd" ~/.local/share/nvim/lazy/scratch.nvim lua
```

This is how you move from "I copied config" to "I understand config."

---

## Phase 8: Learn Runtime Debugging

You should not treat plugin behavior as magic.

When a plugin does something unexpected, debug it live.

### Fast runtime tools

#### `:lua`

Use it to inspect values quickly:

```vim
:lua print(vim.inspect(require("scratch")))
:lua print(vim.bo.filetype)
:lua print(vim.fn.getcwd())
```

#### `vim.notify()` and `print()`

Put them inside the plugin config or helper function you are testing:

```lua
vim.notify("java root = " .. tostring(find_java_project_root()))
print(vim.inspect(opts))
```

Use this for:

- checking which branch executed
- inspecting paths
- inspecting filetypes
- confirming a callback was called

#### `:messages`

After triggering a mapping or plugin action:

```vim
:messages
```

This shows output from:

- `print()`
- `vim.notify()`
- runtime errors
- command output

#### `:checkhealth`

Useful when plugin behavior depends on external tools or Neovim runtime setup.

#### `:Lazy`

Use it to inspect plugin load state, plugin errors, and plugin docs.

Useful checks:

- is the plugin installed?
- is it loaded yet?
- did a build step fail?
- did a lazy-load key trigger it?

#### `:verbose map`

Use it when a keymap does not behave as expected:

```vim
:verbose nmap <leader>jd
```

This shows what mapping owns the key.

#### LSP logs

For language-server behavior:

```vim
:LspLog
:lua print(vim.lsp.get_log_path())
```

### What to debug first

When testing a plugin, inspect these in order:

1. did the mapping/command run?
2. what filetype/root/path did the code see?
3. which branch ran?
4. what final plugin/API call happened?
5. what side effect happened on buffer, file, UI, or command output?

### Debugging exercise

Add temporary tracing to [lua/plugins/scratch.lua](/home/konkov/.config/nvim/lua/plugins/scratch.lua:1):

- print current filetype
- print chosen scratch path
- print whether Java project-local mode was used

Then trigger:

- `<leader>fs` in a Java project
- `<leader>fs` in a non-Java file
- `<leader>fS` from a random directory

Your job is to explain why each path happened.

---

## Phase 9: Study This Repo In A Specific Order

Do not read everything randomly.

### Week 1: Lua shape and plugin spec shape

Read:

- [lua/plugins/scratch.lua](/home/konkov/.config/nvim/lua/plugins/scratch.lua:1)
- [lua/plugins/auto-save.lua](/home/konkov/.config/nvim/lua/plugins/auto-save.lua:1)
- [lua/plugins/ui.lua](/home/konkov/.config/nvim/lua/plugins/ui.lua:1)

Goal:

- identify `keys`, `config`, `opts`, `dependencies`
- explain every `local function`
- explain every returned table

### Week 2: Completion and snippets

Read:

- [lua/plugins/completion.lua](/home/konkov/.config/nvim/lua/plugins/completion.lua:1)

Goal:

- understand source ordering
- understand snippet registration
- understand cmp mappings
- understand difference between snippet engine and completion engine

### Week 3: Telescope and editor workflows

Read:

- [lua/plugins/editor.lua](/home/konkov/.config/nvim/lua/plugins/editor.lua:1)
- [lua/util/init.lua](/home/konkov/.config/nvim/lua/util/init.lua:1)

Goal:

- understand root-aware picker behavior
- understand how helper functions reduce duplication
- understand nested setup tables

### Week 4: LSP

Read:

- [lua/plugins/lsp.lua](/home/konkov/.config/nvim/lua/plugins/lsp.lua:1)
- [lua/plugins/nvim-java.lua](/home/konkov/.config/nvim/lua/plugins/nvim-java.lua:1)

Goal:

- understand LSP attach flow
- understand capabilities
- understand language-specific overrides
- understand why Java config diverges from generic LSP config

---

## Phase 10: Use Upstream Docs Correctly

When reading plugin docs, extract only these things:

1. setup function name
2. top-level options
3. defaults
4. callbacks/hooks
5. commands
6. exported Lua functions

Then map them back into your config:

- plugin docs say `setup({ filetypes = ..., scratch_file_dir = ... })`
- your repo puts that under `config = function() require("scratch").setup(...) end`

That is the whole translation step.

Never try to memorize the whole README.

## Phase 10.5: Understand Current Plugin Support In This Repo

Repo-local plugin support usually has four layers:

1. `lua/plugins/*.lua` lazy spec
2. `lua/util/*.lua` helper module
3. docs under `docs/`
4. key discovery through `which-key`

Examples:

- Java runner/debug support:
  [lua/plugins/lsp.lua](/home/konkov/.config/nvim/lua/plugins/lsp.lua:1),
  [lua/util/java_runner.lua](/home/konkov/.config/nvim/lua/util/java_runner.lua:1),
  [lua/util/java_debug.lua](/home/konkov/.config/nvim/lua/util/java_debug.lua:1)
- Python venv support:
  [lua/plugins/python-venv.lua](/home/konkov/.config/nvim/lua/plugins/python-venv.lua:1),
  [lua/util/python_venv.lua](/home/konkov/.config/nvim/lua/util/python_venv.lua:1),
  [docs/python-venv-behavior.md](/home/konkov/.config/nvim/docs/python-venv-behavior.md:1)
- Neo-tree cwd support:
  [lua/plugins/editor.lua](/home/konkov/.config/nvim/lua/plugins/editor.lua:1),
  [lua/util/init.lua](/home/konkov/.config/nvim/lua/util/init.lua:1),
  [docs/neo-tree-cwd-behavior.md](/home/konkov/.config/nvim/docs/neo-tree-cwd-behavior.md:1)

When adding new support, ask:

1. Does it belong in a plugin spec or a `util` module?
2. Does it need a command?
3. Does it need a keymap?
4. Does it need a `which-key` group or description?
5. Does it change local behavior enough to document?
6. What is the smallest verification command?

---

## Phase 11: Build A Teaching Plugin

This is the capstone.

Build a tiny plugin that exists only to teach you how plugins work.

It should do almost nothing useful.
Its job is to make every moving part explicit.

### Goal of the teaching plugin

By the end, you should understand:

- plugin directory structure
- exported modules
- `setup({})`
- default config vs user config
- commands
- keymaps
- state
- callbacks
- autocmds
- runtime debugging

### Suggested plugin name

Use something obvious like:

- `lua/plugins/learn.lua` for the lazy spec
- `lua/learn/init.lua` for the plugin module

### Stage 1: Smallest possible plugin

Build a module that exports:

```lua
local M = {}

function M.setup(opts)
  vim.notify("learn plugin loaded")
end

return M
```

Then wire it in with a lazy spec.

You should understand:

- what `return M` exports
- what `require("learn")` returns
- who calls `setup`

### Stage 2: Add defaults and user overrides

Add:

```lua
local defaults = {
  enabled = true,
  message = "hello",
}
```

Merge user config into defaults.

You should understand:

- why defaults exist
- how user options override them
- how nested tables differ from flat values

### Stage 3: Add a command

Create:

```lua
:LearnHello
```

It should show the configured message.

You should understand:

- `vim.api.nvim_create_user_command`
- how commands connect editor input to Lua functions

### Stage 4: Add a keymap

Bind:

```lua
<leader>uh
```

or another test key for the learning plugin.

It should call the same command/function.

You should understand:

- difference between a command and direct function call
- where mapping descriptions are used

### Stage 5: Add state

Add internal state:

```lua
local state = {
  counter = 0,
}
```

Each invocation increments the counter and prints it.

You should understand:

- local module state
- when state persists
- when restart/reload resets it

### Stage 6: Add an autocmd

Create an autocmd on `BufEnter` or `InsertLeave`.

Example:

- count how many times buffers were entered
- notify only for certain filetypes

You should understand:

- event-driven behavior
- side effects
- when plugin code runs without explicit user action

### Stage 7: Add a callback option

Support:

```lua
setup({
  on_hello = function(msg)
    ...
  end,
})
```

If the callback exists, call it.

You should understand:

- plugin calling user code
- callback shape
- how options can be behavior, not only values

### Stage 8: Add a small picker or UI input

Use:

- `vim.ui.select`
- or `vim.ui.input`

Example:

- select a greeting style
- ask for a note title

You should understand:

- async callback flow
- UI-to-Lua handoff

### Stage 9: Debug it intentionally

Add temporary:

- `vim.notify`
- `print(vim.inspect(...))`
- `:messages` checks

Break one thing on purpose, then trace it.

### Stage 9.5: Reload it intentionally

While developing `lua/learn/init.lua`, test module cache behavior:

```vim
:lua package.loaded.learn = nil
:lua require("learn").setup({ message = "manual reload" })
```

You should understand:

- why `require("learn")` does not normally re-read the file every time
- what state resets after clearing `package.loaded.learn`
- what state remains because Neovim mappings/commands/autocmds were already
  registered

Reference:

- [Modules](https://ic.ufrj.br/~fabiom/lua/09Modules.pdf)

You should understand:

- how to debug runtime behavior instead of guessing

### Stage 10: Read your own plugin like upstream source

After building it, pretend it is a third-party plugin.

Answer:

1. what does `setup` accept?
2. what are the defaults?
3. what commands exist?
4. what mappings exist?
5. what state exists?
6. what runs on events?
7. what could break if option types are wrong?

If you can answer those, you can read real plugins much better.

### Suggested deliverables

Make the teaching plugin include:

- one config table
- one command
- one keymap
- one autocmd
- one callback option
- one piece of local state
- one debug print path

That is enough to cover most plugin magic.

---

## Exercises

Do these in order.

### Exercise 1

Explain this line in plain English:

```lua
{ "<leader>fs", select_scratch_type, desc = "Scratch" }
```

You should mention:

- it is a lazy key spec
- key is `<leader>fs`
- callback is `select_scratch_type`
- description feeds which-key / mapping metadata

### Exercise 2

Trace `global_scratch_dir` from:

- where it is defined
- where it is used
- what user-visible behavior it changes

### Exercise 3

Pick one Telescope option from [lua/plugins/editor.lua](/home/konkov/.config/nvim/lua/plugins/editor.lua:1) and explain:

- what plugin owns it
- what shape it has
- what behavior it changes

### Exercise 4

Take one plugin from `docs/plugin-map.md` and answer:

- how it loads
- where it is configured
- what keys invoke it
- what settings matter most

### Exercise 5

Open an upstream plugin source file and explain one option by reading the code,
not only the README.

### Exercise 6

Add a temporary `vim.notify()` inside your own teaching plugin and explain:

- when it runs
- why it runs
- what inputs it saw

### Exercise 7

Take one setting from a real plugin in this repo and rewrite it inside your
teaching plugin in simplified form.

Examples:

- a toggle
- a filetype filter
- a path setting
- a callback option

### Exercise 8

Take the teaching plugin's `on_hello` callback and protect it with `pcall`.

Then deliberately break the callback and explain:

- where the error was caught
- what notification appeared
- why the plugin still works afterward

### Exercise 9

Use `:verbose nmap` on one mapping from this repo and answer:

- what key is mapped?
- what file created it?
- does it call a Lua function or a Vim command?
- is it global or buffer-local?

### Exercise 10

Pick one local helper module under `lua/util/` and answer:

- what functions does it export?
- what plugin spec calls it?
- what user-visible behavior depends on it?
- what doc should be updated if it changes?

---

## What To Ignore For Now

Do not waste time early on:

- metatables
- coroutines
- advanced Lua module systems
- complex object-oriented Lua patterns
- every single Neovim API namespace

For plugin config work, those are low-yield early topics.

---

## Good Reference Files In This Repo

- [docs/plugin-map.md](/home/konkov/.config/nvim/docs/plugin-map.md:1)
- [docs/crash-course.md](/home/konkov/.config/nvim/docs/crash-course.md:1)
- [docs/root-detection-policy.md](/home/konkov/.config/nvim/docs/root-detection-policy.md:1)
- [lua/util/init.lua](/home/konkov/.config/nvim/lua/util/init.lua:1)
- [lua/plugins/scratch.lua](/home/konkov/.config/nvim/lua/plugins/scratch.lua:1)
- [lua/plugins/completion.lua](/home/konkov/.config/nvim/lua/plugins/completion.lua:1)
- [lua/plugins/editor.lua](/home/konkov/.config/nvim/lua/plugins/editor.lua:1)
- [lua/plugins/lsp.lua](/home/konkov/.config/nvim/lua/plugins/lsp.lua:1)

---

## Practical Rule

When confused by plugin config, always ask:

1. is this Lua syntax, lazy.nvim spec, or plugin-specific setup?
2. who reads this field?
3. when is it read?
4. what visible behavior changes if I edit it?

If you can answer those four, you understand the setting.
