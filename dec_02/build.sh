#!/bin/bash
# Exit on error
set -e

# Install Flutter if not already installed
if [ ! -d "flutter" ]; then
    git clone https://github.com/flutter/flutter.git -b stable
fi

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"
export FLUTTER_ROOT="`pwd`/flutter"

# Enable web support
flutter config --enable-web

# Clean previous build
rm -rf build/web

# Get dependencies
flutter pub get

# Build web app
flutter build web --release --no-tree-shake-icons

echo "Build completed successfully!"