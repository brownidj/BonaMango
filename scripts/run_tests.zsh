#!/bin/zsh
# Host regressions by default; native integration and release builds are explicit.
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
FLUTTER_BIN="${FLUTTER_BIN:-/Users/david/development/flutter/bin/flutter}"
DEVICE_ID=""
BUILD_RELEASES=false
RUN_HOST=true
RUN_ALL=false
usage() {
  print 'Usage: scripts/run_tests.zsh [--all] [--device <id>] [--builds | --builds-only]'
  print '--all runs all host and native integration tests; auto-selects a booted iOS simulator.'
  print '--builds additionally compiles web/macOS/iOS release packages and checks their assets.'
}
while (( $# )); do
  case "$1" in
    --all) RUN_ALL=true; shift ;;
    --device)
      if (( $# < 2 )) || [[ "$2" == --* || -z "$2" ]]; then
        usage >&2; exit 2
      fi
      DEVICE_ID="$2"; shift 2 ;;
    --builds) BUILD_RELEASES=true; shift ;;
    --builds-only) BUILD_RELEASES=true; RUN_HOST=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
if $RUN_ALL && ! $RUN_HOST; then
  print -u2 -- '--all cannot be combined with --builds-only.'
  exit 2
fi
if $RUN_ALL && [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$("$PROJECT_DIR/.venv/bin/python" - <<'PY'
import json
import subprocess
import sys
inventory = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', 'available', '--json']))
for runtime, devices in inventory['devices'].items():
    if '.iOS-' not in runtime:
        continue
    for device in devices:
        if device.get('isAvailable') and device['state'] == 'Booted':
            print(device['udid'])
            sys.exit(0)
sys.exit('No booted iOS simulator. Start one, then retry --all, or supply --device <id>. Native tests were NOT run.')
PY
)"
  print -r -- "Native integration simulator: $DEVICE_ID"
fi
TEST_OUTPUT="${TEST_OUTPUT:-$PROJECT_DIR/data/logs/testing-$(date +%Y-%m-%d-%H%M%S)}"
mkdir -p "$TEST_OUTPUT"

run_check() {
  local check_name="$1"
  shift
  print "Running $check_name"
  "$@" 2>&1 | tee "$TEST_OUTPUT/$check_name.log"
}

cd "$PROJECT_DIR"
if $RUN_HOST; then
  run_check python .venv/bin/python -m unittest discover -s tests -v
  cd "$PROJECT_DIR/flutter_app"
  run_check dependencies "$FLUTTER_BIN" pub get
  # Dart's analyzer handles the Unicode project path; this Flutter version's
  # analyze wrapper truncates its LSP request for non-ASCII working directories.
  run_check analyze "${FLUTTER_BIN:h}/dart" analyze
  run_check flutter "$FLUTTER_BIN" test --coverage --reporter expanded
fi
cd "$PROJECT_DIR/flutter_app"
if [[ -n "$DEVICE_ID" ]]; then
  run_check integration "$FLUTTER_BIN" test integration_test -d "$DEVICE_ID" --reporter expanded
fi
if $BUILD_RELEASES; then
  run_check package-catalogue "$PROJECT_DIR/.venv/bin/python" "$PROJECT_DIR/scripts/package_catalogue.py"
  run_check web-release "$FLUTTER_BIN" build web --release
  run_check macos-release "$FLUTTER_BIN" build macos --release
  run_check ios-prepare "$PROJECT_DIR/scripts/prepare_ios_build.zsh"
  run_check ios-release "$FLUTTER_BIN" build ios --release
  run_check release-assets "$PROJECT_DIR/.venv/bin/python" "$PROJECT_DIR/scripts/check_release_assets.py"
fi
print "Requested checks passed. Logs: $TEST_OUTPUT"
