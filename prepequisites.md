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
  xdg-utils       # xdg-open — used by obsidian.nvim to open URLs
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
sudo apt-get install openjdk-21-jdk

# Set JAVA_HOME (add to ~/.bashrc or ~/.zshrc):
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

# nvim-java handles jdtls, java-debug, and vscode-java-test automatically
```

### Node.js / npm

```bash
# Required for prettier (JSON/YAML/Markdown formatting)
sudo apt-get install nodejs npm
# Or use nvm: https://github.com/nvm-sh/nvm

npm install -g prettier prettier-plugin-java
```

---

## 4. LazyGit

```bash
# Ubuntu PPA:
sudo add-apt-repository ppa:lazygit-team/release
sudo apt-get update && sudo apt-get install lazygit

# Or download binary from https://github.com/jesseduffield/lazygit/releases
```

---

## 5. Mason-managed tools (auto-installed on first launch)

These are installed automatically by Mason — no manual action needed.
Listed here for reference only.

| Tool                   | Purpose                  |
|------------------------|--------------------------|
| `lua-language-server`  | Lua LSP                  |
| `bash-language-server` | Bash LSP                 |
| `json-lsp`             | JSON LSP                 |
| `yaml-language-server` | YAML LSP                 |
| `gopls`                | Go LSP                   |
| `pyright`              | Python LSP               |
| `stylua`               | Lua formatter            |
| `black`                | Python formatter         |
| `gofumpt`              | Go formatter             |
| `goimports-reviser`    | Go imports organizer     |
| `golines`              | Go line length formatter |
| `golangci-lint`        | Go linter                |
| `delve`                | Go debugger (DAP)        |

> `jdtls`, `java-debug`, and `vscode-java-test` are managed by **nvim-java**, not Mason.

---

## 6. Go extras (run once inside Neovim)

```
:GoInstallDeps
```

Installs: `gomodifytags`, `iferr` — used by gopher.nvim for struct tag generation and `if err != nil` snippets.

---

## 7. MapStruct (Java projects)

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

## 8. Treesitter parsers (auto-compiled on first launch)

Installed automatically via `:TSUpdate`. Requires `gcc` or `clang`:

```bash
sudo apt-get install build-essential  # includes gcc, already covered by make above
```
