#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Build web app
flutter build web --release --no-tree-shake-icons