# nvim-java patches and workarounds

Current local patches around `nvim-java`, JDTLS startup, and Java helper
behavior.

## Current State

JDTLS is package-managed by `nvim-java`.

The previous local JDTLS repository override was removed after upstream
`nvim-java` gained explicit package `path` support and the needed refactor
patches landed upstream. This config no longer hardcodes a local JDTLS checkout
or bypasses `nvim-java`'s JDTLS version validation.

Relevant files:

- [lua/plugins/nvim-java.lua](/home/konkov/.config/nvim/lua/plugins/nvim-java.lua:1)
- [lua/util/java_jdtls.lua](/home/konkov/.config/nvim/lua/util/java_jdtls.lua:1)
- [lua/util/java_patches.lua](/home/konkov/.config/nvim/lua/util/java_patches.lua:1)

## JDTLS JVM Args

`lua/util/java_jdtls.lua` still patches `java-core.ls.servers.jdtls.cmd` before
`require("java").setup()` runs.

It changes JDTLS startup memory from upstream's hardcoded `-Xms1G` to:

- `-Xms2G`
- `-Xmx8G`

This is kept because it is a local runtime preference, not part of the removed
refactor/JDTLS-path workaround.

## Runtime Guards

`lua/util/java_patches.lua` currently keeps two local runtime guards:

- Spring Boot `workspace/executeClientCommand` errors are swallowed for the
  `spring-boot` client so background Spring Boot command failures do not surface
  as noisy `spring-boot: -32603: Internal error.` messages during Java flows.
- `java-core.utils.lsp.get_jdtls()` prefers the `jdtls` client attached to the
  current buffer before falling back to the first global `jdtls` client. This
  keeps Java run/debug/test/profile/refactor actions pointed at the active
  workspace when multiple Java projects are open.

## Removed Local Workarounds

These local workarounds were removed after the `nvim-java` update:

- hardcoded local JDTLS repository path resolution
- `pkgm.manager.get_install_dir()` override for JDTLS
- custom JDTLS version label and version-gate bypass
- `:JdtlsLocalInfo`
- `NVIM_JDTLS_DEBUG` refactor payload logging
- local `Action.rename` patch for dot-call rename dispatch
- local extract-variable selection/refactor instrumentation
