"""Small repeatable workflows. Exploratory audit coverage is documented separately."""

import json

from navigation import CASES as NAVIGATION_CASES
from languages import CASES as LANGUAGE_CASES


def equal(actual, expected, label):
    if actual != expected:
        raise AssertionError(f"{label}: expected {expected!r}; observed {actual!r}")


async def startup(audit):
    inventory = await audit.lua(
            '(function() local out={} for name,p in pairs(require("lazy.core.config").plugins) '
            'do out[name]={loaded=p._.loaded~=nil,installed=vim.fn.isdirectory(p.dir)==1} end return out end)()'
    )
    assert inventory, "No configured plugins discovered"
    missing = [name for name, item in inventory.items() if not item["installed"]]
    if missing:
        raise RuntimeError(f"Missing installed plugins: {missing}")
    (audit.base / "plugins.json").write_text(json.dumps(inventory, indent=2) + "\n")


async def preferences(audit):
    (audit.project / "main.txt").write_text("one\ntwo\nthree\n")
    await audit.reset("main.txt")
    before = await audit.lua("vim.wo.wrap")
    await audit.keys(" uw")
    equal(await audit.lua("vim.wo.wrap"), not before, "English wrap toggle")
    await audit.keys(" гц")
    equal(await audit.lua("vim.wo.wrap"), before, "Russian wrap toggle")
    await audit.wait_for('vim.fn.filereadable(vim.fn.stdpath("state").."/persist-toggle/state.json")==1')


async def bufferline(audit):
    for name in ["first.txt", "second.txt"]:
        (audit.project / name).write_text(name + "\n")
        await audit.reset(name)
    await audit.keys("H")
    equal(await audit.lua('vim.fn.expand("%:t")'), "first.txt", "Previous buffer")
    await audit.keys("Д")
    equal(await audit.lua('vim.fn.expand("%:t")'), "second.txt", "Russian next buffer")
    assert await audit.lua('vim.o.statusline~=""'), "Statusline is empty"


async def lint(audit):
    if not await audit.lua('vim.fn.executable("yamllint")==1'):
        raise RuntimeError("Lint scenario requires installed yamllint")
    tool = await audit.lua('(function() local r=vim.system({"yamllint","--version"},{text=true}):wait(5000); return {code=r.code,stderr=r.stderr,stdout=r.stdout} end)()')
    if tool["code"] != 0:
        raise RuntimeError("Installed yamllint cannot run: " + (tool.get("stderr") or tool.get("stdout") or str(tool)))
    (audit.project / "invalid.yaml").write_text("foo: [\n")
    await audit.reset("invalid.yaml")
    await audit.wait_for('#vim.diagnostic.get(0,{namespace=require("lint").get_namespace("yamllint")})>0')


async def mason(audit):
    await audit.cmd("Mason")
    await audit.wait_for('vim.bo.filetype=="mason"')
    assert await audit.lua("vim.api.nvim_buf_line_count(0)>1"), "Mason did not render package list"


async def terminal(audit):
    (audit.project / "main.txt").write_text("terminal fixture\n")
    await audit.reset("main.txt")
    for open_key, hide_key in [("<A-a>", "<A-c>"), ("<A-ф>", "<A-с>")]:
        await audit.keys(open_key)
        await audit.wait_for('vim.bo.buftype=="terminal"')
        equal((await audit.state())["mode"], "terminal", "Terminal enters input mode")
        await audit.raw(hide_key)
        await audit.wait_for('vim.bo.buftype~="terminal"')
        equal((await audit.state())["mode"], "normal", "Terminal hide restores source")


async def markdown(audit):
    (audit.project / "README.md").write_text("# Audit\n\n[Target](#target)\n\n## Target\n\n**bold**\n")
    await audit.reset("README.md")
    await audit.cmd("3")
    await audit.keys("<CR>")
    equal(await audit.lua('vim.fn.line(".")'), 5, "Markdown heading navigation")
    for key in [" mt", " ье"]:
        await audit.reset("README.md")
        await audit.keys(key)
        await audit.wait_for('vim.bo.filetype=="md-render"')
        rendered = await audit.lua("vim.api.nvim_buf_get_lines(0,0,-1,false)")
        assert any("Target" in line for line in rendered), "Rendered heading absent"


async def autosave(audit):
    path = audit.project / "autosave.txt"
    path.write_text("before\n")
    await audit.reset("autosave.txt")
    await audit.cmd('lua require("util.preferences").set("autoformat",false)')
    await audit.keys("Goafter<Esc>")
    await audit.wait_for('not vim.bo.modified', timeout=6)
    equal(path.read_text(), "before\nafter\n", "Auto-save writes editing result")


async def session(audit):
    (audit.project / "main.txt").write_text("session fixture\n")
    await audit.reset("main.txt")
    for save_key, restore_key in [(" Ss", " Sr"), (" Ыы", " Ык")]:
        await audit.keys(save_key, delay=0.8)
        await audit.cmd("vsplit")
        window_count = '(function() local n=0 for _,w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do if vim.api.nvim_win_get_config(w).relative=="" then n=n+1 end end return n end)()'
        equal(await audit.lua(window_count), 2, "Fixture split created")
        await audit.keys(restore_key, delay=1)
        await audit.wait_for(window_count + "==1", timeout=10)
        equal(await audit.lua('vim.fn.expand("%:t")'), "main.txt", "Session restores source")


async def quickfix(audit):
    path = audit.project / "main.txt"
    path.write_text("one\ntwo\nthree\n")
    await audit.reset("main.txt")
    await audit.cmd(
            'lua vim.fn.setqflist({{filename=' + json.dumps(str(path)) + ',lnum=2,col=1,text="audit entry"}})'
    )
    await audit.keys(" Xq")
    await audit.cmd("wincmd j")
    await audit.wait_for('vim.bo.filetype=="qf"')
    await audit.keys(">")
    await audit.wait_for("vim.api.nvim_buf_line_count(0)>1")
    # nvim_input parses key notation: a bare < can be an incomplete key event.
    await audit.keys("<lt>")
    await audit.wait_for("vim.api.nvim_buf_line_count(0)==1")


async def comment(audit):
    path = audit.project / "main.lua"
    await audit.cmd('lua require("util.preferences").set("autosave",false)')
    outcomes = {}
    for layout, key in [("english", "gcc"), ("russian", "псс")]:
        path.write_text("alpha\n")
        await audit.reset("main.lua")
        await audit.keys("gg0")
        await audit.keys(key, delay=0.8)
        outcomes[layout] = await audit.lua("vim.api.nvim_buf_get_lines(0,0,-1,false)")
        await audit.raw("<Esc>")
    equal(outcomes["english"], ["-- alpha"], "English line comment control")
    equal(outcomes["russian"], outcomes["english"], "Russian line comment parity")


async def surround(audit):
    path = audit.project / "main.lua"
    await audit.cmd('lua require("util.preferences").set("autosave",false)')
    outcomes = {}
    for layout, key in [("english", 'gsaiw"'), ("russian", 'пыфшц"')]:
        path.write_text("hello world\n")
        await audit.reset("main.lua")
        await audit.keys("gg0")
        await audit.keys(key, delay=0.8)
        outcomes[layout] = await audit.lua("vim.api.nvim_buf_get_lines(0,0,-1,false)")
        await audit.raw("<Esc>")
    equal(outcomes["english"], ['"hello" world'], "English surround control")
    equal(outcomes["russian"], outcomes["english"], "Russian surround text object parity")


async def marks(audit):
    (audit.project / "main.txt").write_text("one\ntwo\nthree\n")
    await audit.reset("main.txt")
    await audit.keys("ggmaGmb`a")
    await audit.keys("m]")
    equal(await audit.lua('vim.fn.line(".")'), 3, "English next mark control")
    await audit.keys("m[")
    equal(await audit.lua('vim.fn.line(".")'), 1, "English previous mark control")
    await audit.keys("m]")
    await audit.keys("ьх")
    equal(await audit.lua('vim.fn.line(".")'), 1, "Russian previous mark parity")


async def visual_word(audit):
    path = audit.project / "main.lua"
    path.write_text("alpha beta\n")
    await audit.reset("main.lua")
    outcomes = {}
    for layout, key in [("english", "viw"), ("russian", "мшц")]:
        await audit.raw("<Esc>")
        await audit.keys("gg0")
        await audit.keys(key)
        outcomes[layout] = await audit.lua('{mode=vim.api.nvim_get_mode().mode,cursor=vim.api.nvim_win_get_cursor(0)}')
    equal(outcomes["english"], {"mode": "v", "cursor": [1, 4]}, "English Visual inner-word control")
    equal(outcomes["russian"], outcomes["english"], "Russian Visual inner-word parity")


CASES = {
        "smoke": {"startup": startup},
        "core": {
                "preferences": preferences,
                "bufferline": bufferline,
                "lint": lint,
                "mason": mason,
                "terminal": terminal,
                "markdown": markdown,
                "autosave": autosave,
                "session": session,
                "quickfix": quickfix,
        },
        "layout": {"comment": comment, "surround": surround, "marks": marks, "visual-word": visual_word},
        "navigation": NAVIGATION_CASES,
        "languages": LANGUAGE_CASES,
}
