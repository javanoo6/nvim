#!/usr/bin/env sh
set -eu

file=${1:?missing filename}

case "$file" in
  /*) path=$file ;;
  *) path=$(pwd)/$file ;;
esac

vim_string_literal() {
  printf "%s" "$1" | sed "s/'/''/g"
}

open_in_nvim() {
  escaped_path=$(vim_string_literal "$path")
  nvim --server "$NVIM" --remote-expr "luaeval('require(\"util.lazygit_open\").open_file(_A)', '$escaped_path')" >/dev/null
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
  open_in_nvim
  kill_lazygit_ancestor
else
  nvim -- "$path"
fi
