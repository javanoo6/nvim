.PHONY: check check-format check-lint format test-toggles

MASON_BIN ?= $(HOME)/.local/share/nvim/mason/bin
STYLUA ?= $(MASON_BIN)/stylua
SELENE ?= $(MASON_BIN)/selene
LUA_TARGETS := init.lua lua ftplugin

check: check-format check-lint

check-format:
	$(STYLUA) --check $(LUA_TARGETS)

check-lint:
	$(SELENE) $(LUA_TARGETS)

format:
	$(STYLUA) $(LUA_TARGETS)

test-toggles:
	sh scripts/test-toggle-preferences.sh
