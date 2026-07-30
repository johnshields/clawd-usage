#!/bin/bash
# Installs Clawd Usage menu bar app + daemon on macOS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/.build"
APP_NAME="Clawd Usage"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
INSTALL_DIR="$HOME/Applications"
DAEMON_DIR="$HOME/Library/Application Support/ClawdUsage"
DAEMON_LABEL="com.john.clawdusage.daemon"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST="$PLIST_DIR/$DAEMON_LABEL.plist"

# Preflight
command -v swiftc >/dev/null 2>&1 || { echo "missing: swiftc — run: xcode-select --install"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "missing: python3"; exit 1; }

# Check credentials (keychain on macOS, file on Linux)
if ! security find-generic-password -s "Claude Code-credentials" -a "$(whoami)" -w >/dev/null 2>&1; then
    if [ ! -f "$HOME/.claude/.credentials.json" ]; then
        echo "warning: no claude credentials found. Run 'claude auth login' first."
    fi
fi

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    TARGET="arm64-apple-macosx13.0"
else
    TARGET="x86_64-apple-macosx13.0"
fi

# Build app bundle
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

echo "Compiling ($ARCH)..."
swiftc \
    "$SCRIPT_DIR/Sources/Constants.swift" \
    "$SCRIPT_DIR/Sources/ClawdUsageApp.swift" \
    "$SCRIPT_DIR/Sources/UsageState.swift" \
    "$SCRIPT_DIR/Sources/ClawdIcon.swift" \
    "$SCRIPT_DIR/Sources/PopoverView.swift" \
    "$SCRIPT_DIR/Sources/SettingsView.swift" \
    -o "$APP_BUNDLE/Contents/MacOS/ClawdUsage" \
    -framework SwiftUI \
    -framework AppKit \
    -target "$TARGET" \
    -O

# Copy icon resources from shared assets
cp "$PROJECT_DIR/linux/plasmoid/contents/icons/clawd-silhouette.png" "$APP_BUNDLE/Contents/Resources/"
cp "$PROJECT_DIR/linux/plasmoid/contents/icons/clawd-eyes.png" "$APP_BUNDLE/Contents/Resources/"
cp "$SCRIPT_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"

# Info.plist — LSUIElement hides from dock (menu bar only)
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.john.clawdusage</string>
    <key>CFBundleName</key>
    <string>Clawd Usage</string>
    <key>CFBundleExecutable</key>
    <string>ClawdUsage</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Install app
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$APP_BUNDLE" "$INSTALL_DIR/"
echo "App installed: $INSTALL_DIR/$APP_NAME.app"

# Vendor the Python daemon so it survives the repo being moved or deleted
rm -rf "$DAEMON_DIR"
mkdir -p "$DAEMON_DIR"
cp "$PROJECT_DIR/main.py" "$DAEMON_DIR/"
cp -R "$PROJECT_DIR/src" "$DAEMON_DIR/"
echo "Daemon vendored: $DAEMON_DIR"

# Install launchd daemon for Python poller
mkdir -p "$PLIST_DIR"
launchctl bootout "gui/$(id -u)/$DAEMON_LABEL" 2>/dev/null || true

PYTHON_BIN="$(command -v python3)"
cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$DAEMON_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON_BIN</string>
        <string>$DAEMON_DIR/main.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$DAEMON_DIR</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/clawd-usage.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/clawd-usage.err</string>
</dict>
</plist>
EOF

launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Daemon started."

# Launch menu bar app
open "$INSTALL_DIR/$APP_NAME.app"

echo ""
echo "Installed. Clawd Usage is in the menu bar."
echo "To start on login: System Settings -> General -> Login Items -> add 'Clawd Usage'."
