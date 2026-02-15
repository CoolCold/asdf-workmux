# Agents Documentation

This file contains information for AI agents working on the asdf-workmux plugin.

## Repository Structure

```
asdf-plugin-workmux/
├── bin/                    # Plugin executables (list-all, install, etc.)
├── lib/                    # Shared utilities
├── tests/                  # Testing scripts and documentation
│   ├── test-plugin.sh     # Main test script using LXD
│   └── README.md          # Testing documentation
└── AGENTS.md              # This file
```

## Testing with LXD

**Primary testing method:** LXD containers with Ubuntu Noble (24.04)

See [tests/README.md](tests/README.md) for detailed testing information.

**Quick test:**
```bash
cd tests
bash test-plugin.sh
```

### LXD File Transfer Best Practices

**Key Findings from Testing:**
1. **Directory vs Contents:** `lxc file push -p --recursive "$REPO_ROOT" "$CONTAINER/tmp/plugin"` creates `/tmp/plugin/asdf-plugin-workmux/` (nested structure). To push contents directly, use `.` or `/.` suffix.
2. **Container Readiness:** After `lxc start`, wait for container to be ready (5+ seconds, verify with `lxc exec` test command).
3. **Trailing Slashes:** Destination trailing slash matters when pushing directory contents.
4. **Essential Directories:** Only `bin/` (plugin callbacks) and `tests/` (testing scripts) need to be pushed. Exclude `.git`, `.opencode`, `.tmp` directories.

**Recommended Approach (single, proven method):**

```bash
# Create target directory first
lxc exec "$CONTAINER" -- mkdir -p /tmp/plugin

# Push only essential directories individually
for dir in bin tests; do
    lxc file push --recursive "$REPO_ROOT/$dir" "$CONTAINER/tmp/plugin/"
done
```

**Wait for Container Readiness:**
```bash
lxc start "$CONTAINER"
# Wait for container to be fully ready
local max_attempts=30
local attempt=1
while [ $attempt -le $max_attempts ]; do
    if lxc exec "$CONTAINER" -- bash -c "echo 'ready'" >/dev/null 2>&1; then
        break
    fi
    sleep 1
    attempt=$((attempt + 1))
done
sleep 2  # Extra safety margin
```

**Common Pitfalls:**
- Missing trailing slash when pushing directory contents
- Not waiting for container readiness after `lxc start`
- Pushing directory instead of its contents (creates nested structure)

### Git Ownership Issues

**Problem:** Git complains about "dubious ownership" when running as testuser in container.

**Solution:** Add safe directory before git operations:
```bash
lxc exec "$CONTAINER" -- su - testuser -c "
    git config --global --add safe.directory /tmp/plugin
    cd /tmp/plugin
    git init
    # ... other git operations
"
```

## Bash Script Conventions

**All bash scripts use `set -euo pipefail` for safety:**

- `set -e` (errexit): Exit immediately on command failure
- `set -u` (nounset): Treat unset variables as errors
- `set -o pipefail`: Pipeline failure propagates to exit code

**Always use `${VAR:-}` syntax for optional environment variables:**

```bash
# Wrong - fails with unbound variable error when VAR not set
if [ -n "$GITHUB_API_TOKEN" ]; then

# Correct - handles unset variables gracefully
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
```

**Scripts requiring specific environment variables should validate them:**

```bash
[ -n "${ASDF_INSTALL_VERSION:-}" ] || (>&2 echo 'Missing ASDF_INSTALL_VERSION' && exit 1)
```

**Applied to all plugin scripts:**
- `bin/download`
- `bin/install`
- `bin/latest-stable`
- `bin/list-all`
- `tests/test-plugin.sh`
- `tests/run-test.sh`

## Installing ASDF for Testing

The test script installs asdf v0.18.0 automatically. For manual testing:

```bash
# Install asdf binary
mkdir -p ~/.local/bin
curl -sL https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz -o .tmp/asdf.tar.gz
tar -xzf .tmp/asdf.tar.gz -C ~/.local/bin asdf
rm .tmp/asdf.tar.gz

# Setup PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# Verify
asdf version
```

## Adding Plugin Locally

```bash
# Add plugin from local path
asdf plugin add workmux /path/to/asdf-plugin-workmux

# List available versions
asdf list-all workmux

# Install a version
asdf install workmux <version>

# Set version globally
asdf set -u workmux <version>
```

## Testing Scope

### What We Test

We test only on **Linux (Ubuntu 24.04)** using LXD containers. This is sufficient because:

1. **Plugin is a simple wrapper** - It just downloads pre-built binaries from GitHub releases
2. **Workmux is already tested** - We're not testing workmux itself, only that our plugin can download it
3. **LXD with snapshots is fast** - Restoring a snapshot takes seconds vs minutes for CI runners
4. **Platform-independent logic** - The plugin uses standard POSIX tools (curl, tar, grep)

### What We Skip

**macOS Testing** - Skipped because:
- Plugin logic is identical across platforms (only download URL changes)
- Testing locally on macOS is sufficient if needed
- We trust the platform detection logic (`uname -m`, `uname -s`)

**GitHub Actions CI** - Skipped because:
- LXD with snapshots is faster for local development
- Plugin is trivial (2 scripts, ~80 lines total)
- No complex logic to break on different OS versions
- We don't develop workmux itself, just a download wrapper

## Important Notes

- **Always test in LXD container** before committing changes
- **asdf v0.18.0** uses binary-based installation (not git clone)
- Plugin scripts must be executable (`chmod +x bin/*`)

## Makefile Commands

The repository includes a Makefile for convenient test management:

```bash
make test           # Run LXD tests for the plugin
make test-verbose   # Run LXD tests with bash -x debug output
make reset-test     # Reset test base container (force recreation)
make clean          # Clean up all LXD test containers
make help           # Show help message
```

**Implementation notes:**
- `make clean` uses `lxc list --format csv` for reliable container name extraction
- Container names are filtered with `grep test-workmux` to target test containers only
- Base container `asdf-workmux-base` is deleted separately
- `-` prefix on commands prevents failures if containers don't exist
- `|| true` ensures cleanup continues even if commands fail

## References

- [asdf Documentation](https://asdf-vm.com/)
- [asdf Plugin Authoring Guide](https://asdf-vm.com/plugins/create.html)
- [LXD Documentation](https://documentation.ubuntu.com/lxd/en/latest/)
