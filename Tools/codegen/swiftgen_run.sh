#!/usr/bin/env bash
# swiftgen_run.sh
# Gainz ▸ One-touch asset & strings code-gen
# Usage:
#   ./Scripts/codegen/swiftgen_run.sh
#   CI=true ./Scripts/codegen/swiftgen_run.sh   # quieter logs for CI

set -euo pipefail

# ────────────────────────────
# 1. Paths
# ────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONFIG_FILE="${ROOT_DIR}/Configs/swiftgen.yml"

# ────────────────────────────
# 2. Helpers
# ────────────────────────────
log() {
  [[ "${CI:-}" == "true" ]] && return       # suppress in CI if requested
  printf "[swiftgen] %s\n" "$1"
}

# ────────────────────────────
# 3. Install SwiftGen if needed
# ────────────────────────────
if ! command -v swiftgen >/dev/null 2>&1; then
  log "SwiftGen not found. Installing via Homebrew…"
  if command -v brew >/dev/null 2>&1; then
    brew install swiftgen
  else
    echo "❌ Homebrew is not available. Install SwiftGen manually." >&2
    exit 1
  fi
fi

# ────────────────────────────
# 4. Run SwiftGen
# ────────────────────────────
log "Generating Swift asset & string enums…"
swiftgen config run --config "${CONFIG_FILE}" --verbose

log "✅ SwiftGen finished"
