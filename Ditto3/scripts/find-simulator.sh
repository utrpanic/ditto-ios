#!/usr/bin/env bash

set -euo pipefail

simulator_name="$(
  xcrun simctl list devices available |
    awk '
      /^[[:space:]]+/ {
        sub(/^[[:space:]]+/, "", $0)
        sub(/[[:space:]]+\(.*/, "", $0)
        print
        exit
      }
    '
)"

if [[ -z "$simulator_name" ]]; then
  echo "error: no available iOS Simulator device found" >&2
  exit 1
fi

echo "$simulator_name"
