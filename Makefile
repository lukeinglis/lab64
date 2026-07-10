.PHONY: test test-bash test-python lint check

BATS := test/libs/bats-core/bin/bats
SHELL_SCRIPTS := $(wildcard tools/*.sh)

test: test-bash test-python

test-bash: $(BATS)
	$(BATS) test/

test-python:
	python3 -m pytest test/ -v

lint: check

check:
	shellcheck $(SHELL_SCRIPTS)

$(BATS):
	@echo "bats-core not found. Run: git submodule update --init --recursive"
	@exit 1
