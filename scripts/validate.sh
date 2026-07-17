#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
python3 -m json.tool automation-package/planning/project.json >/dev/null
python3 -m py_compile automation-package/scripts/sync_project.py
bash -n automation-package/setup_project.sh scripts/build.sh scripts/validate.sh
if command -v lazbuild >/dev/null 2>&1; then
  lazbuild --build-mode=Default src/competitive_kpi_tool.lpi
else
  echo "WARNING: lazbuild not installed; Pascal compilation skipped." >&2
fi
