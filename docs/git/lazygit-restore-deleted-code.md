# Restore Deleted Code With LazyGit

Use this when code was deleted, the deletion was already pushed, and the fix
should be a follow-up commit rather than rewriting history.

## Recommended: Restore From An Older Commit

Use this when only specific files or hunks need to come back.

1. Open LazyGit.
2. Go to the **Commits** panel.
3. Find the commit before the deletion happened.
4. Press `Enter` on that commit.
5. Find the file that still contains the deleted code.
6. Press `Enter` to view the file from that old commit.
7. Restore the whole file if needed:
    - Open the file actions menu, usually `a`.
    - Choose the checkout/restore-file action.
8. Restore only selected hunks if needed:
    - Open the file diff.
    - Select the needed hunk.
    - Use the patch/apply action to bring it back.
9. Return to the files panel.
10. Review the restored changes.
11. Stage the restored changes with `Space`.
12. Commit with `c`, for example:

```text
Restore accidentally deleted code
```

13. Push with `P`.

This creates a new commit that reintroduces the deleted code.

## Alternative: Revert The Bad Commit

Use this only when the bad pushed commit should mostly or entirely be undone.

1. Open LazyGit.
2. Go to the **Commits** panel.
3. Select the bad commit.
4. Open the commit actions menu, usually `a`.
5. Choose **Revert commit**.
6. Resolve conflicts if LazyGit reports any.
7. Review the resulting changes.
8. Push with `P`.

This creates a new commit that undoes the selected commit. Avoid this when the
bad commit also contains unrelated good changes that should stay.

## Small Fix: Copy From The Old Version

Use this when only a few lines are missing.

1. Open LazyGit.
2. Go to the **Commits** panel.
3. Open an older commit where the code still existed.
4. Open the file.
5. Copy the missing code.
6. Paste it into the current file in the editor.
7. Back in LazyGit, review the diff.
8. Stage and commit the restored code.
9. Push with `P`.

