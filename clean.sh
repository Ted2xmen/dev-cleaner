#!/bin/bash

# =============================================================================
# dev-cleaner: macOS Developer Disk Cleanup Script
# Frees disk space by clearing caches, build artifacts, and unused data.
# Skips tools that aren't installed.
# =============================================================================

set -euo pipefail

DRY_RUN=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run|-d)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--dry-run|-d] [--help|-h]"
      echo "  --dry-run, -d    Show what would be deleted without actually deleting"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

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

would_delete() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "  ${YELLOW}[DRY RUN]${NC} Would delete: $1"
  fi
}

execute_or_preview() {
  local description=$1
  local command=$2

  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "  ${YELLOW}[DRY RUN]${NC} Would execute: $description"
  else
    info "$description"
    eval "$command"
  fi
}

# -- Record disk space before cleanup -----------------------------------------

DISK_BEFORE=$(df -h / | tail -1 | awk '{print $4}')

echo ""
echo -e "${BOLD}=====================================================${NC}"
echo -e "${BOLD}  ${CYAN}dev-cleaner${NC}${BOLD}: macOS Developer Disk Cleanup${NC}"
if [[ "$DRY_RUN" == "true" ]]; then
  echo -e "${BOLD}  ${YELLOW}[DRY RUN MODE - No files will be deleted]${NC}"
fi
echo -e "${BOLD}=====================================================${NC}"
echo ""
echo -e "  Disk space available: ${YELLOW}${BOLD}${DISK_BEFORE}${NC}"

# -- 1. macOS System Caches ---------------------------------------------------

section "macOS System Caches"

if [[ "$DRY_RUN" == "true" ]]; then
  would_delete "~/Library/Logs/*"
  would_delete "~/.Trash/*"
else
  info "Clearing application logs..."
  rm -rf ~/Library/Logs/* 2>/dev/null || true

  info "Emptying Trash..."
  rm -rf ~/.Trash/* 2>/dev/null || true

  success "Done."
fi

# -- 2. Xcode Cleanup ---------------------------------------------------------

section "Xcode Cleanup"

if command_exists xcrun || dir_exists ~/Library/Developer/Xcode; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/Library/Developer/Xcode/DerivedData/*"
    would_delete "~/Library/Developer/Xcode/Archives/*"
    would_delete "~/Library/Developer/Xcode/iOS DeviceSupport/*"
    would_delete "~/Library/Caches/com.apple.dt.Xcode"
    if command_exists xcrun; then
      echo -e "  ${YELLOW}[DRY RUN]${NC} Would execute: Deleting unavailable simulators..."
    fi
  else
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
  fi
else
  skip "Xcode"
fi

# -- 3. Homebrew ---------------------------------------------------------------

section "Homebrew"

if command_exists brew; then
  execute_or_preview "Running brew cleanup..." "brew cleanup -s 2>/dev/null || true"
  execute_or_preview "Running brew autoremove..." "brew autoremove 2>/dev/null || true"

  if [[ "$DRY_RUN" == "false" ]]; then
    success "Done."
  fi
else
  skip "brew"
fi

# -- 4. Docker -----------------------------------------------------------------

section "Docker"

if command_exists docker; then
  execute_or_preview "Pruning all unused Docker data (images, containers, volumes)..." "docker system prune -a -f --volumes 2>/dev/null || true"

  if [[ "$DRY_RUN" == "false" ]]; then
    success "Done."
  fi
else
  skip "docker"
fi

# -- 5. Node.js / npm / yarn / pnpm -------------------------------------------

section "Node.js Package Manager Caches"

if command_exists npm; then
  execute_or_preview "Cleaning npm cache..." "npm cache clean --force 2>/dev/null || true"
  if [[ "$DRY_RUN" == "false" ]]; then
    success "npm cleaned."
  fi
else
  skip "npm"
fi

if command_exists yarn; then
  execute_or_preview "Cleaning yarn cache..." "yarn cache clean 2>/dev/null || true"
  if [[ "$DRY_RUN" == "false" ]]; then
    success "yarn cleaned."
  fi
else
  skip "yarn"
fi

if command_exists pnpm; then
  execute_or_preview "Pruning pnpm store..." "pnpm store prune 2>/dev/null || true"
  if [[ "$DRY_RUN" == "false" ]]; then
    success "pnpm cleaned."
  fi
else
  skip "pnpm"
fi

if command_exists bun; then
  if dir_exists ~/.bun/install/cache; then
    if [[ "$DRY_RUN" == "true" ]]; then
      would_delete "~/.bun/install/cache"
    else
      info "Clearing Bun install cache..."
      rm -rf ~/.bun/install/cache 2>/dev/null || true
      success "Bun cleaned."
    fi
  else
    skip "~/.bun/install/cache"
  fi
else
  skip "bun"
fi

# -- 6. Python / pip -----------------------------------------------------------

section "Python / pip"

if command_exists pip; then
  execute_or_preview "Purging pip cache..." "pip cache purge 2>/dev/null || true"
  if [[ "$DRY_RUN" == "false" ]]; then
    success "pip cleaned."
  fi
else
  skip "pip"
fi

if command_exists pip3; then
  execute_or_preview "Purging pip3 cache..." "pip3 cache purge 2>/dev/null || true"
  if [[ "$DRY_RUN" == "false" ]]; then
    success "pip3 cleaned."
  fi
else
  skip "pip3"
fi

# -- 7. Ruby / gem -------------------------------------------------------------

section "Ruby / gem"

if command_exists gem; then
  execute_or_preview "Cleaning old gem versions..." "gem cleanup 2>/dev/null || true"
  if [[ "$DRY_RUN" == "false" ]]; then
    success "Done."
  fi
else
  skip "gem"
fi

# -- 8. Go ---------------------------------------------------------------------

section "Go"

if command_exists go; then
  execute_or_preview "Cleaning Go build cache..." "go clean -cache 2>/dev/null || true"
  execute_or_preview "Cleaning Go module cache..." "go clean -modcache 2>/dev/null || true"

  if [[ "$DRY_RUN" == "false" ]]; then
    success "Done."
  fi
else
  skip "go"
fi

# -- 9. Rust / Cargo -----------------------------------------------------------

section "Rust / Cargo"

if dir_exists ~/.cargo/registry/cache; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/.cargo/registry/cache"
  else
    info "Clearing Cargo registry cache..."
    rm -rf ~/.cargo/registry/cache 2>/dev/null || true
    success "Done."
  fi
else
  skip "~/.cargo/registry/cache"
fi

# -- 10. Gradle ----------------------------------------------------------------

section "Gradle"

if dir_exists ~/.gradle/caches; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/.gradle/caches"
  else
    info "Clearing Gradle caches..."
    rm -rf ~/.gradle/caches 2>/dev/null || true
    success "Done."
  fi
else
  skip "~/.gradle/caches"
fi

# -- 11. Maven -----------------------------------------------------------------

section "Maven"

if dir_exists ~/.m2/repository; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/.m2/repository"
  else
    info "Clearing Maven local repository..."
    rm -rf ~/.m2/repository 2>/dev/null || true
    success "Done."
  fi
else
  skip "~/.m2/repository"
fi

# -- 12. CocoaPods Cache -------------------------------------------------------

section "CocoaPods"

if dir_exists ~/Library/Caches/CocoaPods; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/Library/Caches/CocoaPods"
  else
    info "Clearing CocoaPods cache..."
    rm -rf ~/Library/Caches/CocoaPods 2>/dev/null || true
    success "Done."
  fi
else
  skip "CocoaPods cache"
fi

# -- 13. React Native / Android Caches ----------------------------------------

section "React Native / Android"

if dir_exists ~/Library/Caches/react-native; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/Library/Caches/react-native"
  else
    info "Clearing React Native cache..."
    rm -rf ~/Library/Caches/react-native 2>/dev/null || true
    success "React Native cleaned."
  fi
fi

if dir_exists ~/.android/cache; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/.android/cache"
  else
    info "Clearing Android cache..."
    rm -rf ~/.android/cache 2>/dev/null || true
    success "Android cleaned."
  fi
fi

# -- 14. App Caches (Spotify, Chrome, Brave) ----------------------------------

section "App Caches (Spotify, Chrome, Brave)"

if dir_exists ~/Library/Caches/com.spotify.client; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/Library/Caches/com.spotify.client"
  else
    info "Clearing Spotify cache..."
    rm -rf ~/Library/Caches/com.spotify.client 2>/dev/null || true
    success "Spotify cleaned."
  fi
fi

if dir_exists ~/Library/Caches/Google; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/Library/Caches/Google"
  else
    info "Clearing Google Chrome cache..."
    rm -rf ~/Library/Caches/Google 2>/dev/null || true
    success "Chrome cleaned."
  fi
fi

if dir_exists ~/Library/Caches/BraveSoftware; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/Library/Caches/BraveSoftware"
  else
    info "Clearing Brave Browser cache..."
    rm -rf ~/Library/Caches/BraveSoftware 2>/dev/null || true
    success "Brave cleaned."
  fi
fi

# -- 15. Playwright Browsers --------------------------------------------------

section "Playwright Browsers"

if dir_exists ~/.cache/ms-playwright; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/.cache/ms-playwright"
  else
    info "Clearing Playwright browser binaries..."
    rm -rf ~/.cache/ms-playwright 2>/dev/null || true
    success "Done."
  fi
else
  skip "~/.cache/ms-playwright"
fi

# -- 16. TypeScript Build Cache ------------------------------------------------

section "TypeScript Build Cache"

if dir_exists ~/.cache/typescript; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/.cache/typescript"
  else
    info "Clearing TypeScript build info cache..."
    rm -rf ~/.cache/typescript 2>/dev/null || true
    success "Done."
  fi
else
  skip "~/.cache/typescript"
fi

# -- 17. Swift Package Manager -------------------------------------------------

section "Swift Package Manager"

if dir_exists ~/Library/Caches/org.swift.swiftpm; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/Library/Caches/org.swift.swiftpm"
  else
    info "Clearing Swift Package Manager cache..."
    rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null || true
    success "Done."
  fi
else
  skip "Swift PM cache"
fi

# -- 18. Expo / Watchman -------------------------------------------------------

section "Expo / Watchman"

if dir_exists ~/.expo; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/.expo"
  else
    info "Clearing Expo cache..."
    rm -rf ~/.expo 2>/dev/null || true
    success "Expo cleaned."
  fi
fi

if command_exists watchman; then
  execute_or_preview "Clearing Watchman watches..." "watchman watch-del-all 2>/dev/null || true"
  if [[ "$DRY_RUN" == "false" ]]; then
    success "Watchman cleaned."
  fi
else
  skip "watchman"
fi

# -- 19. IDE Caches (Zed, JetBrains) ------------------------------------------

section "IDE Caches (Zed, JetBrains)"

if dir_exists ~/Library/Caches/Zed; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/Library/Caches/Zed"
  else
    info "Clearing Zed editor cache..."
    rm -rf ~/Library/Caches/Zed 2>/dev/null || true
    success "Zed cleaned."
  fi
fi

if dir_exists ~/Library/Caches/JetBrains; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/Library/Caches/JetBrains"
  else
    info "Clearing JetBrains IDE caches..."
    rm -rf ~/Library/Caches/JetBrains 2>/dev/null || true
    success "JetBrains cleaned."
  fi
fi

# -- 20. Communication App Caches (Slack, Discord, Teams) ---------------------

section "Communication App Caches"

if dir_exists ~/Library/Caches/com.tinyspeck.slackmacgap; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/Library/Caches/com.tinyspeck.slackmacgap"
  else
    info "Clearing Slack cache..."
    rm -rf ~/Library/Caches/com.tinyspeck.slackmacgap 2>/dev/null || true
    success "Slack cleaned."
  fi
fi

if dir_exists ~/Library/Caches/com.hnc.Discord; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/Library/Caches/com.hnc.Discord"
  else
    info "Clearing Discord cache..."
    rm -rf ~/Library/Caches/com.hnc.Discord 2>/dev/null || true
    success "Discord cleaned."
  fi
fi

if dir_exists ~/Library/Caches/com.microsoft.teams; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/Library/Caches/com.microsoft.teams"
  else
    info "Clearing Microsoft Teams cache..."
    rm -rf ~/Library/Caches/com.microsoft.teams 2>/dev/null || true
    success "Teams cleaned."
  fi
fi

# -- 21. Composer (PHP) / NuGet (.NET) -----------------------------------------

section "Composer / NuGet"

if command_exists composer; then
  execute_or_preview "Clearing Composer cache..." "composer clear-cache 2>/dev/null || true"
  if [[ "$DRY_RUN" == "false" ]]; then
    success "Composer cleaned."
  fi
elif dir_exists ~/.composer/cache; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/.composer/cache"
  else
    info "Clearing Composer cache directory..."
    rm -rf ~/.composer/cache 2>/dev/null || true
    success "Composer cleaned."
  fi
else
  skip "composer"
fi

if command_exists dotnet; then
  execute_or_preview "Clearing NuGet HTTP cache..." "dotnet nuget locals http-cache --clear 2>/dev/null || true"
  execute_or_preview "Clearing NuGet temp cache..." "dotnet nuget locals temp --clear 2>/dev/null || true"
  if [[ "$DRY_RUN" == "false" ]]; then
    success "NuGet cleaned."
  fi
elif dir_exists ~/.nuget/packages; then
  if [[ "$DRY_RUN" == "true" ]]; then
    would_delete "~/.nuget/packages"
  else
    info "Clearing NuGet packages cache..."
    rm -rf ~/.nuget/packages 2>/dev/null || true
    success "NuGet cleaned."
  fi
else
  skip "dotnet / NuGet"
fi

# -- Summary -------------------------------------------------------------------

if [[ "$DRY_RUN" == "true" ]]; then
  echo ""
  echo -e "${BOLD}=====================================================${NC}"
  echo -e "${YELLOW}${BOLD}  Dry run complete - no changes made${NC}"
  echo -e "${BOLD}=====================================================${NC}"
  echo ""
  echo -e "  Run without --dry-run to actually clean up files."
  echo ""
else
  DISK_AFTER=$(df -h / | tail -1 | awk '{print $4}')

  echo ""
  echo -e "${BOLD}=====================================================${NC}"
  echo -e "${GREEN}${BOLD}  Cleanup complete!${NC}"
  echo -e "${BOLD}=====================================================${NC}"
  echo ""
  echo -e "  Disk space before: ${RED}${BOLD}${DISK_BEFORE}${NC}"
  echo -e "  Disk space after:  ${GREEN}${BOLD}${DISK_AFTER}${NC}"
  echo ""
fi

# -- 22. Interactive: npkill (node_modules scanner) ---------------------------

if [[ "$DRY_RUN" == "true" ]]; then
  echo -e "  ${DIM}[DRY RUN] Skipping interactive npkill (not applicable in preview mode)${NC}"
elif command_exists npx; then
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
