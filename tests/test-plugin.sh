#!/bin/bash
# Test script for asdf-workmux plugin using LXD snapshots for speed
# Creates a base container with asdf, then restores from snapshot for each test

set -euo pipefail
# Ignore SIGPIPE (broken pipe) to prevent exit when piping to commands that exit early
trap '' PIPE

BASE_CONTAINER="asdf-workmux-base"
SNAPSHOT_NAME="asdf-installed"
TEST_CONTAINER="test-workmux-$(date +%s)"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
REPO_ROOT="$(realpath "$SCRIPT_DIR/..")"

setup_base_container() {
    if lxc info "$BASE_CONTAINER" &>/dev/null && lxc info "$BASE_CONTAINER" | grep -q "$SNAPSHOT_NAME"; then
        return 0
    fi
    
    echo "Creating base container..."
    lxc delete "$BASE_CONTAINER" --force 2>/dev/null || true
    lxc launch ubuntu:noble "$BASE_CONTAINER"
    sleep 5
    
    lxc exec "$BASE_CONTAINER" -- bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq sudo curl git tree
        useradd -m -s /bin/bash -G sudo testuser
        echo 'testuser:testpass' | chpasswd
        echo 'testuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/testuser
    " >/dev/null 2>&1
    
    lxc exec "$BASE_CONTAINER" -- su - testuser -c "
        mkdir -p ~/.local/bin
        curl -sL https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz -o /tmp/asdf.tar.gz
        tar -xzf /tmp/asdf.tar.gz -C ~/.local/bin asdf
        rm /tmp/asdf.tar.gz
    " >/dev/null 2>&1
    
    lxc snapshot "$BASE_CONTAINER" "$SNAPSHOT_NAME" >/dev/null 2>&1
}

# Restore from snapshot for testing
restore_container() {
    lxc copy "$BASE_CONTAINER/$SNAPSHOT_NAME" "$TEST_CONTAINER" >/dev/null 2>&1
    lxc start "$TEST_CONTAINER" >/dev/null 2>&1
    
    local max_attempts=30
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if lxc exec "$TEST_CONTAINER" -- bash -c "echo 'ready'" >/dev/null 2>&1; then
            break
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    sleep 2
}

# Cleanup test container only (keep base)
cleanup_test() {
    echo ""
    echo "=== Cleaning up test container ==="
    lxc stop "$TEST_CONTAINER" 2>/dev/null || true
    lxc delete "$TEST_CONTAINER" 2>/dev/null || true
    echo "Cleanup complete (base container preserved)"
}

# Main test logic
main() {
    echo "Test container: $TEST_CONTAINER"
    echo ""
    echo "=== ASDF container preparation ==="
    
    trap cleanup_test EXIT
    setup_base_container
    restore_container
    
    # Push plugin files
    echo "=== ASDF inside container ==="
    lxc exec "$TEST_CONTAINER" -- mkdir -p /tmp/plugin
    for dir in bin lib tests; do
        if ! lxc file push --recursive "$REPO_ROOT/$dir" "$TEST_CONTAINER/tmp/plugin/" >/dev/null 2>&1; then
            echo "ERROR: Failed to push $dir directory"
            exit 1
        fi
    done
    
    # Setup permissions and git
    lxc exec "$TEST_CONTAINER" -- bash -c "chmod +x /tmp/plugin/bin/* && chown -R testuser:testuser /tmp/plugin" 2>/dev/null || true
    lxc exec "$TEST_CONTAINER" -- su - testuser -c "
        cd /tmp/plugin
        git config --global --add safe.directory /tmp/plugin
        git init -q
        git config user.email 'test@example.com'
        git config user.name 'Test User'
        git add . >/dev/null 2>&1
        git commit -m 'Initial commit' >/dev/null 2>&1
    " 2>/dev/null || true
    
    # Run test
    lxc file push "$SCRIPT_DIR/run-test.sh" "$TEST_CONTAINER/tmp/run-test.sh" >/dev/null 2>&1
    lxc exec "$TEST_CONTAINER" -- chmod +x /tmp/run-test.sh
    
    if ! test_output=$(lxc exec "$TEST_CONTAINER" -- su - testuser /tmp/run-test.sh 2>&1); then
        echo "ERROR: Test failed"
        echo "$test_output"
        exit 1
    fi
    echo "$test_output"
}

# Handle command line arguments
case "${1:-}" in
    --reset)
        echo "Resetting base container..."
        lxc delete "$BASE_CONTAINER" --force 2>/dev/null || true
        echo "Base container deleted. Run again without --reset to recreate."
        ;;
    *)
        main
        ;;
esac
