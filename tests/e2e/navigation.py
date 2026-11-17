"""Repeatable navigation and Git workflows in disposable projects."""

import asyncio
import json
import subprocess


def git(audit, *args):
    return subprocess.run(
            ["git", "-c", "core.hooksPath=/dev/null", *args],
            cwd=audit.project,
            check=True,
            capture_output=True,
            text=True,
    ).stdout


def init_git(audit):
    git(audit, "init", "-q")
    git(audit, "config", "user.name", "E2E Audit")
    git(audit, "config", "user.email", "audit@example.invalid")
    git(audit, "add", ".")
    git(audit, "commit", "-qm", "fixture")


async def telescope(audit):
    (audit.project / "one.txt").write_text("one\n")
    (audit.project / "target.txt").write_text("target content\n")
    await audit.reset("one.txt")
    await audit.keys(" ff")
    await audit.wait_for('vim.bo.filetype=="TelescopePrompt"')
    await audit.raw("target")
    await audit.wait_for(
            '(function() local e=require("telescope.actions.state").get_selected_entry(); '
            'return e and e[1] and e[1]:match("target.txt") ~= nil end)()'
    )
    await audit.raw("<CR>")
    await audit.wait_for('vim.fn.expand("%:t")=="target.txt"')
    assert await audit.lua('vim.api.nvim_get_current_line()') == "target content"


async def neotree(audit):
    (audit.project / "one.txt").write_text("one\n")
    await audit.reset("one.txt")
    await audit.keys(" e")
    await audit.wait_for('vim.bo.filetype=="neo-tree"')
    # send_keys prepends Escape, which closes the tree; use raw input inside it.
    await audit.raw("a")
    await audit.wait_for('vim.bo.filetype=="neo-tree-popup"')
    await audit.raw("created.txt<CR>")
    await audit.wait_for('vim.bo.filetype=="neo-tree"')
    assert (audit.project / "created.txt").exists(), "Neo-tree did not create file"
    await audit.raw("r")
    await audit.wait_for('vim.bo.filetype=="neo-tree-popup"')
    await audit.raw("<C-u>renamed.txt<CR>")
    await audit.wait_for('vim.bo.filetype=="neo-tree"')
    assert (audit.project / "renamed.txt").exists(), "Neo-tree did not rename file"
    assert not (audit.project / "created.txt").exists(), "Original file remains after rename"


async def git_workflow(audit):
    path = audit.project / "tracked.txt"
    path.write_text("one\nold\nend\n")
    init_git(audit)
    path.write_text("one\nnew\nend\n")
    await audit.reset("tracked.txt")
    await audit.wait_for('vim.b.gitsigns_head ~= nil')
    await audit.cmd("2")
    await audit.keys(" Ghs")
    for _ in range(40):
        if "new" in git(audit, "diff", "--cached"):
            break
        await asyncio.sleep(0.1)
    assert "new" in git(audit, "diff", "--cached"), "Hunk was not staged"
    await audit.keys(" Ghu")
    for _ in range(40):
        if not git(audit, "diff", "--cached"):
            break
        await asyncio.sleep(0.1)
    assert not git(audit, "diff", "--cached"), "Hunk stage was not undone"
    assert "new" in git(audit, "diff"), "Working tree change was lost"
    await audit.keys(" GD")
    await audit.wait_for('vim.bo.filetype=="DiffviewFiles"')
    lines = await audit.lua("vim.api.nvim_buf_get_lines(0,0,-1,false)")
    assert any("tracked.txt" in line for line in lines), "Diffview did not list changed file"
    await audit.keys(" Gq")
    await audit.wait_for('vim.fn.expand("%:t")=="tracked.txt"')


async def grug_replace(audit):
    path = audit.project / "search.txt"
    path.write_text("alpha.b\nalphaXb\n")
    await audit.reset("search.txt")
    await audit.cmd(
            'lua require("lazy").load({plugins={"grug-far.nvim"}}); '
            'require("grug-far").open({prefills={search="alpha.b",replacement="replaced",paths='
            + json.dumps(str(path))
            + "}})"
    )
    await audit.wait_for('vim.bo.filetype=="grug-far"')
    await audit.wait_for('(function() local l=vim.api.nvim_buf_get_lines(0,0,-1,false); return vim.tbl_contains(l,"replaced") end)()')
    await audit.raw("<Esc>\\r")
    for _ in range(40):
        if path.read_text() == "replaced\nalphaXb\n":
            break
        await asyncio.sleep(0.1)
    assert path.read_text() == "replaced\nalphaXb\n", "Literal replacement changed unexpected content"


CASES = {
        "telescope": telescope,
        "neotree": neotree,
        "git": git_workflow,
        "grug": grug_replace,
}
