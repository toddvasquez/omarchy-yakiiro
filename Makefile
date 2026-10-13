.PHONY: all graphics check

all: graphics check

graphics:
	bash scripts/render_graphics.sh

check:
	bash scripts/check.sh
