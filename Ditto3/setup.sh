#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

if ! command -v mise >/dev/null 2>&1; then
  echo "error: 'mise' command not found. Install mise first." >&2
  exit 1
fi

mise install
mise exec -- tuist clean

mise exec -- tuist install
mise exec -- tuist generate "$@"
