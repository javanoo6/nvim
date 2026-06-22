# Resolve Git Conflicts With LazyGit And Neovim

Use this when a merge, pull, or rebase stops because Git found conflicts.

LazyGit is used to see Git state, open conflicted files, stage resolved files,
and finish the merge. Neovim is used to edit and resolve the conflict contents.

## Open LazyGit

From Neovim normal mode:

```text
<Space>Gg
```

`<Space>` is this config's `<leader>` key.

Inside LazyGit:

```text
Esc     back / cancel inside LazyGit
q       quit LazyGit
<C-q>   leave LazyGit terminal mode and return to Neovim
```

## Start The Merge Or Pull

To merge a branch from LazyGit:

1. Open LazyGit with `<Space>Gg`.
2. Go to the **Branches** panel with `4`.
3. Select the branch you want to merge into the current branch.
4. Press `M`.
5. Confirm the merge.

To pull from LazyGit:

1. Open LazyGit with `<Space>Gg`.
2. Press `U`.
3. Choose the pull target and mode.
4. Confirm.

If Git can merge cleanly, there is nothing else to do. If Git reports conflicts,
continue below.

## Open A Conflicted File

In LazyGit's **Files** panel, conflicted files appear as unmerged files.

Select a conflicted file and press:

```text
e
```

That opens the file in Neovim.

## When LazyGit Opens The Merge Tool

This setup uses Git's `diffview` merge tool:

```sh
nvim "$MERGED" -c "DiffviewOpen"
```

That means the flow becomes nested:

```text
main Neovim
  -> LazyGit terminal
      -> git mergetool
          -> second Neovim instance with DiffviewOpen
```

The merge tool is a **second Neovim process**, not another buffer in the main
Neovim session. Resolve the current file in that second Neovim, then finish that
process to return to LazyGit.

Use this key instead of remembering `:wqa`:

```text
<Space>GQ   finish current mergetool file and return to LazyGit
<Space>GA   abort current mergetool file
```

`<Space>GQ` writes all windows and quits the second Neovim. It does not directly
open the next conflicted file. After it returns you to LazyGit, stage the
resolved file and open the next conflicted file from LazyGit.

## Read The Conflict

A conflict usually looks like this:

```text
<<<<<<< HEAD
changes from ours
=======
changes from theirs
>>>>>>> feature-branch
```

For a normal merge:

```text
ours   = current branch / HEAD
theirs = branch being merged in
```

During a rebase, be careful: Git's ours/theirs wording can feel reversed because
your commit is being replayed onto another base.

## Jump Between Conflicts

In the conflicted file:

```text
]x      next conflict
[x      previous conflict
```

## Resolve A Simple Conflict

Use these keys in normal mode:

```text
<Space>Co    keep ours
<Space>Ct    keep theirs
<Space>Cb    keep both
<Space>C0    keep neither
```

After one of these keys, the conflict markers are removed and the chosen content
stays in the file.

Then jump to the next conflict with:

```text
]x
```

Repeat until the file has no conflict markers left.

## Resolve A Complex Conflict By Hand

Use this when neither side is correct by itself.

1. Edit the code into the final version you want.
2. Delete the marker lines:

```text
<<<<<<< HEAD
=======
>>>>>>> feature-branch
```

3. Save the file:

```text
<C-s>
```

The final file must not contain any `<<<<<<<`, `=======`, or `>>>>>>>` marker
lines.

## Stage The Resolved File

Return to LazyGit from the second Neovim merge tool:

```text
<Space>GQ
```

This is the preferred key. It is equivalent to:

```vim
:wqa
```

If you are in the main Neovim LazyGit terminal and need to leave terminal mode
without quitting LazyGit, press:

```text
<C-q>
```

In LazyGit's **Files** panel, select the resolved file and press:

```text
Space
```

That stages the file.

Repeat the open, resolve, save, and stage flow for every conflicted file.

## Move To The Next Conflicted File

There is no safe single key inside the second Neovim that can both finish the
current mergetool process and choose the next file in LazyGit. The handoff is:

```text
<Space>GQ   finish current file in second Neovim and return to LazyGit
Space       stage the resolved file in LazyGit
select next conflicted file
open merge tool for that file
```

Repeat that loop until LazyGit has no conflicted files left.

## Finish The Merge

When every conflicted file is resolved and staged, press this in LazyGit:

```text
c
```

For a merge commit, Git usually pre-fills the merge commit message. Confirm it.

## Use Diffview For Hard Conflicts

If inline conflict markers are not enough context, open Diffview from Neovim:

```text
<Space>GD
```

In Diffview merge view:

```text
]x / [x      next / previous conflict
<Space>Co   accept ours
<Space>Ct   accept theirs
<Space>Cb   accept both
<Space>CB   accept base
<Space>C0   accept none
<Space>GQ   finish current mergetool file
<Space>GA   abort current mergetool file
<Space>Gq   close Diffview
```

Diffview's configured merge layout shows the editable result separately from
the reference sides, so use it when you need to compare ours, base, and theirs.
For LazyGit-launched mergetool sessions, prefer `<Space>GQ` over `<Space>Gq`:
`<Space>Gq` only closes Diffview, while `<Space>GQ` exits the second Neovim and
returns to LazyGit.

## Quick Reference

```text
<Space>Gg                  open LazyGit
4                          branches panel
M                          merge selected branch
U                          pull menu
e                          open selected conflicted file
]x / [x                    next / previous conflict
<Space>Co                  keep ours
<Space>Ct                  keep theirs
<Space>Cb                  keep both
<Space>C0                  keep neither
<C-s>                      save file
<Space>GQ                  finish second nvim mergetool and return to LazyGit
<Space>GA                  abort second nvim mergetool
Space                      stage file in LazyGit
c                          commit / finish merge
<Space>GD                  open Diffview
<Space>Gq                  close Diffview
```
