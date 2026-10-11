.PHONY: check check-format check-lint check-config check-compatibility format

MASON_BIN ?= $(HOME)/.local/share/nvim/mason/bin
STYLUA ?= $(MASON_BIN)/stylua
SELENE ?= $(MASON_BIN)/selene
NVIM_BIN ?= nvim
LUA_TARGETS := init.lua lua after tests

check: check-format check-lint check-config

check-format:
	$(STYLUA) --check $(LUA_TARGETS)

check-lint:
	$(SELENE) $(LUA_TARGETS)

check-config: check-compatibility
	$(NVIM_BIN) --headless -u NONE -i NONE -l tests/config_refinement.lua DiffviewOpen
	$(NVIM_BIN) --headless -u NONE -i NONE -l tests/neotest_scope.lua
	$(NVIM_BIN) --headless -u NONE -i NONE -l tests/root_policy.lua
	$(NVIM_BIN) --headless -u NONE -i NONE -l tests/lsp_rename.lua
	$(NVIM_BIN) --headless -u NONE -i NONE -l tests/session_scrub.lua
	$(NVIM_BIN) --headless -u NONE -i NONE -l tests/live_hunks.lua
	$(NVIM_BIN) --headless -u NONE -i NONE -l tests/lazy_bootstrap.lua
	$(NVIM_BIN) --headless -u NONE -i NONE -l tests/portability.lua
	$(NVIM_BIN) --headless -u NONE -i NONE -l tests/format_dir.lua

check-compatibility:
	$(NVIM_BIN) --headless -u NONE -i NONE -l tests/compatibility.lua

format:
	$(STYLUA) $(LUA_TARGETS)
