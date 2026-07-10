.PHONY: test test-bash test-python lint check validate doctor pack typecheck help pre-commit-install

BATS := test/libs/bats-core/bin/bats
SHELL_SCRIPTS := $(wildcard tools/*.sh)

help: ## Show all available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

test: test-bash test-python ## Run all tests (Bats + pytest)

test-bash: $(BATS) ## Run Bats tests only
	$(BATS) test/

test-python: ## Run pytest only
	python3 -m pytest test/ -v

lint: ## Run all linters via pre-commit
	pre-commit run --all-files

check: ## Run ShellCheck on all bash scripts
	shellcheck $(SHELL_SCRIPTS)

typecheck: ## Run mypy type checking
	python3 -m mypy tools/ eval/

validate: ## Validate mod archives (placeholder)
	tools/validate-mod.sh --help

pack: ## Pack all character mods (or show help)
	@chars=$$(find assets/characters -mindepth 1 -maxdepth 1 -type d 2>/dev/null); \
	if [ -z "$$chars" ]; then \
		echo "No characters found in assets/characters/. Run 'tools/lab64 pack --help' for usage."; \
		tools/lab64 pack --help; \
	else \
		for dir in $$chars; do \
			name=$$(basename "$$dir"); \
			echo "Packing $$name..."; \
			tools/lab64 pack "$$name" "$$dir/sprites"; \
		done; \
	fi

doctor: ## Check all dependencies
	tools/lab64 doctor

pre-commit-install: ## Install pre-commit hooks
	pip install pre-commit
	pre-commit install

$(BATS):
	@echo "bats-core not found. Run: git submodule update --init --recursive"
	@exit 1
