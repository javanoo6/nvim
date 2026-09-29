# macOS setup

Validated on Apple Silicon with Neovim 0.12.5 and Homebrew JDK 21.

## Install

```sh
brew install neovim git ripgrep fd node go python lazygit tree-sitter-cli openjdk@21 maven
brew install --cask kitty font-iosevka-term-nerd-font
git clone --branch feat/macos-support git@github.com:javanoo6/nvim.git ~/.config/nvim
cd ~/.config/nvim
git submodule update --init intellij-code-formatter
```

Use the `feat/macos-support` branch until these changes are merged into `master`.
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
and debuggers. Restart Neovim after the first installation; the configuration
requires the Java Treesitter parser while loading key mappings.

Python debugging uses Mason's isolated `debugpy` environment when installed,
with the existing `python3` fallback. Language servers are installed by
Mason LSP configuration; Java tooling is installed by nvim-java.

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
- Obsidian's vault path in `lua/plugins/obsidian.lua` is still personal to the
  original Linux machine; point it at your actual vault before using it.
- Ruby integration still expects RVM Ruby 3.2.5 and the gems described in
  [prerequisites](prepequisites.md). It is not installed by the commands above.
- Intel macOS and Linux were not retested for this change.
