"""Isolated, evidence-preserving Neovim MCP harness for interactive checks."""

import asyncio
import contextlib
import fcntl
import json
import os
from pathlib import Path
import pty
import shutil
import signal
import struct
import subprocess
import tempfile
import termios
import threading
import time

from mcp.client import ClientSession
from mcp.client.stdio import StdioServerParameters, stdio_client

REPO = Path(__file__).resolve().parents[2]


class MCPError(RuntimeError):
    """The editor rejected an operation; this is distinct from missing prerequisites."""


class Audit:
    """Run a dedicated editor and MCP server; retain all evidence on exit."""

    def __init__(self, name, output_dir=None):
        safe_name = "".join(c if c.isalnum() or c in "-_" else "_" for c in name)
        if not safe_name:
            raise ValueError("Audit name must contain at least one character")
        if output_dir is None:
            self.base = Path(tempfile.mkdtemp(prefix=f"nvim-e2e-{safe_name}-"))
        else:
            parent = Path(output_dir).expanduser().resolve()
            parent.mkdir(parents=True, exist_ok=True)
            self.base = Path(tempfile.mkdtemp(prefix=f"{safe_name}-", dir=parent))
        self.project = self.base / "project"
        self.project.mkdir()
        self.log = (self.base / "mcp.jsonl").open("a", encoding="utf-8")
        self.stack = contextlib.AsyncExitStack()
        self.proc = None
        self.master = None
        self.drainer = None
        self.session = None

    async def __aenter__(self):
        try:
            await self._start()
            return self
        except BaseException:
            await self._cleanup()
            raise

    async def _start(self):
        nvim = shutil.which("nvim")
        mcp = shutil.which("nvim-mcp")
        if not nvim or not mcp:
            raise RuntimeError("nvim and nvim-mcp must both be available on PATH")
        original_data = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share") / "nvim"
        original_cache = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "nvim"
        if not (original_data / "lazy/lazy.nvim").is_dir():
            raise RuntimeError(f"Installed lazy.nvim not found in {original_data}; refusing to install plugins")
        env = os.environ.copy()
        for key, folder in (("XDG_DATA_HOME", "data"), ("XDG_STATE_HOME", "state"), ("XDG_CACHE_HOME", "cache")):
            env[key] = str(self.base / folder)
            (self.base / folder / "nvim").mkdir(parents=True)
        data = self.base / "data/nvim"
        for item in ("lazy", "mason", "site"):
            source = original_data / item
            if source.exists():
                (data / item).symlink_to(source, target_is_directory=True)
        test_jars = original_data / "neotest-java"
        if test_jars.is_dir():
            jar_target = data / "neotest-java"
            jar_target.mkdir()
            for jar in test_jars.glob("*.jar"):
                (jar_target / jar.name).symlink_to(jar)
        java_source = original_data / "intellij-lsp"
        if java_source.is_dir():
            target = data / "intellij-lsp"
            target.mkdir()
            for item in java_source.iterdir():
                if item.is_dir():
                    (target / item.name).symlink_to(item, target_is_directory=True)
                else:
                    shutil.copy2(item, target / item.name)
        java_cache = original_cache / "intellij-lsp"
        cache_target = self.base / "cache/nvim/intellij-lsp"
        cache_target.mkdir()
        if java_cache.is_dir():
            for item in java_cache.iterdir():
                if item.name.startswith(("server", "bundle")):
                    (cache_target / item.name).symlink_to(item, target_is_directory=item.is_dir())
        env["HISTFILE"] = str(self.base / "shell_history")
        # Disable automatic plugin/tool installation while preserving normal plugin setup.
        bootstrap = self.base / "bootstrap.lua"
        self.editor_pid_file = self.base / "editor.pid"
        bootstrap.write_text(
                "vim.fn.writefile({ tostring(vim.fn.getpid()) }, " + json.dumps(str(self.editor_pid_file)) + ")\n"
                                                                                                             "vim.opt.rtp:prepend(" + json.dumps(str(REPO)) + ")\n"
                                                                                                                                                              "vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/lazy.nvim')\n"
                                                                                                                                                              "local lazy = require('lazy')\n"
                                                                                                                                                              "local setup = lazy.setup\n"
                                                                                                                                                              "lazy.setup = function(opts)\n"
                                                                                                                                                              "  opts.install = opts.install or {}\n"
                                                                                                                                                              "  opts.install.missing = false\n"
                                                                                                                                                              "  table.insert(opts.spec, { 'WhoIsSethDaniel/mason-tool-installer.nvim', "
                                                                                                                                                              "opts = { run_on_start = false, auto_update = false } })\n"
                                                                                                                                                              "  return setup(opts)\n"
                                                                                                                                                              "end\n",
                encoding="utf-8",
        )
        self.socket = str(self.base / "nvim.sock")
        if len(os.fsencode(self.socket)) >= 104:
            raise ValueError(f"Socket path is too long: {self.socket}")
        self.master, slave = pty.openpty()
        try:
            fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 48, 160, 0, 0))
            self.proc = subprocess.Popen(
                    [nvim, "--cmd", "lua dofile(" + json.dumps(str(bootstrap)) + ")", "-u", str(REPO / "init.lua"), "--listen", self.socket, "-i", "NONE",
                     "-n"],
                    cwd=self.project,
                    env=env,
                    stdin=slave,
                    stdout=slave,
                    stderr=slave,
                    start_new_session=True,
            )
        finally:
            os.close(slave)
        self.drainer = threading.Thread(target=self._drain, daemon=True)
        self.drainer.start()
        for _ in range(100):
            if Path(self.socket).exists():
                break
            if self.proc.poll() is not None:
                raise RuntimeError(f"Neovim exited during startup ({self.proc.returncode}); see {self.base / 'terminal.log'}")
            await asyncio.sleep(0.1)
        else:
            raise TimeoutError(f"Neovim socket did not appear: {self.socket}; see {self.base / 'terminal.log'}")
        streams = await self.stack.enter_async_context(stdio_client(StdioServerParameters(command=mcp)))
        self.session = await self.stack.enter_async_context(ClientSession(*streams))
        await self.session.initialize()
        await self.call("connect", socket_path=self.socket)
        await asyncio.sleep(2)
        await self.state()
        await self.cmd(
                "lua _G.audit_notifications = {}; local ok, manager = pcall(require, 'noice.message.manager'); "
                "if ok then local old = manager.add; manager.add = function(message) "
                "if message.event == 'notify' then table.insert(_G.audit_notifications, "
                "{msg = message:content(), level = message.level}) end; return old(message) end end"
        )

    def _drain(self):
        with (self.base / "terminal.log").open("wb") as output:
            while True:
                try:
                    chunk = os.read(self.master, 65536)
                except OSError:
                    break
                if not chunk:
                    break
                output.write(chunk)
                output.flush()

    async def call(self, name, **args):
        result = await self.session.call_tool(name, args, read_timeout_seconds=30)
        data = result.model_dump(mode="json")
        self.log.write(json.dumps({"time": time.time(), "tool": name, "args": args, "result": data}, ensure_ascii=False) + "\n")
        self.log.flush()
        if result.is_error:
            raise MCPError(f"MCP {name} failed: {data}")
        structured = result.structured_content
        if isinstance(structured, dict):
            payload = structured.get("result", structured)
        else:
            text = "\n".join(item.text for item in result.content if item.type == "text")
            try:
                payload = json.loads(text)
            except json.JSONDecodeError:
                raise RuntimeError(f"MCP {name} returned non-JSON: {text}") from None
        if not isinstance(payload, dict):
            raise RuntimeError(f"MCP {name} returned unexpected payload: {payload!r}")
        if payload.get("error"):
            raise MCPError(f"MCP {name} failed: {payload['error']}")
        return payload

    async def cmd(self, command):
        # nvim-mcp 1.1.1 treats any v:errmsg as failure, including successful
        # upstream `silent!` cleanup. Preserve those diagnostics without turning
        # them into product defects; actual thrown errors still fail the case.
        wrapped = (
                "lua local ok,result=pcall(vim.api.nvim_exec2,"
                + json.dumps(command, ensure_ascii=False)
                + ",{output=true}); local diagnostic=vim.v.errmsg; vim.v.errmsg=''; "
                  "print(vim.json.encode({ok=ok,output=ok and result.output or tostring(result),"
                  "suppressed_error=ok and diagnostic or nil})); vim.v.errmsg=''"
        )
        envelope = await self.call("send_command", command=wrapped)
        try:
            payload = json.loads(envelope["output"])
        except (KeyError, TypeError, json.JSONDecodeError) as exc:
            raise MCPError(f"Could not decode editor command: {envelope!r}") from exc
        if not payload["ok"]:
            raise MCPError(payload["output"])
        return payload

    async def keys(self, keys, delay=0.4):
        result = await self.call("send_keys", keys=keys)
        await asyncio.sleep(delay)
        return result

    async def raw(self, keys, delay=0.4):
        result = await self.cmd("lua vim.api.nvim_input(" + json.dumps(keys, ensure_ascii=False) + ")")
        await asyncio.sleep(delay)
        return result

    async def state(self):
        return await self.call("get_state")

    async def lua(self, expr):
        result = await self.cmd("lua print(vim.json.encode(" + expr + "))")
        try:
            return json.loads(result["output"])
        except (KeyError, TypeError, json.JSONDecodeError) as exc:
            raise RuntimeError(f"Could not decode Lua result: {result!r}") from exc

    async def reset(self, file="main.lua"):
        path = (self.project / file).resolve()
        if not path.is_relative_to(self.project):
            raise ValueError("Reset file must be inside the disposable project")
        path.parent.mkdir(parents=True, exist_ok=True)
        await self.keys("<Esc>")
        await self.cmd("silent! tabonly! | silent! only!")
        await self.cmd("execute 'edit! ' .. fnameescape(" + json.dumps(str(path)) + ")")
        await asyncio.sleep(0.2)

    async def wait_for(self, expr, timeout=10, interval=0.1):
        deadline = time.monotonic() + timeout
        while True:
            value = await self.lua(expr)
            if value:
                return value
            if time.monotonic() >= deadline:
                raise TimeoutError(f"Timed out waiting for Lua expression: {expr}")
            await asyncio.sleep(interval)

    async def _cleanup(self):
        if self.session is not None:
            try:
                await self.cmd('lua vim.schedule(function() vim.cmd("qa!") end)')
            except Exception:
                pass
        try:
            await self.stack.aclose()
        finally:
            if self.proc is not None:
                # The wrapper and editor share this private process group.
                with contextlib.suppress(ProcessLookupError):
                    os.killpg(self.proc.pid, signal.SIGTERM)
                try:
                    await asyncio.to_thread(self.proc.wait, timeout=3)
                except subprocess.TimeoutExpired:
                    with contextlib.suppress(ProcessLookupError):
                        os.killpg(self.proc.pid, signal.SIGKILL)
                    await asyncio.to_thread(self.proc.wait)
            # Neovim can spawn an embedded editor in a separate session. Only
            # signal the PID recorded by our bootstrap when its environment
            # still identifies this isolated run.
            pid_file = getattr(self, "editor_pid_file", None)
            if pid_file and pid_file.exists():
                with contextlib.suppress(ValueError, OSError):
                    editor_pid = int(pid_file.read_text().strip())
                    environ = Path(f"/proc/{editor_pid}/environ").read_bytes().split(b"\0")
                    marker = os.fsencode("XDG_STATE_HOME=" + str(self.base / "state"))
                    if marker in environ:
                        os.kill(editor_pid, signal.SIGTERM)
            if self.master is not None:
                with contextlib.suppress(OSError):
                    os.close(self.master)
                self.master = None
            if self.drainer is not None:
                await asyncio.to_thread(self.drainer.join, 3)
            self.log.close()

    async def __aexit__(self, *exc):
        await self._cleanup()
