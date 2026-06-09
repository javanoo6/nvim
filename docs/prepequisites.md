# Prerequisites

Everything needed before this Neovim setup works correctly.

---

## 1. Neovim

```bash
# Must be 0.10+ (for virtual_lines diagnostic support)
# Download latest from https://github.com/neovim/neovim/releases
```

---

## 2. System packages

```bash
sudo apt-get install -y \
  git \           # version control (required by many plugins)
  make \          # required to build telescope-fzf-native
  ripgrep \       # rg — required by Telescope live grep and grug-far
  fd-find \       # fd — faster file finder for Telescope
  curl \          # used by Mason to download tools
  unzip \         # used by Mason to extract tools
  xdg-utils \     # xdg-open — used by obsidian.nvim to open URLs
  sqlite3         # used by scripts/update-leetcode-cookies.sh to read Firefox cookies
```

---

## 3. Language runtimes

### Go

```bash
# Download from https://golang.org/dl/
# Or:
sudo apt-get install golang-go

# Verify:
go version  # should be 1.21+
```

### Python

```bash
sudo apt-get install python3 python3-pip python3-venv

# Required by nvim-dap-python for debugging:
pip3 install debugpy
```

### Java (JDK)

```bash
# JDK 21 recommended (LTS)
sudo apt-get install openjdk-21-jdk openjdk-21-source

# Set JAVA_HOME (add to ~/.bashrc or ~/.zshrc):
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

# nvim-java handles jdtls, java-debug, and vscode-java-test automatically
```

Important notes:

- `openjdk-21-source` is required for JDK source navigation. On Ubuntu,
  `java --version` can be correct while
  `/usr/lib/jvm/java-21-openjdk-amd64/lib/src.zip` is still broken because the
  source archive is packaged separately.
- If `gd` on JDK methods only opens decompiled content or source navigation
  fails, verify the source archive:

```bash
realpath /usr/lib/jvm/java-21-openjdk-amd64/lib/src.zip
unzip -l /usr/lib/jvm/java-21-openjdk-amd64/lib/src.zip | head
```

- If needed, install optional local Javadoc too:

```bash
sudo apt-get install openjdk-21-doc
```

- Maven dependency navigation is configured to download `-sources.jar` files
  when available. That means external libraries should usually open as real
  source; if a dependency publishes no sources, JDTLS falls back to decompiled
  class content.

### Node.js / npm

```bash
# Required by Mason to install npm-backed tools such as prettier
sudo apt-get install nodejs npm
# Or use nvm: https://github.com/nvm-sh/nvm
```

---

## 4. Kitty terminal

This config is used with **Kitty** as the primary terminal.

```bash
# Install kitty:
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# Or via apt:
sudo apt-get install kitty
```

**Required:** a **Nerd Font** must be set in `~/.config/kitty/kitty.conf` so that
bufferline separators, lualine icons, neo-tree glyphs, and devicons render correctly.

Current font in use: `IosevkaTerm Nerd Font Mono`

```bash
# kitty.conf
font_family IosevkaTerm Nerd Font Mono
font_size 15.0
```

Download Nerd Fonts from: https://www.nerdfonts.com/font-downloads

---

## 6. LazyGit

```bash
# Ubuntu PPA:
sudo add-apt-repository ppa:lazygit-team/release
sudo apt-get update && sudo apt-get install lazygit

# Or download binary from https://github.com/jesseduffield/lazygit/releases
```

This setup uses two LazyGit config layers:

- `~/.config/lazygit/config.yml` for user-level LazyGit settings
- `~/.config/nvim/lazygit/config.yml` for repo-managed commands loaded by `lazygit.nvim`

Repo-managed LazyGit commands:

- `F` fetch menu
- `U` pull menu with `--rebase` and related options
- `X` delete local branches whose upstream is gone

---

## 7. Mason-managed tools (auto-installed on first launch)

These are installed automatically by Mason — no manual action needed.
Listed here for reference only.

| Tool                   | Purpose                  |
|------------------------|--------------------------|
| `lua-language-server`  | Lua LSP                  |
| `bash-language-server` | Bash LSP                 |
| `helm-ls`              | Helm LSP                 |
| `json-lsp`             | JSON LSP                 |
| `yaml-language-server` | YAML LSP                 |
| `gopls`                | Go LSP                   |
| `pyright`              | Python LSP               |
| `stylua`               | Lua formatter            |
| `ruff`                 | Python linter            |
| `prettier`             | JSON formatter           |
| `gofumpt`              | Go formatter             |
| `goimports-reviser`    | Go imports organizer     |
| `golines`              | Go line length formatter |
| `golangci-lint`        | Go linter                |
| `delve`                | Go debugger (DAP)        |

> `jdtls`, `java-debug`, and `vscode-java-test` are managed by **nvim-java**, not Mason.
>
> This repo also disables Glance `winbar` for Java/JDT navigation because
> decompiled `jdt://...` URIs can trigger `E539` in upstream Glance if rendered
> through its winbar statusline path.

---

## 8. Java test runner (run once inside Neovim)

Downloads the JUnit Platform Console Standalone jar required by neotest-java.

If on Neovim < 0.12, run manually:

```bash
mkdir -p ~/.local/share/nvim/neotest-java
curl -L https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/1.10.1/junit-platform-console-standalone-1.10.1.jar \
  -o ~/.local/share/nvim/neotest-java/junit-platform-console-standalone-1.10.1.jar
```

On Neovim 0.12+, run inside Neovim instead:

```
:NeotestJava setup
```

---

## 9. Go extras (run once inside Neovim)

```
:GoInstallDeps
```

Installs: `gomodifytags`, `iferr` — used by gopher.nvim for struct tag generation and `if err != nil` snippets.

---

## 10. MapStruct (Java projects)

For MapStruct + Lombok to work correctly, `annotationProcessorPaths` in `pom.xml` must follow this order:

```xml

<annotationProcessorPaths>
    <path>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <version>${lombok.version}</version>
    </path>
    <path>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok-mapstruct-binding</artifactId>
        <version>${org.mapstruct.binding.version}</version>
    </path>
    <path>
        <groupId>org.mapstruct</groupId>
        <artifactId>mapstruct-processor</artifactId>
        <version>${org.mapstruct.version}</version>
    </path>
</annotationProcessorPaths>
```

---

## 11. Treesitter parsers (auto-compiled on first launch)

Installed automatically via `:TSUpdate`. Requires `gcc` or `clang`:

```bash
sudo apt-get install build-essential  # includes gcc, already covered by make above
```
