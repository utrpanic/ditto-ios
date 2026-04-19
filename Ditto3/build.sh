#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

build_args=("$@")
needs_default_scheme=true
needs_default_destination=true

for arg in "$@"; do
  if [[ "$arg" == "-scheme" || "$arg" == -scheme=* ]]; then
    needs_default_scheme=false
  fi

  if [[ "$arg" == "-destination" || "$arg" == -destination=* ]]; then
    needs_default_destination=false
  fi
done

if [[ "$needs_default_scheme" == true ]]; then
  build_args+=(-scheme App)
fi

if [[ "$needs_default_destination" == true ]]; then
  simulator_name="$(./script/find-simulator.sh)"
  build_args+=(-destination "platform=iOS Simulator,name=${simulator_name}")
fi

xcodebuild build \
  -workspace Ditto3.xcworkspace \
  "${build_args[@]}"
