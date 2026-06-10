.PHONY: build up down logs test-md test-yaml test-bdd test-links test help

ifeq ($(OS),Windows_NT)
    CURR_DIR := $(shell cd .; cmd /c echo %CD%)
else
    CURR_DIR := $(shell pwd)
endif

build:
	@echo "Installing npm dependencies for documentation server..."
	@if [ ! -d "node_modules" ]; then npm install; else echo "npm dependencies already installed"; fi
	@echo "Installing markdownlint-cli2 locally..."
	npm install markdownlint-cli2 --save-dev
	@echo "Installing cucumber-js locally..."
	npm install @cucumber/cucumber --save-dev
	@echo "Pulling Lychee Docker image..."
	docker pull lycheeverse/lychee:latest
	@echo "Installing yamllint..."
	@if command -v apt-get > /dev/null; then sudo apt-get update && sudo apt-get install -y yamllint; \
	elif command -v brew > /dev/null; then brew install yamllint; \
	else echo "Please install yamllint manually"; fi
	@echo "Building Docker image for documentation..."
	$(MAKE) -C deploy/docs/local build
	@echo "Build completed."

up:
	$(MAKE) -C deploy/docs/local up

down:
	$(MAKE) -C deploy/docs/local down

logs:
	$(MAKE) -C deploy/docs/local logs

test-md:
	npx markdownlint-cli2 "docs/**/*.md" --config .markdownlint.json

test-yaml:
	@echo "Running YAML linting on docs/..."
	@yamllint -c .yamllint.yaml docs/ && echo "✅ All YAML files passed validation"

test-bdd:
	@echo "Checking BDD feature files syntax..."
	@output=$$(npx cucumber-js --config cucumber.js --format json 2>&1); \
	if echo "$$output" | grep -qi "syntax error"; then \
		echo "❌ Syntax error found"; \
		echo "$$output"; \
		exit 1; \
	else \
		echo "✅ All feature files are valid"; \
	fi

test-links:
	docker run --rm -v "$(CURR_DIR):/input" lycheeverse/lychee:latest \
    		--config /input/lychee.toml \
    		/input/docs /input/*.md

test: test-md test-yaml test-bdd test-links
	@echo "All validations passed."

help:
	@echo "Available targets:"
	@echo ""
	@echo "Setup:"
	@echo "  build        - Install all tools, dependencies, and build Docker image"
	@echo ""
	@echo "Local docs deployment:"
	@echo "  up           - Start documentation locally at http://localhost:8000"
	@echo "  down         - Stop documentation container"
	@echo "  logs         - View container logs"
	@echo ""
	@echo "Validations:"
	@echo "  test-md      - Lint Markdown files"
	@echo "  test-yaml    - Validate YAML files"
	@echo "  test-bdd     - Check Gherkin syntax"
	@echo "  test-links   - Check links with Lychee (Docker)"
	@echo "  test         - Run all validations"