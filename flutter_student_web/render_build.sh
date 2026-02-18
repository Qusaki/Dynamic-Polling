#!/usr/bin/env bash
set -e

echo "Downloading Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Building Flutter Web App..."
flutter build web --release

echo "Build complete. Artifacts are in build/web"
