# asdf-workmux

[workmux](https://github.com/raine/workmux) plugin for [asdf](https://asdf-vm.com/) version manager.

## Dependencies

- `bash`, `curl`, `tar`: standard POSIX tools
- `git`: required by asdf v0.18.0+ for plugin installation

## Install

```bash
asdf plugin add workmux https://github.com/CoolCold/asdf-workmux.git
```

## Usage

```bash
# List all versions
asdf list all workmux

# Install latest
asdf install workmux latest

# Install specific version
asdf install workmux 0.1.113

# Set global version
asdf set -u workmux 0.1.113

# Verify
workmux --version
```

## Supported Platforms

- Linux: `amd64`, `arm64`
- macOS: `amd64`, `arm64`

## Testing

Tests run in LXD containers (Linux only):

```bash
make test      # Run tests
make clean     # Clean up containers
make reset-test # Recreate base container
```

See [tests/README.md](tests/README.md) for details.

## License

MIT

## Development

### Lint

```bash
./scripts/lint.bash
```

### Format

```bash
./scripts/format.bash
```

### Test

```bash
asdf plugin test workmux . 'workmux --version'
```

Or use LXD containers:

```bash
make test
```
