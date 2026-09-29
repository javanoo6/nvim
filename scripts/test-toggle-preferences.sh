#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_state=$(mktemp -d)
trap 'rm -rf "$test_state"' EXIT HUP INT TERM
cd "$repo_dir"
for phase in write read; do
  XDG_STATE_HOME="$test_state" PERSIST_TOGGLE_TEST_PHASE="$phase" \
    nvim --headless -i NONE -u "$repo_dir/init.lua" \
    -c 'lua dofile("scripts/test-toggle-preferences.lua")'
done
