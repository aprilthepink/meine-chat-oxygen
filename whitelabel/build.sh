#!/usr/bin/env bash
# Usage: whitelabel/build.sh <pdl|ljs> [apk|appbundle]  (BUILD_NUMBER, FLUTTER_BUILD_ARGS optional)
set -euo pipefail

ctx="${1:?usage: $0 <pdl|ljs> [apk|appbundle]}"
target="${2:-apk}"
cd "$(dirname "$0")/.."

whitelabel/apply.sh "$ctx"

dart tool/configure_build.dart --profile=oss
bash tool/apply_macos_pub_overrides.sh
flutter pub get
dart run build_runner build

flutter build "$target" --release \
  --flavor stableUnifiedpush \
  ${BUILD_NUMBER:+--build-number "$BUILD_NUMBER"} \
  --dart-define-from-file=tool/dart_defines/stable.json \
  --dart-define-from-file="whitelabel/$ctx.json" \
  --dart-define=BUILD_TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  ${FLUTTER_BUILD_ARGS:-}
