# Resolve Git Conflicts With LazyGit And Neovim

Use LazyGit to inspect/stage conflicts and finish the Git operation. Use Neovim
for edits, inline conflict choices, or a Diffview merge view.

## Open a conflicted file

Open LazyGit with `<leader>Gg` or `<A-g>`. `Esc` goes back, `q` exits LazyGit,
and `<C-q>` leaves its terminal mode without quitting the process.

In the Files panel, select the conflicted file and press `o`. This repo's
`os.open` helper opens it in the existing Neovim instance and closes the
LazyGit float. `e` uses LazyGit's configured editor and can have a different
process/window lifecycle.

To start a merge, select a branch in LazyGit's Branches panel and use its merge
action (`M` in the installed default mappings). `U` opens this repo's pull menu.
Those Git operations can produce unmerged files in the Files panel.

## Resolve inline markers

A normal merge conflict contains:

```text
<<<<<<< HEAD
ours
=======
theirs
>>>>>>> feature-branch
```

| Key          | Action                          |
|--------------|---------------------------------|
| `]x` / `[x`  | Next / previous marker conflict |
| `<leader>Co` | Keep ours                       |
| `<leader>Ct` | Keep theirs                     |
| `<leader>Cb` | Keep both                       |
| `<leader>C0` | Keep neither                    |

For a normal merge, ours is the current branch and theirs is the merged branch.
Rebase uses ours/theirs relative to the replay operation, so inspect the contents
rather than relying on branch intuition.

If neither side is correct, edit the code and remove all marker lines manually.
Save with `<C-s>`. Reopen LazyGit with `<leader>Gg`, review the diff, and stage
the file with `Space`. Continue the merge/rebase using LazyGit's operation menu;
a normal merge finishes with a commit (`c`).

## Diffview

`<leader>GD` opens Diffview. Its configured merge layout uses `diff3_mixed`, with
the editable result at the bottom and reference versions available for context.

| Key                                        | Action                                  |
|--------------------------------------------|-----------------------------------------|
| `]x` / `[x`                                | Next / previous conflict                |
| `<leader>Co` / `<leader>Ct`                | Choose ours / theirs for the conflict   |
| `<leader>Cb` / `<leader>CB`                | Choose both / base                      |
| `<leader>C0`                               | Choose none                             |
| `<leader>CO` / `<leader>CT` / `<leader>CA` | Choose ours / theirs / all for the file |
| `<leader>Gq`                               | Close Diffview                          |

## Git merge-tool processes

`<leader>Gt` runs `git mergetool`. The merge tool is an external Git setting,
not installed by this repo. Inspect it with:

```sh
git config --get merge.tool
git config --get mergetool.diffview.cmd
```

The local Diffview tool command is:

```sh
nvim "$MERGED" -c "DiffviewOpen"
```

It opens a second Neovim process. This config detects startup with
`DiffviewOpen` and installs:

| Key          | Action                                            |
|--------------|---------------------------------------------------|
| `<leader>GQ` | Write all and quit the merge-tool editor (`:wqa`) |
| `<leader>GA` | Abort it (`:cq`)                                  |

Those keys are also installed in classic Neovim diff buffers. They are specific
to the merge-tool lifecycle; in your main editor, save and reopen LazyGit
instead. `<leader>Gq` closes only Diffview and does not exit a nested editor.
The parent Git/LazyGit process controls which conflicted file is processed next.

Classic vimdiff panes use normal window navigation and `:diffget`; this repo
has no LOCAL/REMOTE/MERGED focus-key mappings. `<leader>Co/Ct` are inline-marker
or Diffview conflict choices, rather than classic vimdiff copy-hunk mappings.

## Markers committed by accident

Committed markers are normal file text; they do not recreate Git's unmerged
index state. Use `<leader>GC` / `:GitConflictMarkers` to scan tracked files,
fill quickfix, and jump to the first hit. Examples in fenced Markdown code
blocks are skipped. `:GitConflictMarkers!` fills quickfix without jumping.

Resolve with inline choices or manual edits, save, test, stage, and create a
normal fix commit. Diffview can compare versions, but it cannot reconstruct an
active merge from marker text alone.
