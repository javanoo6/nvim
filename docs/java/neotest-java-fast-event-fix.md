# neotest-java Fast Event Fix

Status note for an old `neotest-java` classpath-provider failure.

## Status

Fixed upstream in `neotest-java`.

The relevant upstream commit is `1c623f7`:

```text
fix: wrap classpath LSP requests in vim.schedule (#293)
```

The pinned `neotest-java` version includes this fix, so this repo should not
carry a local override for:

```text
lua/neotest-java/core/spec_builder/compiler/classpath_provider.lua
```

## Original Symptom

```text
E5560: nvim_buf_is_valid must not be called in a fast event context
```

The stack involved:

- `vim.lsp.client.request()`
- `neotest-java/.../classpath_provider.lua`

`neotest-java` requested Java runtime/test classpaths from an `nio` coroutine
that could resume inside a libuv fast-event context. Wrapping the LSP requests
in `vim.schedule(...)` fixed that upstream.

## Local Guidance

- Do not re-add a local `classpath_provider.lua` shadow copy for this old bug.
- If `E5560` returns, treat it as a new upstream regression and compare against
  current `neotest-java` before patching locally.
- Existing local `neotest-java` overrides are unrelated to this issue and should
  be evaluated independently.

Current local override files:

- [lua/neotest-java/core/file_checker.lua](/home/konkov/.config/nvim/lua/neotest-java/core/file_checker.lua:1)
- [lua/neotest-java/core/result_builder.lua](/home/konkov/.config/nvim/lua/neotest-java/core/result_builder.lua:1)
