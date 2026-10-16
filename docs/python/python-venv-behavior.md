# Python Venv Behavior

Current repo-local Python environment behavior.

## Goals

- Make Python environment selection predictable per project root.
- Show the active env in the UI for Python buffers.
- Keep Neovim-spawned terminals, jobs, tests, and LSP clients aligned with the
  selected env.

## Project Root

Python roots are detected from nearest project markers such as:

- `pyproject.toml`
- `setup.py`
- `setup.cfg`
- `tox.ini`
- `pytest.ini`
- `requirements.txt`

`requirements.txt`-only projects are valid Python roots.

## Environment Discovery

The config supports:

- user-selected envs via `venv-selector.nvim`
- common local envs such as `.venv` and `venv`
- managed envs under `~/.local/share/nvim/python-venvs`

The managed-env search resolves `fd`/`fdfind` at startup so discovery does not
depend on the shell `PATH` used to launch Neovim.

## Activation Semantics

`util.python_venv_picker` captures the originating Python buffer before opening
the picker. Confirmation saves the choice to that buffer and project, even if
popup activity changes the alternate buffer or the interpreter is already
active elsewhere. Selection from a non-Python buffer uses the alternate Python
buffer; if neither is available, open a Python file first. A deleted originating
buffer cancels activation rather than redirecting it to another project.

When a venv is activated:

- `VIRTUAL_ENV` is updated.
- the env `bin` directory is prepended to `PATH` for future jobs.
- `${project_root}/.env` is loaded into Neovim's process environment if present.
- Python LSP clients are restarted so Pyright sees the selected interpreter.
- Existing terminal buffers are not force-reinitialized.

The `.env` loader preserves the inherited `PATH` (including the selected venv)
and appends unique directories from `.env`'s `PATH`. `$PATH` and `${PATH}` are
expanded in that entry only. Other variables use the simple literal parser;
general variable interpolation and inline comment stripping are not supported.
On the next activation, previously loaded variables are restored to their
original values if they have not since changed, and added PATH directories are
removed before loading the next project's `.env`.
The selected interpreter's bin directory is then explicitly placed first, even
when that directory was previously added by `.env`. CLI scripts using
`#!/usr/bin/env python3` therefore use the same environment as Python tests.

Neotest's Go adapter checks for a `_test.go` filename and an executable `go`
before calling upstream discovery, so Python test discovery works without Go.

## Commands And Keys

| Key          | Command / Action                                     |
|--------------|------------------------------------------------------|
| `<leader>ps` | select env                                           |
| `<leader>pe` | show loaded .env path, variables, and effective PATH |
| `<leader>pc` | create env                                           |
| `<leader>pr` | recreate env                                         |
| `<leader>pi` | install default deps                                 |
| `<leader>pI` | prompt for custom `pip install ...` args             |

Commands:

- `:PythonVenvSelect`
- `:PythonVenvCreate [name] [python]`
- `:PythonVenvRecreate [name] [python]`
- `:PythonVenvInstall [pip args]`

Relevant files:

- [lua/plugins/python-venv.lua](/home/konkov/.config/nvim/lua/plugins/python-venv.lua:1)
- [lua/util/python_venv.lua](/home/konkov/.config/nvim/lua/util/python_venv.lua:1)
