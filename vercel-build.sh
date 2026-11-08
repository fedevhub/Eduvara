#!/bin/bash
set -e

# Download Flutter SDK
git clone https://github.com/flutter/flutter.git \
  --depth 1 -b stable "$HOME/flutter"

export PATH="$HOME/flutter/bin:$PATH"

# Install dependencies
flutter --version
flutter pub get

# Build Flutter Web
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"