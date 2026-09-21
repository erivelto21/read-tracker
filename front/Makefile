.PHONY: all install dev build preview \
        test test-coverage test-e2e \
        lint fmt type-check \
        clean help

# ── Default ────────────────────────────────────────────────────────────────────
all: install lint type-check test

# ── Dependencies ───────────────────────────────────────────────────────────────
## install: install npm dependencies
install:
	npm install

# ── Development ────────────────────────────────────────────────────────────────
## dev: start the Vite dev server with HMR
dev:
	npm run dev

# ── Build ──────────────────────────────────────────────────────────────────────
## build: compile TypeScript and bundle with Vite
build:
	npm run build

# ── Tests ──────────────────────────────────────────────────────────────────────
## test: run unit/integration tests with Vitest
test:
	npm test -- --run

## test-coverage: run tests with coverage report
test-coverage:
	npm run test:coverage

## test-e2e: run Playwright end-to-end tests
test-e2e:
	npm run test:e2e

# ── Quality ────────────────────────────────────────────────────────────────────
## lint: run ESLint
lint:
	npm run lint

## fmt: format code with Prettier
fmt:
	npm run fmt

## type-check: run TypeScript type-checker without emitting files
type-check:
	npm run type-check

# ── Help ───────────────────────────────────────────────────────────────────────
## help: list available targets
help:
	@grep -E '^## ' Makefile | sed 's/## /  /'
