#!/usr/bin/env bash
# Runs every check that must pass before every push. There is no CI on
# the free GitHub tier, so this script is the gate. Usage: tool/check.sh
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n== %s\n' "$1"; }

step 'packages'
flutter pub get
(cd packages/fusion_core && dart pub get)

step 'scripts'
for script in tool/*.sh; do bash -n "$script"; done

step 'format'
dart format --output=none --set-exit-if-changed lib test tool packages/fusion_core

step 'analyze'
flutter analyze
(cd packages/fusion_core && dart analyze)

step 'engine tests'
(cd packages/fusion_core && dart test)

step 'app tests'
flutter test

step 'web build'
flutter build web --release --no-web-resources-cdn

printf '\nAll checks passed.\n'
