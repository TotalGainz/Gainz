#!/usr/bin/env bash
# ================================================================
#  generate_project.sh
#  Gainz ▸ Build-Setup Helper
#  ----------------------------------------------------------------
#  Generates Gainz.xcodeproj from project.yml using XcodeGen,
#  verifies toolchain versions, and bootstraps Swift packages.
# ================================================================

set -euo pipefail

# ────────────────────────────────────────────────────────────────
# MARK: ✦ Helpers
# ────────────────────────────────────────────────────────────────
function die()  { printf "\e[31m✖ %s\e[0m\n" "$1"; exit 1; }
function note() { printf "\e[34m➜ %s\e[0m\n" "$1";           }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.."              && pwd)"
PROJECT_YML="$REPO_ROOT/project.yml"
PROJECT_FILE="$REPO_ROOT/Gainz.xcodeproj"
REQUIRED_XCODEGEN="2.40.0"

cd "$REPO_ROOT"

# ────────────────────────────────────────────────────────────────
# MARK: ✦ Preconditions
# ────────────────────────────────────────────────────────────────
[[ -f "$PROJECT_YML" ]] || die "project.yml not found at repo root."

if ! command -v xcodegen >/dev/null 2>&1; then
  note "Installing XcodeGen via Homebrew…"
  brew install xcodegen || die "Homebrew install failed."
fi

CURRENT_XCODEGEN="$(xcodegen --version | awk '{print $2}')"
if [[ "$(printf '%s\n' "$REQUIRED_XCODEGEN" "$CURRENT_XCODEGEN" | sort -V | head -n1)" != "$REQUIRED_XCODEGEN" ]]; then
  note "Upgrading XcodeGen to >= $REQUIRED_XCODEGEN…"
  brew upgrade xcodegen || die "XcodeGen upgrade failed."
fi

# ────────────────────────────────────────────────────────────────
# MARK: ✦ Generate Xcode project
# ────────────────────────────────────────────────────────────────
note "Generating Gainz.xcodeproj…"
xcodegen generate --spec "$PROJECT_YML" --use-cache || die "XcodeGen failed."

# ────────────────────────────────────────────────────────────────
# MARK: ✦ Swift package bootstrap
# ────────────────────────────────────────────────────────────────
note "Resolving Swift Package dependencies…"
xcodebuild -resolvePackageDependencies -project "$PROJECT_FILE" -quiet || die "SPM resolve failed."

# ────────────────────────────────────────────────────────────────
# MARK: ✦ Lint fast-fail (optional)
# ────────────────────────────────────────────────────────────────
if command -v swiftlint >/dev/null 2>&1; then
  note "Running SwiftLint…"
  swiftlint || die "SwiftLint violations detected."
fi

note "✅ Gainz project generated successfully."
