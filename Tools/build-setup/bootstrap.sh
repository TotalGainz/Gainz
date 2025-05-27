#!/usr/bin/env bash
# bootstrap.sh
# Gainz ▸ One-touch local environment bootstrap
# -------------------------------------------------------------
# This script installs all required developer tooling, generates
# the Xcode project, and wires up git hooks. Run it once after
# cloning; subsequent updates are incremental and idempotent.
#
# Usage:
#   ./bootstrap.sh        # standard install
#   FORCE=1 ./bootstrap.sh  # re-install everything from scratch
# -------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$REPO_ROOT"

# ─────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────
log()   { printf "\033[1;36m➤ $*\033[0m\n"; }
err()   { printf "\033[1;31m✖ $*\033[0m\n" >&2; }
abort() { err "$1"; exit 1; }

# ─────────────────────────────────────────────
#  Xcode & Homebrew
# ─────────────────────────────────────────────
log "🔍 Checking Xcode command-line tools…"
xcode-select -p &> /dev/null || xcode-select --install

if ! command -v brew &> /dev/null; then
  log "🍺 Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

log "🔄 Updating Homebrew formulae…"
brew update

BREW_PACKAGES=(
  swiftlint
  swiftformat
  xcodegen
  swiftgen
  pre-commit
)

log "📦 Installing brew packages: ${BREW_PACKAGES[*]}…"
brew install "${BREW_PACKAGES[@]}"

# ─────────────────────────────────────────────
#  Ruby / Bundler / Fastlane
# ─────────────────────────────────────────────
if ! command -v bundle &> /dev/null; then
  log "💎 Installing Bundler…"
  gem install bundler --no-document
fi

if [ -f "Gemfile" ]; then
  log "🔧 Installing Ruby gems…"
  bundle install --quiet
fi

# ─────────────────────────────────────────────
#  Pre-commit hooks
# ─────────────────────────────────────────────
log "⚙️  Setting up git hooks…"
pre-commit install --install-hooks --overwrite

# ─────────────────────────────────────────────
#  Code generation
# ─────────────────────────────────────────────
log "🛠  Generating Xcode project with XcodeGen…"
xcodegen generate --use-cache

log "🎨 Running SwiftGen (assets & strings)…"
swiftgen --config SwiftGen.yml

# ─────────────────────────────────────────────
#  Formatting pass
# ─────────────────────────────────────────────
log "🧹 Running SwiftFormat…"
swiftformat .

log "🔍 Linting with SwiftLint…"
swiftlint --quiet

# ─────────────────────────────────────────────
#  Final sanity check
# ─────────────────────────────────────────────
log "✅ Bootstrap finished. Open Gainz.xcodeproj and hit ⌘R!"
