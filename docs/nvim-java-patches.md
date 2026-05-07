# nvim-java patches and workarounds

## Background

[nvim-java](https://github.com/nvim-java/nvim-java) is a Neovim plugin that wraps
JDTLS (Eclipse Java Development Tools Language Server). Internally it calls
`vim.lsp.config('jdtls', ...)` to register the LSP client, then
`vim.lsp.enable('jdtls')` to start it.

Two non-obvious limitations were discovered by reading nvim-java's source code
directly.

---

## 1. JVM heap size patch (`-Xms` / `-Xmx`)

### Problem

nvim-java hardcodes `-Xms1G` in
`lua/java-core/ls/servers/jdtls/cmd.lua` and provides no configuration option
to change it. Any `vmargs` or similar key passed to `require("java").setup()`
is silently ignored — the `jdtls` config type only accepts `{ version: string }`.

Additionally, `-Xmx` (maximum heap) is never set at all, meaning JDTLS can
consume unlimited memory on large projects.

### Fix

After `require("java").setup()` has run (which loads the module into Lua's
`package.loaded` cache), we monkey-patch `get_jvm_args` on the already-loaded
module:

```lua
local jdtls_cmd = require('java-core.ls.servers.jdtls.cmd')
local orig_get_jvm_args = jdtls_cmd.get_jvm_args
jdtls_cmd.get_jvm_args = function(cfg)
    local list = orig_get_jvm_args(cfg)
    for i, v in ipairs(list) do
        if v == '-Xms1G' then
            list[i] = '-Xms2G'
            break
        end
    end
    list:push('-Xmx8G')
    return list
end
```

**What this does:**

- Calls the original function to get the full argument list (java executable,
  OSGi flags, lombok agent path, etc.)
- Finds the hardcoded `-Xms1G` entry and replaces it with `-Xms2G`
- Appends `-Xmx8G` to cap maximum heap at 8 GB

**Why this works:** Lua modules are singletons cached in `package.loaded`. By
the time `setup()` returns, `java-core.ls.servers.jdtls.cmd` is loaded and its
table is shared by reference. Replacing the function on that table affects all
future callers, including nvim-java's internal startup code.

**Survival across plugin updates:** The patch does not edit any plugin file on
disk. It only replaces the in-memory function at runtime. If nvim-java changes
the function signature or the string `'-Xms1G'`, the patch silently stops
working (the `break` just never fires and only `-Xmx8G` gets added). Adjust
the values here to taste.
