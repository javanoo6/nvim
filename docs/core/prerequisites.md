# Prerequisites

Requirements for this configuration and its configured integrations. For macOS,
start with [macOS setup](macos-setup.md).

## Neovim and parser tools

The configured nvim-treesitter `main` revision requires Neovim 0.12.0 or later,
`tree-sitter-cli` 0.26.1 or later, a C compiler, `tar`, and `curl`. Install the
CLI through a system package manager or its upstream release, rather than npm.
Parsers are requested from the language list in `lua/plugins/treesitter.lua`;
`:TSUpdate` updates installed parsers. Missing parsers are skipped quietly
while they install; restart or re-enter a buffer once installation finishes.

Use a Nerd Font for plugin icons. Kitty is the usual terminal for this setup,
but the configuration does not require Kitty. For example, its font setting is:

```conf
font_family IosevkaTerm Nerd Font Mono
```

## Linux system tools

```sh
sudo apt-get install -y \
  git make build-essential ripgrep fd-find curl unzip tar \
  xdg-utils sqlite3 python3 python3-pip python3-venv nodejs npm
```

Install Neovim, tree-sitter-cli, Go, and Java separately at versions satisfying
this configuration. Distribution packages may be older than those requirements.
`fd-find` provides `fdfind`; the local helpers accept either executable name.
`xdg-utils` supplies a Linux URL opener, and `sqlite3` is used by the optional
Firefox LeetCode-cookie helper. System clipboard support needs a detected
Wayland/X11 clipboard tool; without one, this config falls back to Vim registers.

## Language runtimes

- Go 1.24.0 or later for the pinned `gotestsum v1.13.0` build hook. The compiler
  and a C toolchain are needed for the Go adapter's default race-enabled tests.
- Python 3 with venv/pip support for environment commands and Python tooling.
  Mason installs debugpy; the DAP setup uses its isolated interpreter when
  available, with a `python3` fallback (which needs debugpy installed).
  Selecting a project venv changes the debuggee interpreter through `VIRTUAL_ENV`;
  the adapter keeps Mason's interpreter, so project envs do not need debugpy.
- JDK 21 for the standalone IntelliJ formatter and generated Java projects;
  Maven and/or Gradle (including project wrappers) for Java build/run/test flows.
  `NVIM_JAVA_HOME` overrides `JAVA_HOME` for the IntelliJ project SDK. The
  language server itself uses its bundled JBR.
- Node.js/npm for Mason's npm-backed tools. Markdown linting uses the Node
  bundled with BasedPyright when available to support the linter's regex syntax.
- Ruby tooling is optional and uses RVM/project gems, rather than Mason.
  The fallback Ruby is 3.2.5; projects can select `.ruby-version`/`.ruby-gemset`.
  Install Bundler, ruby-lsp, and RuboCop in the selected environment. A project
  Gemfile routes formatting through `bundle exec rubocop`.

On Linux, JDK source navigation also needs a working `lib/src.zip`. For the
Ubuntu JDK 21 package, install `openjdk-21-source` and check:

```sh
realpath /usr/lib/jvm/java-21-openjdk-amd64/lib/src.zip
```

IntelliJ handles Java LSP installation. nvim-java/JDTLS and their debug/test
bundles are not used. See [Java workflow](../java/java-workflow.md).

## Plugins and Mason

Launch Neovim and allow initial downloads to finish. `:Lazy restore` uses the
committed plugin versions. `:MasonToolsInstall` installs the configured external
tools; restart after initial setup.

`lua/plugins/lsp.lua` requests these Mason LSP configurations:
`lua_ls`, `bashls`, `helm_ls`, `jsonls`, `yamlls`, `gopls`, `pyright`,
`basedpyright`, and `ts_ls`. Pyright is the Python default; BasedPyright is opt-in.

`lua/plugins/mason.lua` requests:

| Tools                                                | Purpose                                           |
|------------------------------------------------------|---------------------------------------------------|
| stylua, selene                                       | Lua formatting and linting                        |
| bash-language-server, json-lsp, yaml-language-server | Shell/JSON/YAML LSP                               |
| typescript-language-server, pyright                  | JS/TS and Python LSP                              |
| ruff, prettier, eslint_d                             | Python linting, JSON/JS/TS formatting and linting |
| shellcheck, markdownlint-cli2, yamllint              | Shell/Markdown/YAML linting                       |
| golangci-lint, gopls                                 | Go linting and LSP                                |
| gofumpt, goimports-reviser, golines                  | Go formatting                                     |
| delve, debugpy                                       | Go/Python debugging                               |

## Markdown and Mermaid preview

`md-render.nvim` requires Neovim 0.12+ and a Kitty graphics compatible terminal
for inline images and Mermaid diagrams. Install Mermaid CLI with the Node/npm
environment used to launch Neovim:

```sh
npm install -g @mermaid-js/mermaid-cli
mmdc --version
```

The CLI uses Puppeteer's headless Chrome; allow its browser download during
installation. Verify with `:MdRender demo`, then use `<leader>mt` to toggle a
Markdown file between source and render or `<leader>ms` to see both in a vertical
split. Without `mmdc`, upstream can fall back to an on-demand npm download.
Plain Markdown renders without the diagram CLI; Mermaid images require it.
On Linux, the plugin prefers installed `google-chrome` when
`PUPPETEER_EXECUTABLE_PATH` is unset, so Ubuntu's sandbox restrictions on
Puppeteer's downloaded browser do not prevent rendering. An explicit value of
that environment variable is preserved. No sandbox-disabling flags are added.

## Standalone formatter

Initialize the formatter submodule and build its jar using JDK 21 and Maven:

```sh
cd ~/.config/nvim
git submodule update --init intellij-code-formatter
cd intellij-code-formatter
mvn package -pl minimal-jar-builder
mvn package -pl formatter-cli
```

Neovim expects `formatter-cli/target/formatter-cli-full.jar`. The nested
IntelliJ source submodule is not required for this CLI build. `:FormatterInfo`
reports the jar, Java executable, style path, and other formatter dependencies.

## Go and Java test helpers

neotest-golang's build hook installs `gotestsum v1.13.0` through `go install`.
Keep Go's GOBIN/GOPATH bin directory on PATH so the test runner can find it.
Installation failures appear as Lazy build errors; retry with
`:Lazy build neotest-golang` after fixing the cause.

Gopher's build hook runs `:GoInstallDeps`; run that command again if its helper
executables are missing. Java tests need the JUnit Console jar installed with
`:NeotestJava setup`. No manual version-specific jar download is configured.

## LazyGit and personal integrations

Install LazyGit separately. This config combines user-level LazyGit settings
with `lazygit/config.yml`, which defines `F` fetch, `U` pull, and `X` gone-upstream
branch cleanup. The user-level path is resolved for the current OS/XDG settings.
The Git merge-tool command is an external Git setting, not installed by this
Neovim repo; see [conflict resolution](../git/lazygit-resolve-conflicts.md).

Obsidian uses `~/Obsidian` in the current user's home. Create/configure that vault
before using its keys. LeetCode cookies are optional local credentials stored
outside tracked configuration.

## Config checks

Run from the config root after Mason and plugin installation:

```sh
make check      # stylua --check, selene, compatibility and isolated regressions
make format     # format init.lua, lua/, after/, and tests/ with stylua
```

The regression suites use installed plugins/parsers and disposable fixtures;
they do not start language servers or run project test suites.
