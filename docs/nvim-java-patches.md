# nvim-java patches and workarounds

## Background

[nvim-java](https://github.com/nvim-java/nvim-java) is a Neovim plugin that wraps
JDTLS (Eclipse Java Development Tools Language Server). Internally it calls
`vim.lsp.config('jdtls', ...)` to register the LSP client, then
`vim.lsp.enable('jdtls')` to start it.

The current local setup has two categories of customization:

- JDTLS startup/runtime overrides in `lua/util/java_jdtls.lua`
- temporary `nvim-java` monkey-patches in `lua/util/java_patches.lua`

The intent is to keep the temporary patch layer small and removable once
upstream `nvim-java` and/or upstream JDTLS behavior is good enough.

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

**Status:** keep for now.

Reason:

- This is not related to the temporary record-refactor testing.
- It solves a general startup/runtime limitation in `nvim-java`.

---

## 2. Local JDTLS pinning

The config currently forces `nvim-java` to use a locally built JDTLS
repository when it exists:

- local build resolution: `lua/util/java_jdtls.lua`
- package-manager install-dir override: `patch_pkgm_install_dir(...)`
- version gate bypass for custom builds: `patch_jdtls_cmd(...)`

This is what makes Neovim use the JDTLS product built from:

`/home/konkov/Desktop/JDTLS/eclipse.jdt.ls/org.eclipse.jdt.ls.product/target/repository`

**Status:** keep until upstream fix lands and local build is no longer needed.

Reason:

- This is the mechanism that makes the editor actually consume the patched
  server.
- Once upstream is fixed and a released JDTLS contains the needed behavior,
  this can be removed and the config can return to package-managed JDTLS.

---

## 3. `NVIM_JDTLS_DEBUG=1` debug logging

The debug logging is now gated behind:

```bash
NVIM_JDTLS_DEBUG=1 nvim
```

When unset, the logger is a no-op.

It is used to inspect:

- inferred extract-variable selections
- refactor edit payloads returned by JDTLS
- chosen fallback selections

**Status:** keep for now, but this is low-value once the patch layer is gone.

Reason:

- It has essentially zero runtime cost when disabled.
- It is useful during current testing of temporary refactor patches.

---

## 4. `:JdtlsLocalInfo`

This command shows:

- configured JDTLS directory
- configured version label
- active attached JDTLS server info
- local `org.eclipse.jdt.core.manipulation` bundle path

It exists only as a debugging/inspection tool for the temporary local build.

**Status:** optional, removable after local-build testing is finished.

Reason:

- It does not affect Java functionality.
- It is only useful while verifying that Neovim is actually using the local
  JDTLS build.

---

## 5. `java_patches.lua`

These are temporary runtime monkey-patches around `nvim-java` internals.

Current file:

- [lua/util/java_patches.lua](/home/konkov/.config/nvim/lua/util/java_patches.lua:1)

### Patch status summary

| Patch/helper                               | What it does                                                                     | Status                                       |
|--------------------------------------------|----------------------------------------------------------------------------------|----------------------------------------------|
| `is_extract_variable_refactor`             | identifies the two extract-variable actions                                      | keep while extract-variable patch exists     |
| `has_explicit_selection`                   | distinguishes true selection from cursor-only zero-width range                   | keep while extract-variable patch exists     |
| `normalize_rename_targets`                 | normalizes rename payload shape into the list form expected by `nvim-java`       | keep until upstream rename dispatch is fixed |
| `select_inferred_selection`                | turns JDTLS inferred candidates into the `List` object expected by `nvim-java`   | keep while extract-variable patch exists     |
| `infer_selection_or_fallback`              | uses original selection flow first, then falls back to inferred JDTLS selections | keep while extract-variable patch exists     |
| `Action.rename` patch                      | repairs broken rename dispatch in `nvim-java` and accepts both call styles       | keep until upstream rename dispatch is fixed |
| `Action.choose_imports` patch              | guards against non-table import-candidate payloads                               | keep for now, test later                     |
| `JdtlsClient.java_infer_selection` patch   | instrumentation only; logs inferred selection flow                               | removable after debugging                    |
| `JdtlsClient.java_get_refactor_edit` patch | instrumentation only; logs refactor edit flow                                    | removable after debugging                    |
| `Refactor.get_selections` patch            | real behavioral workaround for cursor-based extract-variable refactors           | keep until upstream client behavior is fixed |

### Confirmed rename root cause

The rename failure after a successful extract-variable refactor is a client-side
`nvim-java` bug, not a JDTLS bug.

Observed behavior:

- JDTLS returns a valid workspace edit
- `nvim-java` applies the edit successfully
- the follow-up rename command `java.action.rename` is dispatched with valid
  rename arguments
- but the rename session still does not start unless patched locally

Confirmed cause:

- `nvim-java` defines the method as:

```lua
function Action:rename(params)
```

- but calls it as:

```lua
action.rename(params)
```

instead of:

```lua
action:rename(params)
```

Consequence:

- Lua passes the rename payload into `self`
- `params` becomes `nil`
- upstream code reaches `ipairs(params)` and fails, or cannot start the rename
  flow

Current local workaround:

- `Action.rename` accepts both:
  - correct colon-call shape
  - broken dot-call shape
- `normalize_rename_targets(...)` also wraps single rename targets into the
  list shape expected by upstream `Action:rename`

Removal condition:

- remove this patch pair once upstream `nvim-java` fixes the caller to use
  `action:rename(params)`

### Detailed reasoning for each remaining helper

#### `is_extract_variable_refactor(refactor_type)`

Purpose:

- narrows all custom behavior to:
    - `extractVariable`
    - `extractVariableAllOccurrence`

Reasoning:

- The patch layer should interfere with as little of `nvim-java` as possible.
- These were the only refactor commands known to be problematic in this setup.

#### `has_explicit_selection(params)`

Purpose:

- checks whether the request contains a real non-empty range

Reasoning:

- cursor-only refactor requests often appear as a zero-width range
- explicit selection and cursor inference should not be treated the same way
- only the cursor-inference case needed heavy patching

#### `normalize_rename_targets(params)`

Purpose:

- makes rename payload shape consistent for upstream `Action:rename`

Reasoning:

- upstream `Action:rename` expects a list and iterates with `ipairs(...)`
- rename payloads may arrive as:
  - a single target object
  - a target list
- wrapping the single-target case into `{ params }` keeps the upstream method
  happy

Status detail:

- keep until upstream rename dispatch is fixed
- remove together with the `Action.rename` patch

#### `select_inferred_selection(selection_res, ui, List)`

Purpose:

- converts JDTLS inferred candidates into `nvim-java`’s internal selection list

Reasoning:

- JDTLS can infer multiple valid expressions under the cursor
- `nvim-java` needs one concrete selection object
- some selections also require a second choice for initialization target

#### `infer_selection_or_fallback(...)`

Purpose:

- preserves original `nvim-java` behavior if it works
- only falls back to inferred JDTLS selections when the original path returns
  nothing usable

Reasoning:

- this is the conservative patch path
- it minimizes behavioral drift from upstream `nvim-java`

#### `Action.rename` patch

Purpose:

- works around the broken rename dispatch in `nvim-java`

Reasoning:

- debug tracing proved `runLspClientCommand(...)` receives valid rename
  arguments
- the breakage happens after dispatch because `nvim-java` calls a colon-method
  with dot syntax
- the patch accepts both calling conventions and recovers locally

Status detail:

- must keep for now
- remove once upstream `nvim-java` fixes the method call

#### `Action.choose_imports` patch

Purpose:

- guards against malformed import-choice payloads

Reasoning:

- if `nvim-java` tries to render an import chooser without a real table of
  candidates, it can fail noisily
- returning `{}` is safer than erroring

Status detail:

- keep for now
- remove later if testing shows upstream no longer emits malformed payloads

#### `JdtlsClient.java_infer_selection` patch

Purpose:

- logs inferred selection results for extract-variable operations

Reasoning:

- debugging aid only
- no intended behavior change beyond instrumentation

Status detail:

- safe to remove after debugging

#### `JdtlsClient.java_get_refactor_edit` patch

Purpose:

- logs refactor edit payloads/results for extract-variable operations

Reasoning:

- debugging aid only
- helps correlate:
    - selection inference
    - chosen candidate
    - resulting workspace edit

Status detail:

- safe to remove after debugging

#### `Refactor.get_selections` patch

Purpose:

- this is the real workaround
- it intercepts cursor-based extract-variable flows and synthesizes selections
  from JDTLS inferred candidates when `nvim-java` does not produce them

Reasoning:

- this was the client-side gap behind the broken record-accessor extract-variable
  workflow
- JDTLS could infer a valid expression, but `nvim-java` was not always turning
  that into a usable refactor selection flow

Status detail:

- keep until upstream `nvim-java` behavior is confirmed fixed
- this is the first patch to retest whenever upstream changes
