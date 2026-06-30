# Fix LazyGit Crash From Empty Git Objects

Use this when LazyGit exits with errors like:

```text
error: object file .git/objects/<xx>/<sha-rest> is empty
fatal: missing object <sha> for refs/heads/<branch>
fatal: bad object HEAD
error: bad tree object HEAD
```

This usually means Git has zero-byte loose object files. LazyGit crashes because
it asks Git to load branches or `HEAD`, and Git cannot read the corrupted object.

## First Check The Repo

Run commands from the repository that crashes LazyGit:

```sh
cd /path/to/repo
git status --short --branch
```

If `git status` fails with an empty object or missing object error, continue.

Check the current branch:

```sh
git rev-parse --abbrev-ref HEAD
cat .git/HEAD
```

If the error mentions a specific branch, inspect that ref:

```sh
cat .git/refs/heads/<branch-name>
```

The output is the object id that branch points to.

## Find Empty Objects

List all zero-byte loose Git objects:

```sh
find .git/objects -type f -empty -print | sort
```

If this prints files, those files are corrupt placeholders and must be removed
from Git's object lookup path before Git can download real copies.

## Back Up And Move Empty Objects

Do not delete the files first. Move them into a backup folder:

```sh
backup_dir=.git/corrupt-object-backups/empty-objects-$(date +%Y%m%d%H%M%S)
mkdir -p "$backup_dir"

find .git/objects -type f -empty -print | while IFS= read -r f; do
  dir=${f%/*}
  file=${f##*/}
  prefix=${dir##*/}
  mv "$f" "$backup_dir/${prefix}${file}.empty"
done
```

The backup filenames become full object ids, for example:

```text
.git/corrupt-object-backups/empty-objects-20260630092344/ee64d19668813b7b35f8a113ae3b15484ef7afd3.empty
```

## Refetch Objects From Origin

Fetch the current branch first:

```sh
branch=$(git rev-parse --abbrev-ref HEAD)
git fetch --force origin "refs/heads/$branch:refs/remotes/origin/$branch"
```

If `git status` still says `bad tree object HEAD` or `missing tree`, force Git
to redownload the reachable object graph:

```sh
git fetch --force --refetch origin "refs/heads/$branch:refs/remotes/origin/$branch"
```

If the damaged branch is not the current branch, replace `$branch` with that
branch name.

## Verify Recovery

Run these checks:

```sh
find .git/objects -type f -empty -print | sort
git cat-file -t HEAD
git status --short --branch
git branch --list
git fsck --connectivity-only --no-dangling
```

Expected results:

- `find .git/objects -type f -empty` prints nothing.
- `git cat-file -t HEAD` prints `commit`.
- `git status` and `git branch` no longer crash.
- `git fsck --connectivity-only --no-dangling` prints nothing.

After that, LazyGit should open normally.

## If Fetch Still Fails

If fetch fails with another empty object, repeat the empty-object scan and backup
step, then fetch again:

```sh
find .git/objects -type f -empty -print | sort
```

If `git fsck` reports many missing objects after all empty files are moved and a
full refetch still fails, the local clone may be too damaged. Preserve your
working tree changes before recloning:

```sh
git diff > ../repo-working-tree.patch
git diff --cached > ../repo-staged.patch
git status --short > ../repo-status.txt
```

Then make a fresh clone and apply the saved patches manually.

## What Happened In The QBRD-5157 Case

LazyGit crashed because:

```text
.git/objects/ee/64d19668813b7b35f8a113ae3b15484ef7afd3
```

was an empty file, while:

```text
refs/heads/QBRD-5157_quota_dto
```

pointed to that object. After moving all empty object files aside, a normal fetch
restored the commit object. A second `--refetch` was needed because `HEAD` then
referenced a missing tree object that Git had assumed was already local.
