#!/usr/bin/env bash
set -euo pipefail
export CI=true
export TAR_OPTIONS=--no-same-owner
FLUTTER_VERSION=3.47.6
FITGUIDE_SDK_DIR="${TMPDIR:-/tmp}/fitguide-flutter-$FLUTTER_VERSION"
if [ ! -x "$FITGUIDE_SDK_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FITGUIDE_SDK_DIR"
fi
export PATH="$FITGUIDE_SDK_DIR/bin:$PATH"
flutter pub get
# SQLite worker and WASM binaries are committed and match pubspec.lock.
test -f web/sqlite3.wasm
test -f web/sqflite_sw.js
flutter --suppress-analytics build web --release --no-web-resources-cdn
