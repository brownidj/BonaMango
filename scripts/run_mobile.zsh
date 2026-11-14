#!/bin/zsh
# One command prepares a paired Mac service and launches the selected phone.
set -euo pipefail
BONA_MANGXO_PROJECT_ROOT="${0:A:h:h}"
# Validate before creating configuration, starting services or touching builds.
if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  print 'Usage: ./scripts/run_mobile.zsh -d DEVICE_ID [--debug|--profile|--release]'
  print 'Find DEVICE_ID using: flutter devices. Use --debug for a simulator.'
  exit 0
fi
BONA_MANGXO_DEVICE_COUNT=0
BONA_MANGXO_EXPECT_DEVICE=false
for BONA_MANGXO_ARGUMENT in "$@"; do
  if $BONA_MANGXO_EXPECT_DEVICE; then
    if [[ -z "$BONA_MANGXO_ARGUMENT" || "$BONA_MANGXO_ARGUMENT" == -* || "$BONA_MANGXO_ARGUMENT" == */* || "$BONA_MANGXO_ARGUMENT" == *PHONE_ID* || "$BONA_MANGXO_ARGUMENT" == *SIMULATOR_ID* ]]; then
      print -u2 'Supply a real device ID after -d. Run flutter devices to find it; do not paste the script name or PHONE_ID.'
      exit 2
    fi
    BONA_MANGXO_EXPECT_DEVICE=false
  elif [[ "$BONA_MANGXO_ARGUMENT" == -d || "$BONA_MANGXO_ARGUMENT" == --device-id ]]; then
    (( ++BONA_MANGXO_DEVICE_COUNT ))
    BONA_MANGXO_EXPECT_DEVICE=true
  fi
done
if $BONA_MANGXO_EXPECT_DEVICE || (( BONA_MANGXO_DEVICE_COUNT != 1 )); then
  print -u2 'Usage: ./scripts/run_mobile.zsh -d DEVICE_ID [--debug|--profile|--release]'
  print -u2 'Specify exactly one real device ID from flutter devices.'
  exit 2
fi
"$BONA_MANGXO_PROJECT_ROOT/.venv/bin/python" "$BONA_MANGXO_PROJECT_ROOT/scripts/prepare_mobile.py"
"$BONA_MANGXO_PROJECT_ROOT/.venv/bin/python" "$BONA_MANGXO_PROJECT_ROOT/scripts/package_catalogue.py"
"$BONA_MANGXO_PROJECT_ROOT/scripts/prepare_ios_build.zsh"
if (( $+commands[flutter] )); then
  BONA_MANGXO_FLUTTER_BIN="${commands[flutter]}"
else
  BONA_MANGXO_FLUTTER_BIN="$HOME/development/flutter/bin/flutter"
fi
cd "$BONA_MANGXO_PROJECT_ROOT/flutter_app"
# A release installation can be reopened from the iPhone home screen without
# Flutter's debugger. Explicit mode flags remain available for development.
BONA_MANGXO_BUILD_MODE=(--release)
for BONA_MANGXO_ARGUMENT in "$@"; do
  case "$BONA_MANGXO_ARGUMENT" in
    --debug|--profile|--release) BONA_MANGXO_BUILD_MODE=();;
  esac
done
exec "$BONA_MANGXO_FLUTTER_BIN" run \
  "${BONA_MANGXO_BUILD_MODE[@]}" \
  --dart-define-from-file="$BONA_MANGXO_PROJECT_ROOT/data/mobile_connection.json" "$@"
