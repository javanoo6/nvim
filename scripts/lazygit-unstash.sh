#!/usr/bin/env sh
set -eu

action=${1:?missing apply/pop action}
stash_index=${2:?missing stash index}
case "$action" in
apply | pop) ;;
*)
  echo "Expected apply or pop" >&2
  exit 2
  ;;
esac
case "$stash_index" in
'' | *[!0-9]*)
  echo "Expected a numeric stash index" >&2
  exit 2
  ;;
esac

# Save existing staged content so restored additions also remain unstaged.
# Without -u, read-tree changes only the index, preserving working files.
# Stop on conflicts: keep Git's unmerged entries and retain the stash.
index_tree=$(git write-tree)
stash_ref="stash@{$stash_index}"
git stash apply "$stash_ref"
git read-tree "$index_tree"
if [ "$action" = pop ]; then
  git stash drop "$stash_ref"
fi
