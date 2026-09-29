# Changelog

## 0.1.0

First tagged configuration release, adding macOS setup support.

- Detect Homebrew JDK 21 on macOS, respecting explicit Java environment settings.
- Use `pbcopy` and `pbpaste` for the macOS system clipboard.
- Install debugpy with Mason and use its isolated Python environment for debugging.
- Pin the IntelliJ formatter submodule to the macOS-compatible 0.0.5 release.
- Document installation, initial plugin setup, and remaining personal integrations.

Validated on Apple Silicon with Neovim 0.12.5 and JDK 21. Linux and Intel macOS
were not retested. The Obsidian vault path and RVM Ruby setup remain user-specific.
