.PHONY: test

test:
	nvim --headless -c "luafile tests/core_test.lua" -c "qa"
