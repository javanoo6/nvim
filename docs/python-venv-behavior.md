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

When a venv is activated:

- `VIRTUAL_ENV` is updated.
- the env `bin` directory is prepended to `PATH` for future jobs.
- `${project_root}/.env` is loaded into Neovim's process environment if present.
- Python LSP clients are restarted so Pyright sees the selected interpreter.
- Existing terminal buffers are not force-reinitialized.

## Commands And Keys

| Key          | Command / Action                         |
|--------------|------------------------------------------|
| `<leader>ps` | select env                               |
| `<leader>pc` | create env                               |
| `<leader>pr` | recreate env                             |
| `<leader>pi` | install default deps                     |
| `<leader>pI` | prompt for custom `pip install ...` args |

Commands:

- `:PythonVenvSelect`
- `:PythonVenvCreate [name] [python]`
- `:PythonVenvRecreate [name] [python]`
- `:PythonVenvInstall [pip args]`

Relevant files:

- [lua/plugins/python-venv.lua](/home/konkov/.config/nvim/lua/plugins/python-venv.lua:1)
- [lua/util/python_venv.lua](/home/konkov/.config/nvim/lua/util/python_venv.lua:1)
