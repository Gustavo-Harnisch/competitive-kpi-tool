#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
command -v lazbuild >/dev/null 2>&1 || { echo "ERROR: lazbuild is not installed." >&2; exit 1; }
mkdir -p build
lazbuild --build-mode=Default src/competitive_kpi_tool.lpi
