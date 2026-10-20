"""Run with python3 tests/markdown_scroll.py; uses a real disposable Neovim TUI."""

import fcntl
import json
import os
from pathlib import Path
import pty
import struct
import subprocess
import tempfile
import termios
import threading
import time


ROOT = Path(__file__).resolve().parents[1]


def main():
    with tempfile.TemporaryDirectory(prefix="markdown-scroll-") as directory:
        socket = str(Path(directory) / "socket")
        init = Path(directory) / "init.lua"
        init.write_text(
            "vim.opt.rtp:prepend(" + json.dumps(str(ROOT)) + ")\n" + """
vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/md-render.nvim')
vim.opt.splitright = true
vim.opt.scrolloff = 0
local image = require('md-render.image')
local display = require('md-render.display_utils')
image._set_kitty_supported(true)
output, events, repaints = {}, {}, 0
vim.api.nvim_ui_send = function(data) output[#output+1] = data end
require('util.markdown_images').setup()
vim.api.nvim_create_autocmd('VimEnter', {once=true, callback=function()
  vim.schedule(function()
    source = vim.api.nvim_get_current_win()
    vim.api.nvim_buf_set_lines(0,0,-1,false,vim.fn['repeat']({'source'},120))
    vim.cmd('vnew')
    render = vim.api.nvim_get_current_win()
    vim.api.nvim_buf_set_lines(0,0,-1,false,vim.fn['repeat']({'render'},120))
    local state = display.setup_images(render,{image_placements={{line=999,rows=3}}},0)
    state.placements[1] = {line=10,col=0,rows=3,cols=5,path='fixture',img_w=100,img_h=60}
    state.image_ids.fixture = 101
    vim.api.nvim_create_autocmd('WinScrolled',{callback=function(ev)
      events[#events+1] = {match=ev.match,windows=vim.deepcopy(vim.v.event)}
    end})
    vim.api.nvim_create_autocmd('User',{pattern=display.REPAINT_EVENT,callback=function(ev)
      if ev.data.source=='split-scroll' then repaints=repaints+1 end
    end})
    vim.api.nvim_set_current_win(source)
    display.announce_repaint('test')
    ready = true
  end)
end})
""",
            encoding="utf-8",
        )
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 35, 100, 1000, 700))
        process = subprocess.Popen(
            ["nvim", "--clean", "-u", str(init), "-i", "NONE", "-n", "--listen", socket],
            stdin=slave, stdout=slave, stderr=slave, cwd=directory,
            env={**os.environ, "TERM": "xterm-kitty"},
        )
        os.close(slave)

        def drain():
            try:
                while os.read(master, 65536):
                    pass
            except OSError:
                pass

        reader = threading.Thread(target=drain, daemon=True)
        reader.start()

        def remote(code):
            expression = "luaeval(" + json.dumps("vim.json.encode((function() " + code + " end)())") + ")"
            result = subprocess.run(
                ["nvim", "--server", socket, "--remote-expr", expression],
                capture_output=True, text=True, timeout=5, check=True,
            )
            return json.loads(result.stdout)

        def wait_for(predicate, message):
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                if predicate():
                    return
                time.sleep(0.02)
            raise AssertionError(message)

        try:
            wait_for(lambda: Path(socket).exists(), "Neovim did not start")
            wait_for(lambda: remote("return ready or false"), "Preview did not initialize")
            time.sleep(0.15)  # Let the initial image redraw timer settle.
            assert remote("return table.concat(output):find('a=p',1,true) ~= nil"), "Initial image was not placed"
            remote("""
output, events, repaints = {}, {}, 0
vim.api.nvim_win_call(source,function() vim.cmd('normal! 65Gzt') end)
vim.api.nvim_win_call(render,function() vim.cmd('normal! 65Gzt') end)
return true
""")
            wait_for(lambda: remote("return repaints > 0"), "Combined split scroll did not repaint images")
            assert remote("""
for _,ev in ipairs(events) do
  if ev.match==tostring(source) and ev.windows[tostring(render)] then return true end
end
return false
"""), "Test did not produce a real source-first combined scroll event"
            assert remote("return table.concat(output):find('a=d',1,true) ~= nil"), "Off-screen placement was not cleared"
            assert remote("return table.concat(output):find('a=p',1,true) == nil"), "Off-screen image was placed"
            remote("""
output, repaints = {}, 0
vim.api.nvim_win_call(source,function() vim.cmd('normal! ggzt') end)
vim.api.nvim_win_call(render,function() vim.cmd('normal! ggzt') end)
return true
""")
            wait_for(
                lambda: remote("return repaints > 0 and table.concat(output):find('a=p',1,true) ~= nil"),
                "Scrolling back did not restore the image",
            )
            print("PASS: combined split scroll clears off-screen images and restores visible images")
        finally:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
            reader.join(timeout=1)
            os.close(master)


if __name__ == "__main__":
    main()
