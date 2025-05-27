#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
#  DevTools/MockServer/stub-run.sh
#  Spin-up a zero-config JSON stub API for local Gainz development
#  ─ compiles in <1 s, hot reloads on file save.
# ────────────────────────────────────────────────────────────────
set -euo pipefail

# ────────────────
# MARK: • Constants
# ────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DB_FILE="${SCRIPT_DIR}/db.json"                 # seed data
ROUTES_FILE="${SCRIPT_DIR}/routes.json"        # REST ↔︎ file mapping
PORT="${GAINZ_MOCK_PORT:-8080}"

# ────────────────
# MARK: • Dependency check
# ────────────────
command -v json-server >/dev/null 2>&1 || {
  echo "🔧  Installing json-server globally (requires npm)…"
  npm install -g json-server
}

# ────────────────
# MARK: • Cleanup hook
# ────────────────
cleanup() {
  echo -e "\n🛑  Stopping mock server…"
  kill "${SERVER_PID}" 2>/dev/null || true
}
trap cleanup INT TERM EXIT

# ────────────────
# MARK: • Launch
# ────────────────
echo "🚀  Starting Gainz mock API on http://localhost:${PORT}"
json-server                     \
  --watch  "${DB_FILE}"         \
  --routes "${ROUTES_FILE}"     \
  --static "${ROOT_DIR}/Assets/MockUploads" \
  --port   "${PORT}"            \
  --delay  200 &                # simulate network latency (ms)
SERVER_PID=$!

# Optional: open API root in default browser
if [[ "$OSTYPE" == "darwin"* ]]; then
  open "http://localhost:${PORT}"
fi

# ────────────────
# MARK: • Tail logs
# ────────────────
wait "${SERVER_PID}"
