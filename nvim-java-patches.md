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

---

## 2. JDTLS settings (formatter + import order)

### Problem

nvim-java's `java.Config` type definition for the `jdtls` key only accepts
`{ version: string }`. Any other keys — including `settings` or `vmargs` —
are silently dropped and never forwarded to the LSP client. This was confirmed
by reading:

- `lua/java/config.lua` — type definition
- `lua/java/startup/lsp_setup.lua` — where nvim-java calls `vim.lsp.config()`
- `lua/java-core/ls/servers/jdtls/conf.lua` — base JDTLS config (no `settings` field)

### Fix

Call `vim.lsp.config("jdtls", { settings = { ... } })` directly after
`require("java").setup()`. Neovim 0.10+ deep-merges multiple calls to
`vim.lsp.config()` for the same server name, so this safely layers on top of
whatever nvim-java registered:

```lua
vim.lsp.config("jdtls", {
    settings = {
        java = {
            format = {
                settings = {
                    url = vim.fn.stdpath("config") .. "/Default-for-eclipse.xml",
                    profile = "Default",
                },
            },
            completion = {
                importOrder = { "javax", "", "java", "", "#" },
            },
            sources = {
                organizeImports = {
                    starThreshold = 5,
                    staticStarThreshold = 3,
                },
            },
        },
    },
})
```

### What each setting does

**`java.format.settings.url`**
Points JDTLS at an Eclipse JDT formatter XML profile. JDTLS uses the Eclipse
JDT formatter engine internally; this file contains all the `org.eclipse.jdt.core.formatter.*`
rules (indentation, wrapping, braces, etc.). Without this, JDTLS falls back to
Eclipse's built-in defaults (tabs, 80-char line limit).

The file `Default-for-eclipse.xml` lives in the nvim config directory and was
exported from the project's IntelliJ settings to be Eclipse-compatible.

**`java.format.settings.profile`**
Selects which named profile inside the XML to use. The XML can contain multiple
profiles; `"Default"` matches the `name="Default"` attribute in the file.

**`java.completion.importOrder`**
Controls the section ordering when JDTLS organises imports. Each string is a
package prefix; `""` is the catch-all group; `"#"` is static imports.

The value `{ "javax", "", "java", "", "#" }` is a starting point — JDTLS's
handling of the catch-all `""` position is not fully reliable, so a
post-processing Lua function in `ftplugin/java.lua` enforces the final order
after JDTLS finishes its cleanup pass.

**`java.sources.organizeImports.starThreshold`**
Number of classes from the same package that must be imported before JDTLS
collapses them into a wildcard (`import java.util.*`). Set to `5` to match
IntelliJ's default.

**`java.sources.organizeImports.staticStarThreshold`**
Same threshold but for static imports.
