.PHONY: test test-verbose clean help reset-test

# Default target
.PHONY: default
default: help

# Run LXD tests
test:
	@echo "Running LXD tests..."
	cd tests && bash test-plugin.sh

# Run LXD tests with verbose output (bash -x)
test-verbose:
	@echo "Running LXD tests with verbose output..."
	cd tests && bash -x test-plugin.sh 2>&1

# Reset test base container (force recreation)
reset-test:
	@echo "Resetting test base container..."
	cd tests && bash test-plugin.sh --reset

# Clean up all test containers and base container
clean:
	@echo "Cleaning up LXD containers..."
	@-lxc delete asdf-workmux-base --force 2>/dev/null || true
	@-lxc list --format csv 2>/dev/null | grep test-workmux | cut -d, -f1 | xargs -r -I {} lxc delete {} --force 2>/dev/null || true
	@echo "Cleanup complete"

# Show help
help:
	@echo "Available targets:"
	@echo "  make test         - Run LXD tests for the plugin"
	@echo "  make test-verbose - Run LXD tests with bash -x debug output"
	@echo "  make reset-test   - Reset test base container (force recreation)"
	@echo "  make clean        - Clean up all LXD test containers"
	@echo "  make help         - Show this help message"
