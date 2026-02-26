#!/bin/bash
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter config --no-analytics
flutter pub get
flutter build web --release --no-tree-shake-icons
