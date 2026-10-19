# AGENTS.md

Start every session here:

- [docs/core/session-context.md](/home/konkov/.config/nvim/docs/core/session-context.md:1)
- [docs/core/crash-course.md](/home/konkov/.config/nvim/docs/core/crash-course.md:1)
- [docs/core/plugin-map.md](/home/konkov/.config/nvim/docs/core/plugin-map.md:1)

## Repo Rules

- Before finishing changes, agents must format every changed code file through
  this repository's Neovim formatter: run `./format.sh FILE...` from this repo,
  or `/home/konkov/.config/nvim/format.sh FILE...` from another directory.
  Pass every changed code and Markdown file explicitly; paths are relative to
  the calling directory. The script uses the same formatter config and
  `util.format` path as `<leader>cf`, waits, saves results, and exits nonzero
  on failure. Do not substitute another formatter or rely only on format-on-save.
  If formatting fails, resolve the error or report the blocker before handing off.
- Preserve the standard Vim direction model:
  `h = left`, `j = down`, `k = up`, `l = right`
- When a plugin exposes its own `j/k` or `<C-j>/<C-k>` mappings, keep them
  aligned with that model unless there is a strong reason not to.
- Prefer updating [docs/core/session-context.md](/home/konkov/.config/nvim/docs/core/session-context.md:1)
  whenever local behavior diverges from upstream plugin defaults or a new
  repo-specific helper/decision is introduced.
- Treat Java support as heavily customized. Read
  [docs/java/java-workflow.md](/home/konkov/.config/nvim/docs/java/java-workflow.md:1)
  before changing IntelliJ LSP, Java scratch behavior, or `neotest-java` flows.
