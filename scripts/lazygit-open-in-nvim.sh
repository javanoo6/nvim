#!/usr/bin/env sh
set -eu

file=${1:?missing filename}

case "$file" in
  /*) path=$file ;;
  *) path=$(pwd)/$file ;;
esac

close_lazygit() {
  [ -n "${NVIM:-}" ] || return 0
  nvim --server "$NVIM" --remote-send '<Cmd>lua require("util.lazygit_open").close_lazygit()<CR>' >/dev/null 2>&1 || true
}

kill_lazygit_ancestor() {
  pid=$PPID
  while [ "${pid:-0}" -gt 1 ] 2>/dev/null; do
    comm=$(ps -o comm= -p "$pid" 2>/dev/null | tr -d '[:space:]')
    if [ "$comm" = "lazygit" ]; then
      kill -TERM "$pid" 2>/dev/null || true
      return 0
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d '[:space:]')
  done
}

if [ -n "${NVIM:-}" ]; then
  nvim --server "$NVIM" --remote-tab-silent "$path"
  close_lazygit
  kill_lazygit_ancestor
else
  nvim -- "$path"
fi
