#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

command -v python3 >/dev/null 2>&1 || {
  echo "ERROR: python3 is required." >&2
  exit 1
}

python3 -m json.tool planning/project.json >/dev/null
python3 -m py_compile scripts/sync_project.py
exec python3 scripts/sync_project.py --config planning/project.json "$@"
