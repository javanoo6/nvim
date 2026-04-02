#!/usr/bin/env bash
set -e

COOKIES_DB=$(find ~/.mozilla/firefox -name "cookies.sqlite" 2>/dev/null | head -1)
if [ -z "$COOKIES_DB" ]; then
  echo "ERROR: Firefox cookies.sqlite not found" >&2
  exit 1
fi

# Copy DB to temp file — Firefox may have it locked while running
TMP=$(mktemp /tmp/lc-cookies.XXXXXX.sqlite)
trap 'rm -f "$TMP"' EXIT
cp "$COOKIES_DB" "$TMP"

CSRF=$(sqlite3 "$TMP" "SELECT value FROM moz_cookies WHERE host LIKE '%leetcode%' AND name='csrftoken' LIMIT 1;")
SESSION=$(sqlite3 "$TMP" "SELECT value FROM moz_cookies WHERE host LIKE '%leetcode%' AND name='LEETCODE_SESSION' LIMIT 1;")

if [ -z "$CSRF" ] || [ -z "$SESSION" ]; then
  echo "ERROR: LeetCode cookies not found. Make sure you are logged into leetcode.com in Firefox." >&2
  exit 1
fi

# Write cookie file for the plugin
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/nvim/leetcode"
mkdir -p "$CACHE_DIR"
echo "csrftoken=$CSRF; LEETCODE_SESSION=$SESSION" > "$CACHE_DIR/cookie"

# Update private.lua
cat > "$HOME/.config/nvim/lua/private.lua" << EOF
return {
  leetcode = {
    session = "$SESSION",
    csrf = "$CSRF",
  },
}
EOF

echo "OK"
