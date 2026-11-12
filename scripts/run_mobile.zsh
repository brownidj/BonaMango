#!/bin/zsh
# One command prepares a paired Mac service and launches the selected phone.
set -euo pipefail
BONA_MANGXO_PROJECT_ROOT="${0:A:h:h}"
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
