#!/usr/bin/env bash
set -euo pipefail
FLUTTER_DIR="${TMPDIR:-/tmp}/jereposteria-flutter-3.47.8"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch 3.47.8 https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
cd app
flutter pub get
flutter build web --release --no-wasm-dry-run
