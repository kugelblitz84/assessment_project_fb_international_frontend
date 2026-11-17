#!/usr/bin/env bash
set -euo pipefail

# Flutter 3.41.9 ships Dart 3.11.5, matching pubspec.yaml.
readonly FLUTTER_VERSION='3.41.9'
readonly FLUTTER_REVISION='00b0c91f06209d9e4a41f71b7a512d6eb3b9c694'
readonly SDK_DIR="${RENDER_FLUTTER_CACHE:-$PWD/.render-cache}/flutter-$FLUTTER_VERSION"
if [[ ! -d "$SDK_DIR/.git" ]]; then
  mkdir -p "$(dirname "$SDK_DIR")"
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$SDK_DIR"
fi
if [[ "$(git -C "$SDK_DIR" rev-parse HEAD)" != "$FLUTTER_REVISION" ]]; then
  echo 'Flutter SDK revision differs from the pinned release.' >&2
  exit 1
fi
export PATH="$SDK_DIR/bin:$PATH"
export CI=true
flutter config --no-analytics --enable-web
flutter --version
flutter pub get --enforce-lockfile
flutter build web --release --dart-define="API_BASE_URL=${API_BASE_URL:-https://fb-international-assessment-project.onrender.com/api/v1}"
test -f build/web/index.html
