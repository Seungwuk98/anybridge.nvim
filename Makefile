.PHONY: test lint clean

test:
	nvim --headless -u tests/init.lua -c "qa"

lint:
	luacheck lua/

clean:
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -delete
