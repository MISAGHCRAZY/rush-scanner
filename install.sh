#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/rush-scanner"
APP_SCRIPT="$APP_DIR/rushscanner.sh"
SCRIPT_URL="https://raw.githubusercontent.com/MISAGHCRAZY/rush-scanner/main/rushscanner.sh"

mkdir -p "$APP_DIR"

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$SCRIPT_URL" -o "$APP_SCRIPT"
elif command -v wget >/dev/null 2>&1; then
  wget -q "$SCRIPT_URL" -O "$APP_SCRIPT"
else
  echo "Error: install curl or wget first."
  exit 1
fi

chmod 700 "$APP_SCRIPT"
exec "$APP_SCRIPT"
