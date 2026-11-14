#!/bin/zsh
# Export a local App Store/TestFlight IPA. This script never uploads it.
set -euo pipefail
BONA_MANGXO_PROJECT_ROOT="${0:A:h:h}"
BONA_MANGXO_BUILD_NUMBER=""
BONA_MANGXO_BUILD_NAME=""
BONA_MANGXO_DRY_RUN=false
BONA_MANGXO_IPA_DESTINATION="$BONA_MANGXO_PROJECT_ROOT/build/ios/ipa/bona_mangxo_app.ipa"

usage() {
  print 'Usage: scripts/build_testflight.zsh --build-number <integer> [--build-name <x.y.z>] [--dry-run]'
  print 'Builds an App Store IPA with Flutter; upload it manually using Transporter.'
  print 'Packages initial data and a public server URL; never the private pairing key. See docs/distribution/TESTFLIGHT_AND_TRANSPORTER.md.'
}
while (( $# )); do
  case "$1" in
    --build-number|--build-name)
      if (( $# < 2 )); then usage >&2; exit 2; fi
      if [[ "$1" == --build-number ]]; then
        BONA_MANGXO_BUILD_NUMBER="$2"
      else
        BONA_MANGXO_BUILD_NAME="$2"
      fi
      shift 2 ;;
    --dry-run) BONA_MANGXO_DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
if [[ ! "$BONA_MANGXO_BUILD_NUMBER" =~ '^[1-9][0-9]*$' ]]; then
  print -u2 -- 'Supply a positive --build-number higher than the last build uploaded to Apple.'
  exit 2
fi
if [[ -n "$BONA_MANGXO_BUILD_NAME" && ! "$BONA_MANGXO_BUILD_NAME" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
  print -u2 -- '--build-name must have the form x.y.z.'
  exit 2
fi
if (( $+commands[flutter] )); then
  BONA_MANGXO_FLUTTER_BIN="${commands[flutter]}"
else
  BONA_MANGXO_FLUTTER_BIN="$HOME/development/flutter/bin/flutter"
fi
BONA_MANGXO_COMMAND=("$BONA_MANGXO_FLUTTER_BIN" build ipa --release --export-method app-store
  "--build-number=$BONA_MANGXO_BUILD_NUMBER"
  "--dart-define-from-file=$BONA_MANGXO_PROJECT_ROOT/data/catalogue_build.json")
if [[ -n "$BONA_MANGXO_BUILD_NAME" ]]; then
  BONA_MANGXO_COMMAND+=("--build-name=$BONA_MANGXO_BUILD_NAME")
fi
if $BONA_MANGXO_DRY_RUN; then
  print -r -- "Working directory: $BONA_MANGXO_PROJECT_ROOT/flutter_app"
  printf '%q ' "${BONA_MANGXO_COMMAND[@]}"
  print
  print -r -- "Move exported IPA to: $BONA_MANGXO_IPA_DESTINATION (replace previous export)"
  exit 0
fi
if [[ ! -x "$BONA_MANGXO_FLUTTER_BIN" ]]; then
  print -u2 -- "Flutter executable not found: $BONA_MANGXO_FLUTTER_BIN"
  exit 1
fi
"$BONA_MANGXO_PROJECT_ROOT/.venv/bin/python" "$BONA_MANGXO_PROJECT_ROOT/scripts/package_catalogue.py"
"$BONA_MANGXO_PROJECT_ROOT/scripts/prepare_ios_build.zsh"
BONA_MANGXO_BUILD_MARKER="$(mktemp -t bona_mangxo-testflight)"
trap 'rm -f "$BONA_MANGXO_BUILD_MARKER"' EXIT
cd "$BONA_MANGXO_PROJECT_ROOT/flutter_app"
"${BONA_MANGXO_COMMAND[@]}"
BONA_MANGXO_NEW_IPA=false
for BONA_MANGXO_IPA in "$BONA_MANGXO_PROJECT_ROOT/flutter_app/build/ios/ipa/"*.ipa(N); do
  if [[ "$BONA_MANGXO_IPA" -nt "$BONA_MANGXO_BUILD_MARKER" ]]; then
    mkdir -p "${BONA_MANGXO_IPA_DESTINATION:h}"
    mv -f "$BONA_MANGXO_IPA" "$BONA_MANGXO_IPA_DESTINATION"
    print -r -- "New IPA for Transporter: $BONA_MANGXO_IPA_DESTINATION"
    BONA_MANGXO_NEW_IPA=true
  fi
done
if ! $BONA_MANGXO_NEW_IPA; then
  print -u2 -- 'No new IPA was exported. Check signing/export output or use Xcode Organizer on the archive.'
  exit 1
fi
