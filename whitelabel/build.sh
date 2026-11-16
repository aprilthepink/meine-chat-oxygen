#!/usr/bin/env bash
# Build the whitelabel app for a context: ./whitelabel/build.sh <pdl|ljs> [apk|appbundle]
set -euo pipefail

ctx="${1:?usage: $0 <pdl|ljs> [apk|appbundle]}"
target="${2:-apk}"
cd "$(dirname "$0")/.."

config="whitelabel/${ctx}.json"
[[ -f "$config" ]] || { echo "unknown context: $ctx (no $config)" >&2; exit 1; }

flutter build "$target" --release \
  --flavor stableUnifiedpush \
  --dart-define-from-file="$config"
