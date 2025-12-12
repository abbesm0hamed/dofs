#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PACKAGES_DIR="${REPO_ROOT}/packages"

log_step() { printf '\e[34m==> %s\e[0m\n' "$1"; }
log_done() { printf '\e[32m==> %s\e[0m\n' "$1"; }
log_info() { printf '\e[36m--> %s\e[0m\n' "$1"; }
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

  # Install with retry logic
  local max_retries=2
  local retry=0
  while [ $retry -le $max_retries ]; do
    if yay -S --needed --noconfirm "${pkgs[@]}" 2>&1 | tee -a /tmp/niri-bootstrap.log; then
      break
    else
      retry=$((retry + 1))
      if [ $retry -le $max_retries ]; then
        log_error "Installation failed, retrying ($retry/$max_retries)..."
        sleep 2
      else
        log_error "Installation failed after $max_retries retries"
        return 1
      fi
    fi
  done

  log_done "[$label] done"
}

verify_critical_packages() {
  log_step "[wayland] Verifying critical packages..."

  local critical_bins=("niri" "waybar" "mako" "fuzzel")
  local missing=()

  for bin in "${critical_bins[@]}"; do
    if ! command -v "$bin" &>/dev/null; then
      missing+=("$bin")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    log_error "Critical packages missing: ${missing[*]}"
    log_error "Installation may have failed"
    return 1
  fi

  log_done "[wayland] All critical packages verified"
}

install_wayland() {
  run_install "wayland" "${PACKAGES_DIR}/wayland.txt"
  verify_critical_packages
}
