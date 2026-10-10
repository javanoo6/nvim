# AGENTS.md

Start every session here:

- [docs/core/session-context.md](/home/konkov/.config/nvim/docs/core/session-context.md:1)
- [docs/core/crash-course.md](/home/konkov/.config/nvim/docs/core/crash-course.md:1)
- [docs/core/plugin-map.md](/home/konkov/.config/nvim/docs/core/plugin-map.md:1)

## Repo Rules

- Preserve the standard Vim direction model:
  `h = left`, `j = down`, `k = up`, `l = right`
- When a plugin exposes its own `j/k` or `<C-j>/<C-k>` mappings, keep them
  aligned with that model unless there is a strong reason not to.
- Prefer updating [docs/core/session-context.md](/home/konkov/.config/nvim/docs/core/session-context.md:1)
  whenever local behavior diverges from upstream plugin defaults or a new
  repo-specific helper/decision is introduced.
- Treat Java support as heavily customized. Read the Java docs before changing
  `nvim-java`, JDTLS, Java scratch behavior, or `neotest-java` flows.
