#!/bin/bash

# =============================================================================
# dev-cleaner: macOS Developer Disk Cleanup Script
# Frees disk space by clearing caches, build artifacts, and unused data.
# Skips tools that aren't installed.
# =============================================================================

set -euo pipefail

# -- Colors -------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# -- Helper functions ---------------------------------------------------------

command_exists() {
  command -v "$1" &>/dev/null
}

dir_exists() {
  [[ -d "$1" ]]
}

section() {
  echo ""
  echo -e "${BLUE}${BOLD}=== $1 ===${NC}"
}

info() {
  echo -e "  ${CYAN}->  ${NC}$1"
}

success() {
  echo -e "  ${GREEN}[OK]${NC} $1"
}

skip() {
  echo -e "  ${DIM}[--] Skipped: $1 not found${NC}"
}

# -- Record disk space before cleanup -----------------------------------------

DISK_BEFORE=$(df -h / | tail -1 | awk '{print $4}')

echo ""
echo -e "${BOLD}=====================================================${NC}"
echo -e "${BOLD}  ${CYAN}dev-cleaner${NC}${BOLD}: macOS Developer Disk Cleanup${NC}"
echo -e "${BOLD}=====================================================${NC}"
echo ""
echo -e "  Disk space available: ${YELLOW}${BOLD}${DISK_BEFORE}${NC}"

# -- 1. macOS System Caches ---------------------------------------------------

section "macOS System Caches"

info "Clearing application logs..."
rm -rf ~/Library/Logs/* 2>/dev/null || true

info "Emptying Trash..."
rm -rf ~/.Trash/* 2>/dev/null || true

success "Done."

# -- 2. Xcode Cleanup ---------------------------------------------------------

section "Xcode Cleanup"

if command_exists xcrun || dir_exists ~/Library/Developer/Xcode; then
  info "Clearing DerivedData..."
  rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true

  info "Clearing Archives..."
  rm -rf ~/Library/Developer/Xcode/Archives/* 2>/dev/null || true

  info "Clearing iOS DeviceSupport..."
  rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/* 2>/dev/null || true

  info "Clearing Xcode caches..."
  rm -rf ~/Library/Caches/com.apple.dt.Xcode 2>/dev/null || true

  if command_exists xcrun; then
    info "Deleting unavailable simulators..."
    xcrun simctl delete unavailable 2>/dev/null || true
  fi

  success "Done."
else
  skip "Xcode"
fi

# -- 3. Homebrew ---------------------------------------------------------------

section "Homebrew"

if command_exists brew; then
  info "Running brew cleanup..."
  brew cleanup -s 2>/dev/null || true

  info "Running brew autoremove..."
  brew autoremove 2>/dev/null || true

  success "Done."
else
  skip "brew"
fi

# -- 4. Docker -----------------------------------------------------------------

section "Docker"

if command_exists docker; then
  info "Pruning all unused Docker data (images, containers, volumes)..."
  docker system prune -a -f --volumes 2>/dev/null || true
  success "Done."
else
  skip "docker"
fi

# -- 5. Node.js / npm / yarn / pnpm -------------------------------------------

section "Node.js Package Manager Caches"

if command_exists npm; then
  info "Cleaning npm cache..."
  npm cache clean --force 2>/dev/null || true
  success "npm cleaned."
else
  skip "npm"
fi

if command_exists yarn; then
  info "Cleaning yarn cache..."
  yarn cache clean 2>/dev/null || true
  success "yarn cleaned."
else
  skip "yarn"
fi

if command_exists pnpm; then
  info "Pruning pnpm store..."
  pnpm store prune 2>/dev/null || true
  success "pnpm cleaned."
else
  skip "pnpm"
fi

# -- 6. Python / pip -----------------------------------------------------------

section "Python / pip"

if command_exists pip; then
  info "Purging pip cache..."
  pip cache purge 2>/dev/null || true
  success "pip cleaned."
else
  skip "pip"
fi

if command_exists pip3; then
  info "Purging pip3 cache..."
  pip3 cache purge 2>/dev/null || true
  success "pip3 cleaned."
else
  skip "pip3"
fi

# -- 7. Ruby / gem -------------------------------------------------------------

section "Ruby / gem"

if command_exists gem; then
  info "Cleaning old gem versions..."
  gem cleanup 2>/dev/null || true
  success "Done."
else
  skip "gem"
fi

# -- 8. Go ---------------------------------------------------------------------

section "Go"

if command_exists go; then
  info "Cleaning Go build cache..."
  go clean -cache 2>/dev/null || true

  info "Cleaning Go module cache..."
  go clean -modcache 2>/dev/null || true

  success "Done."
else
  skip "go"
fi

# -- 9. Rust / Cargo -----------------------------------------------------------

section "Rust / Cargo"

if dir_exists ~/.cargo/registry/cache; then
  info "Clearing Cargo registry cache..."
  rm -rf ~/.cargo/registry/cache 2>/dev/null || true
  success "Done."
else
  skip "~/.cargo/registry/cache"
fi

# -- 10. Gradle ----------------------------------------------------------------

section "Gradle"

if dir_exists ~/.gradle/caches; then
  info "Clearing Gradle caches..."
  rm -rf ~/.gradle/caches 2>/dev/null || true
  success "Done."
else
  skip "~/.gradle/caches"
fi

# -- 11. Maven -----------------------------------------------------------------

section "Maven"

if dir_exists ~/.m2/repository; then
  info "Clearing Maven local repository..."
  rm -rf ~/.m2/repository 2>/dev/null || true
  success "Done."
else
  skip "~/.m2/repository"
fi

# -- 12. CocoaPods Cache -------------------------------------------------------

section "CocoaPods"

if dir_exists ~/Library/Caches/CocoaPods; then
  info "Clearing CocoaPods cache..."
  rm -rf ~/Library/Caches/CocoaPods 2>/dev/null || true
  success "Done."
else
  skip "CocoaPods cache"
fi

# -- 13. React Native / Android Caches ----------------------------------------

section "React Native / Android"

if dir_exists ~/Library/Caches/react-native; then
  info "Clearing React Native cache..."
  rm -rf ~/Library/Caches/react-native 2>/dev/null || true
  success "React Native cleaned."
fi

if dir_exists ~/.android/cache; then
  info "Clearing Android cache..."
  rm -rf ~/.android/cache 2>/dev/null || true
  success "Android cleaned."
fi

# -- 14. App Caches (Spotify, Chrome) -----------------------------------------

section "App Caches (Spotify, Chrome)"

if dir_exists ~/Library/Caches/com.spotify.client; then
  info "Clearing Spotify cache..."
  rm -rf ~/Library/Caches/com.spotify.client 2>/dev/null || true
  success "Spotify cleaned."
fi

if dir_exists ~/Library/Caches/Google; then
  info "Clearing Google Chrome cache..."
  rm -rf ~/Library/Caches/Google 2>/dev/null || true
  success "Chrome cleaned."
fi

# -- Summary -------------------------------------------------------------------

DISK_AFTER=$(df -h / | tail -1 | awk '{print $4}')

echo ""
echo -e "${BOLD}=====================================================${NC}"
echo -e "${GREEN}${BOLD}  Cleanup complete!${NC}"
echo -e "${BOLD}=====================================================${NC}"
echo ""
echo -e "  Disk space before: ${RED}${BOLD}${DISK_BEFORE}${NC}"
echo -e "  Disk space after:  ${GREEN}${BOLD}${DISK_AFTER}${NC}"
echo ""

# -- 15. Interactive: npkill (node_modules scanner) ---------------------------

if command_exists npx; then
  echo -e "  ${YELLOW}Optional:${NC} Scan for old node_modules with npkill?"
  echo -e "  ${DIM}Controls: [Space] to delete, [Q] to quit.${NC}"
  read -rp "  Launch npkill? (y/N): " LAUNCH_NPKILL
  if [[ "$LAUNCH_NPKILL" =~ ^[Yy]$ ]]; then
    npx npkill --directory ~
  else
    echo -e "  ${DIM}Skipping npkill.${NC}"
  fi
else
  skip "npx"
fi
