#!/bin/sh
# Build UsageBar from source, install to ~/Applications, start at login.
# Usage: ./install.sh            install or update
#        ./install.sh uninstall  remove app and login item
set -eu
cd "$(dirname "$0")"

APP="$HOME/Applications/UsageBar.app"
AGENT="$HOME/Library/LaunchAgents/local.usagebar.plist"
DOMAIN="gui/$(id -u)"

if [ "${1:-}" = "uninstall" ]; then
  launchctl bootout "$DOMAIN/local.usagebar" 2>/dev/null || true
  rm -rf "$APP" "$AGENT"
  echo "UsageBar removed."; exit 0
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Apple's command line tools are needed. Starting the installer; run ./install.sh again when it finishes."
  xcode-select --install; exit 1
fi

echo "Building…"
mkdir -p build/UsageBar.app/Contents/MacOS
swiftc -O UsageBar.swift -o build/UsageBar.app/Contents/MacOS/UsageBar
cp Info.plist build/UsageBar.app/Contents/Info.plist
build/UsageBar.app/Contents/MacOS/UsageBar --selftest

echo "Installing to $APP…"
launchctl bootout "$DOMAIN/local.usagebar" 2>/dev/null || true
pkill -x UsageBar 2>/dev/null || true
mkdir -p "$HOME/Applications" "$HOME/Library/LaunchAgents"
rm -rf "$APP" && cp -R build/UsageBar.app "$APP"

cat > "$AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>local.usagebar</string>
<key>ProgramArguments</key><array><string>$APP/Contents/MacOS/UsageBar</string></array>
<key>RunAtLoad</key><true/>
</dict></plist>
EOF
launchctl bootstrap "$DOMAIN" "$AGENT"
echo "Done. Look for the ring in your menu bar."
