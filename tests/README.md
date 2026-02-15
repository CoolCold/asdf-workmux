# Testing asdf-workmux Plugin

This directory contains tests for the asdf-workmux plugin using LXD containers with snapshots for fast iteration.

## Prerequisites

- LXD installed and initialized (`lxd init`)
- Ubuntu image available (`lxc image list`)

## Running Tests

```bash
cd tests
bash test-plugin.sh
```

## How It Works (Snapshots for Speed)

The test script uses LXD snapshots to avoid reinstalling asdf every time:

1. **First run**: Creates a base container with asdf v0.18.0 installed
2. **Takes snapshot**: Saves the state as "asdf-installed"
3. **Subsequent runs**: Restores from snapshot in seconds instead of minutes

### LXD File Transfer Best Practices

The test script pushes only essential directories to the container:
- `bin/` – plugin callback scripts (required)
- `tests/` – testing scripts (optional, for testing only)

Exclude unnecessary directories: `.git`, `.opencode`, `.tmp`.

For detailed LXD file transfer patterns and common pitfalls, see [AGENTS.md](../AGENTS.md#lxd-file-transfer-best-practices).

### Base Container Management

The base container `asdf-workmux-base` is preserved between runs:

```bash
# List snapshots
lxc info asdf-workmux-base

# Reset base container (force recreation)
bash test-plugin.sh --reset

# Delete base container manually
lxc delete asdf-workmux-base --force
```

## What the Test Does

1. Restores container from snapshot (fast!)
2. Pushes `bin/` and `tests/` directories to container
3. Makes scripts executable and initializes git repository
4. Adds workmux plugin to asdf using local file path
5. Lists available versions, installs latest, sets global version
6. Verifies workmux binary works

## Troubleshooting

### Permission denied
```bash
sudo usermod -aG lxd $USER
# Log out and back in
```

### Reset everything
```bash
# Delete base container and test containers
lxc delete asdf-workmux-base --force 2>/dev/null || true
lxc list | grep test-workmux | awk '{print $2}' | xargs -I {} lxc delete {} --force 2>/dev/null || true
```

## LXD Snapshot Commands Reference

```bash
# Create snapshot
lxc snapshot <container> <snapshot-name>

# Restore snapshot
lxc restore <container> <snapshot-name>

# Copy snapshot to new container
lxc copy <container>/<snapshot-name> <new-container>

# List snapshots
lxc info <container>

# Delete snapshot
lxc delete <container>/<snapshot-name>
```
