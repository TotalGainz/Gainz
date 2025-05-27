#!/usr/bin/env bash
#───────────────────────────────────────────────────────────────────────────────
# lint.sh — Gainz code-style gate
# Runs SwiftFormat then SwiftLint; fails CI if either reports violations.
# USAGE: ./Scripts/lint.sh [target_path]
#───────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# Resolve workspace root (script may be invoked from anywhere)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_PATH="${1:-$ROOT_DIR}"

# Constants
SWIFTLINT_CMD="${SWIFTLINT_PATH:-swiftlint}"
SWIFTFORMAT_CMD="${SWIFTFORMAT_PATH:-swiftformat}"
SWIFTFORMAT_CONFIG="$ROOT_DIR/.swiftformat"
SWIFTLINT_CONFIG="$ROOT_DIR/.swiftlint.yml"

# Pretty log helper
log() { printf "\033[0;35m▶ %s\033[0m\n" "$1"; }

# Check tool availability
command -v "$SWIFTFORMAT_CMD" >/dev/null 2>&1 || {
  echo "❌ SwiftFormat not found. Install via 'brew install swiftformat'."; exit 127; }
command -v "$SWIFTLINT_CMD" >/dev/null 2>&1 || {
  echo "❌ SwiftLint not found. Install via 'brew install swiftlint'."; exit 127; }

# 1. SwiftFormat — auto-correct style
log "Running SwiftFormat …"
"$SWIFTFORMAT_CMD" "$TARGET_PATH" \
  --config "$SWIFTFORMAT_CONFIG" \
  --swiftversion 5.9 \
  --quiet

# 2. SwiftLint — static analysis
log "Running SwiftLint …"
"$SWIFTLINT_CMD" lint \
  --config "$SWIFTLINT_CONFIG" \
  --strict \
  --quiet \
  --path "$TARGET_PATH"

log "✅ Linting completed with no violations."
```
