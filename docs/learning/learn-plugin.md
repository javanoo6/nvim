# Learn Plugin

This guide describes a tiny in-repo teaching plugin you should write yourself.

Suggested files:

- `lua/learn/init.lua`
- `lua/plugins/learn.lua`

Its purpose is not utility. Its purpose is to make plugin behavior easy to edit,
observe, and understand.

## Progressive Overload

Do not try to learn everything at once.

Move through these levels in order:

1. Load a module and call `setup()`.
2. Add one command.
3. Add one keymap.
4. Add local state.
5. Add options and default merging.
6. Add one autocmd.
7. Add one callback option.
8. Add callback safety with `pcall`.
9. Learn how to reload the module while testing.

Only move to the next level when you can explain:

- what code ran
- what input it read
- what state changed
- what user-visible behavior changed

Relevant Lua references:

- [Modules](https://ic.ufrj.br/~fabiom/lua/09Modules.pdf): `require`, `return M`, module cache, `package.loaded`
- [Data Structures](https://ic.ufrj.br/~fabiom/lua/05DataStructures.pdf): tables, arrays/maps, mutable table references
- [Functions](https://ic.ufrj.br/~fabiom/lua/04Functions.pdf): functions as values, anonymous functions, multiple return values
- [Handling Errors](https://ic.ufrj.br/~fabiom/lua/08HandlingErrors.pdf): `pcall` and safe execution

## First Steps

1. Create `lua/learn/init.lua`.
2. Create `lua/plugins/learn.lua`.
3. Re-type the reference shapes below section by section.
4. Restart Neovim.
5. Run `:LearnHello`.
6. Press `<leader>uL`.
7. Run `:LearnState`.
8. Run `:LearnReset`.

## What This Teaches

- `setup({ ... })` and user options
- defaults vs overrides
- command creation
- keymap creation
- local module state
- optional autocmds
- callback options
- safe callback execution with `pcall`
- module reload behavior through `package.loaded`
- runtime debugging with `vim.notify`, `vim.inspect`, and `:messages`

## Suggested Exercises

### Exercise 1

Change the message and verify both `:LearnHello` and `<leader>uL` reflect it.

### Exercise 2

Set `debug = true`, trigger `:LearnHello`, then inspect `:messages`.

### Exercise 3

Set `count_buf_enter = true`, switch buffers a few times, then run `:LearnState`.

### Exercise 4

Replace `on_hello = nil` with:

```lua
on_hello = function(ctx)
  vim.notify("callback saw count = " .. ctx.hello_count)
end
```

Then run `:LearnHello`.

### Exercise 5

Add one new option yourself to `lua/learn/init.lua`, use it in behavior, and explain:

- where the option is defined
- where the user overrides it
- where the plugin reads it
- what runtime behavior changes

### Exercise 6

Break the `on_hello` callback on purpose:

```lua
on_hello = function()
  error("intentional callback failure")
end
```

Then run `:LearnHello`.

Expected result:

- the plugin should show an error notification
- Neovim should not crash
- `LearnHello` should still be callable afterward

### Exercise 7

Reload the module manually:

```vim
:lua package.loaded.learn = nil
:lua require("learn").setup({ message = "reloaded" })
```

Then run:

```vim
:LearnHello
```

Explain what reset and what did not reset.

## Reference: Lazy Spec

Write a plugin spec shaped like this:

```lua
return {
  {
    dir = vim.fn.stdpath("config"),
    name = "learn.nvim",
    event = "VeryLazy",
    config = function()
      require("learn").setup({
        message = "hello from your own teaching plugin",
        debug = false,
        count_buf_enter = false,
        on_hello = nil,
      })
    end,
  },
}
```

What to learn from this:

- why `dir = vim.fn.stdpath("config")` works for a local in-repo plugin
- what `name` does
- what `event` does
- why `config = function() ... end` is executable code
- how `setup({ ... })` passes user config

## Reference: Plugin Module

Write a module shaped like this:

```lua
local M = {}

local defaults = {
  enabled = true,
  message = "hello from learn plugin",
  keymap = "<leader>uL",
  debug = false,
  count_buf_enter = false,
  notify_level = vim.log.levels.INFO,
  on_hello = nil,
}

local config = vim.deepcopy(defaults)

local state = {
  hello_count = 0,
  buf_enter_count = 0,
}

local function debug(label, payload)
  if not config.debug then
    return
  end
  vim.notify(label .. ": " .. vim.inspect(payload), vim.log.levels.INFO, { title = "learn.nvim" })
end

local function safe_call(callback, ctx)
  if type(callback) ~= "function" then
    return
  end

  local ok, err = pcall(callback, ctx)
  if not ok then
    vim.notify("callback failed: " .. tostring(err), vim.log.levels.ERROR, { title = "learn.nvim" })
  end
end

local function hello()
  state.hello_count = state.hello_count + 1

  debug("hello()", {
    hello_count = state.hello_count,
    buf_enter_count = state.buf_enter_count,
    cwd = vim.uv.cwd(),
    filetype = vim.bo.filetype,
  })

  vim.notify(config.message .. " (" .. state.hello_count .. ")", config.notify_level, {
    title = "learn.nvim",
  })

  safe_call(config.on_hello, {
    message = config.message,
    hello_count = state.hello_count,
    buf_enter_count = state.buf_enter_count,
  })
end

local function show_state()
  vim.notify(vim.inspect(state), vim.log.levels.INFO, { title = "learn.nvim state" })
end

local function reset_state()
  state.hello_count = 0
  state.buf_enter_count = 0
  vim.notify("learn.nvim state reset", vim.log.levels.INFO, { title = "learn.nvim" })
end

local function register_commands()
  vim.api.nvim_create_user_command("LearnHello", hello, {})
  vim.api.nvim_create_user_command("LearnState", show_state, {})
  vim.api.nvim_create_user_command("LearnReset", reset_state, {})
end

local function register_keymaps()
  vim.keymap.set("n", config.keymap, hello, { desc = "Learn hello" })
end

local function register_autocmds()
  if not config.count_buf_enter then
    return
  end

  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("learn_plugin", { clear = true }),
    callback = function(args)
      state.buf_enter_count = state.buf_enter_count + 1
      debug("BufEnter", {
        buf = args.buf,
        name = vim.api.nvim_buf_get_name(args.buf),
        buf_enter_count = state.buf_enter_count,
      })
    end,
  })
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  if not config.enabled then
    return
  end

  register_commands()
  register_keymaps()
  register_autocmds()

  debug("setup()", config)
end

return M
```

Do not just copy it whole. Re-type it section by section and test after each step.

## Build Order

Implement in this order:

1. `local M = {}` and `return M`
2. `defaults`
3. `config`
4. `state`
5. `hello()`
6. `setup(opts)`
7. `:LearnHello`
8. keymap
9. `:LearnState`
10. `:LearnReset`
11. `debug()`
12. `BufEnter` autocmd
13. `on_hello` callback
14. `safe_call()` with `pcall`
15. module reload with `package.loaded.learn = nil`

After each step:

1. restart Neovim
2. trigger the feature
3. inspect `:messages`
4. explain what changed

## Rules For Yourself

- Type the code manually.
- Do not add three features at once.
- If it breaks, debug before asking why.
- After every new function, explain what inputs it reads and what side effect it has.
- After every new option, explain who reads it.
- Never call user callbacks directly once you know `pcall` exists.
- Do not mutate `defaults`; always merge from a fresh `vim.deepcopy(defaults)`.
