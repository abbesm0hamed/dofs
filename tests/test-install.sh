#!/bin/bash

# test-install.sh - Run dofs installation in a clean Docker container
# This script builds and runs a Fedora container to verify bootstrap health.

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="dofs-test"
CONTAINER_NAME="dofs-test-run"

echo "==> Building test environment (Fedora)..."
docker build -t "$IMAGE_NAME" -f "$REPO_ROOT/tests/Dockerfile" "$REPO_ROOT/tests"

echo "==> Starting test container..."
# Remove any existing container
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# Run the container, mounting the repo
# We run the actual install.sh script inside
docker run --name "$CONTAINER_NAME" \
    -v "$REPO_ROOT:/home/abbes/dofs:Z" \
    -t "$IMAGE_NAME" \
    bash -c "cd /home/abbes/dofs && ./install.sh --non-interactive"

# After install, run verification
echo "==> Running verification inside container..."
docker exec -t "$CONTAINER_NAME" bash -c "cd /home/abbes/dofs && ./scripts/setup/verify.sh"

echo "==> Test complete! Cleaning up..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

echo "==> SUCCESS: Dotfiles bootstrap verified in clean Fedora environment."
