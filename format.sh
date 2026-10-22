#!/bin/sh
set -eu

case "${1:-}" in
  -h|--help)
    cat <<'HELP'
Usage: ./format.sh [--] FILE...

Format existing files in place with this repo's Neovim formatter configuration.
Paths are relative to the calling directory. No sessions or editor UI are loaded.
Unsupported files, missing formatters, and formatting failures exit nonzero.
Earlier files may already be formatted when a later formatter fails.

Examples:
  ./format.sh lua/plugins/markdown.lua AGENTS.md
  /home/konkov/.config/nvim/format.sh ./src/main.py
  ./format.sh -- ./file-with-spaces.lua

Exit codes: 0 success, 1 formatting/setup error, 2 invalid arguments.
HELP
    exit 0
    ;;
esac

case "${1:-}" in
  --) shift ;;
  -*)
    printf '%s\n' 'error: Unknown option' 'help: ./format.sh --help; use -- before dash-leading filenames'
    exit 2
    ;;
esac
if [ "$#" -eq 0 ]; then
  printf '%s\n' 'error: No files supplied' 'help: ./format.sh [--] FILE...'
  exit 2
fi
if ! command -v nvim >/dev/null 2>&1; then
  printf '%s\n' 'error: Neovim is unavailable' 'help: Install Neovim and put nvim on PATH, then rerun format.sh'
  exit 1
fi

format_repo=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
exec nvim --headless -u NONE -i NONE -n -l "$format_repo/scripts/format.lua" "$@"
