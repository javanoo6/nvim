# macOS setup

Setup for Homebrew on Apple Silicon or Intel macOS. Use Neovim 0.12.0 or later
and tree-sitter-cli 0.26.1 or later for the configured Treesitter revision.

## Install

```sh
brew install neovim git ripgrep fd node go python lazygit tree-sitter-cli openjdk@21 maven
brew install --cask kitty font-iosevka-term-nerd-font
git clone git@github.com:javanoo6/nvim.git ~/.config/nvim
cd ~/.config/nvim
git submodule update --init intellij-code-formatter
```

Do not overwrite an existing `~/.config/nvim`; move it aside before cloning.
The formatter's nested IntelliJ source submodule is not required to build the CLI.

Set this in `~/.config/kitty/kitty.conf`, then restart Kitty:

```conf
font_family IosevkaTerm Nerd Font Mono
```

The config respects `NVIM_JAVA_HOME` and `JAVA_HOME`, then looks for Homebrew
JDK 21 under `/opt/homebrew` or `/usr/local`. It sets Java's PATH inside Neovim.
The macOS clipboard uses `pbcopy` and `pbpaste`.

## Install plugins and tools

Launch `nvim` and allow initial downloads to finish. Run `:Lazy restore` to use
the committed plugin versions, then `:MasonToolsInstall` for formatters, linters
and debuggers. Restart Neovim after the first installation. Missing parsers are
skipped quietly while they install; keymap registration does not require a
loaded Java parser.

Python debugging uses Mason's isolated `debugpy` environment when installed,
with the existing `python3` fallback. Language servers are installed by
Mason LSP configuration; Java uses IntelliJ LSP and the local run/test bridges.
Go tests use gotestsum v1.13.0; its build requires Go 1.24.0 or later.

## Build the formatter

```sh
cd ~/.config/nvim/intellij-code-formatter
export JAVA_HOME="$(brew --prefix openjdk@21)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
mvn package -pl minimal-jar-builder
mvn package -pl formatter-cli
```

Neovim uses `formatter-cli/target/formatter-cli-full.jar` automatically.
See the formatter README for daemon and one-shot usage.

## Checks and personal integrations

- `:checkhealth`, `:JavaInfo`, and `:FormatterInfo` show integration status.
- Run `:NeotestJava setup` once to install the JUnit runner.
- Obsidian resolves `~/Obsidian` from your current home; create that vault or
  change the workspace in `lua/plugins/obsidian.lua`.
- Ruby integration still expects RVM Ruby 3.2.5 and the gems described in
  [prerequisites](prerequisites.md). It is not installed by the commands above.
