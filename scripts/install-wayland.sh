#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PACKAGES_DIR="${REPO_ROOT}/packages"

log_step()  { printf '\e[34m==> %s\e[0m\n' "$1"; }
log_done()  { printf '\e[32m==> %s\e[0m\n' "$1"; }
log_info()  { printf '\e[36m--> %s\e[0m\n' "$1"; }
log_error() { printf '\e[31m==> ERROR: %s\e[0m\n' "$1"; }

run_install() {
  local label="$1" file="$2"
  if [[ ! -f "$file" ]]; then
    log_error "Package list not found: $file"
    return 1
  fi
  mapfile -t pkgs < <(grep -vE '^[[:space:]]*(#|$)' "$file")
  if [[ ${#pkgs[@]} -eq 0 ]]; then
    log_info "[$label] no packages to install"
    return 0
  fi
  log_step "[$label] installing ${#pkgs[@]} packages"
  yay -S --needed --noconfirm "${pkgs[@]}"
  log_done "[$label] done"
}

install_wayland() {
  run_install "wayland" "${PACKAGES_DIR}/wayland.txt"
}
