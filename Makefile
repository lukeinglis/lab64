.PHONY: test test-bash test-python lint check pre-commit-install

BATS := test/libs/bats-core/bin/bats
SHELL_SCRIPTS := $(wildcard tools/*.sh)

test: test-bash test-python

test-bash: $(BATS)
	$(BATS) test/

test-python:
	python3 -m pytest test/ -v

lint:
	pre-commit run --all-files

check:
	shellcheck $(SHELL_SCRIPTS)

pre-commit-install:
	pip install pre-commit
	pre-commit install

$(BATS):
	@echo "bats-core not found. Run: git submodule update --init --recursive"
	@exit 1
