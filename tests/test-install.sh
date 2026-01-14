#!/bin/bash

# test-install.sh - Run dofs installation in a clean Docker container
# This script builds and runs a Fedora container to verify bootstrap health.

set -e

if command -v podman >/dev/null 2>&1; then
    ENGINE=(podman)
    USERNS_ARGS=(--userns=keep-id)
else
    if docker info >/dev/null 2>&1; then
        ENGINE=(docker)
        USERNS_ARGS=()
    elif sudo -n docker info >/dev/null 2>&1; then
        ENGINE=(sudo docker)
        USERNS_ARGS=()
    else
        echo "==> ERROR: Docker is not accessible as your user and would require an interactive sudo password."
        echo "==>        Run 'sudo -v' first, add your user to the docker group, or install/use podman (rootless)."
        exit 1
    fi
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="dofs-test"
CONTAINER_NAME="dofs-test-run-$(date +%s)-$$"

echo "==> Building test environment (Fedora)..."
"${ENGINE[@]}" build \
    --build-arg UID="$(id -u)" \
    --build-arg GID="$(id -g)" \
    -t "$IMAGE_NAME" \
    -f "$REPO_ROOT/tests/Dockerfile" \
    "$REPO_ROOT/tests"

echo "==> Starting test container..."

# Run installation + verification in a single ephemeral container.
"${ENGINE[@]}" run --rm --name "$CONTAINER_NAME" \
    "${USERNS_ARGS[@]}" \
    -v "$REPO_ROOT:/home/dofs/dofs:Z" \
    -t "$IMAGE_NAME" \
    bash -lc "cd /home/dofs/dofs && ./install.sh --non-interactive && ./scripts/setup/verify.sh"

echo "==> SUCCESS: Dotfiles bootstrap verified in clean Fedora environment."
