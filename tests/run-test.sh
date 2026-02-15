#!/bin/bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

echo "* Adding workmux plugin"
asdf plugin add workmux "file:///tmp/plugin"
echo "  ✓ Plugin added"

echo "* Plugin structure"
tree ~/.asdf/plugins/workmux/

echo "* Listing versions"
asdf list all workmux | tail -5

echo "* Getting latest"
latest_version=$(asdf latest workmux)
echo "  Latest: $latest_version"

echo "* Installing workmux"
asdf install workmux "$latest_version"
echo "  ✓ Installed"

echo "* Setting global"
asdf set -u workmux "$latest_version"

echo "* Verifying commands"
command -v asdf
command -v workmux

echo "* Testing binary"
workmux --version
echo "  ✓ Binary works"
