# Restore A Deleted File In A New Commit

Use this when a file was deleted in an older commit, and you want to restore it
in your next commit without rewriting history.

## Goal

Create a new commit that adds the deleted file back.

Do not use reset, amend, or rebase for this workflow unless you explicitly want
to rewrite history.

## LazyGit Config Location

This Neovim setup keeps LazyGit config here:

```text
/home/konkov/.config/nvim/lazygit/config.yml
```

The config may define extra LazyGit commands, but restoring a deleted file can
be done with LazyGit's built-in commit and file actions.

## Find The Deleted File

1. Open LazyGit in the target repository.
2. Go to the **Commits** panel.
3. Select the commit that deleted the file.
4. Open the commit and note the deleted file path.
5. Identify the restore source:

```text
<deleting-commit>^
```

That means "the parent commit before the deletion".

## Restore With LazyGit

1. In LazyGit, go to the **Commits** panel.
2. Select the parent commit before the deletion:

```text
<deleting-commit>^
```

3. Press `Enter` to open that commit.
4. Find the deleted file in that commit's file list.
5. Select the file.
6. Open the file actions menu with `a`.
7. Choose the checkout or restore-file action.
8. Return to the **Files** panel.
9. Confirm the file appears in the working tree.
10. Review the diff.
11. Stage the restored file with `Space`.
12. Commit with `c`.

Example commit message:

```text
Restore accidentally deleted file
```

## Terminal Equivalent

If LazyGit's menu wording is unclear, run this from the repository root:

```sh
git restore --source=<deleting-commit>^ -- <path-to-deleted-file>
```

Then return to LazyGit, review the diff, stage the restored file, and commit it.

## When To Revert Instead

Use **revert commit** only when the whole deleting commit should be undone.

If the deleting commit also contains changes that should stay, restore only the
deleted file from the parent commit instead of reverting the whole commit.
