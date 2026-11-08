#!/bin/bash
set -e

git clone https://github.com/flutter/flutter.git \
  --depth 1 -b stable "$HOME/flutter"

export PATH="$HOME/flutter/bin:$PATH"

flutter pub get

cat > .env <<EOF
SUPABASE_URL=$SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY
EOF

flutter build web --release