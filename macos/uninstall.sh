#!/bin/bash
# Removes Clawd Usage menu bar app + daemon on macOS.
set -euo pipefail

DAEMON_LABEL="com.john.clawdusage.daemon"
APP_NAME="Clawd Usage"

# Stop daemon
launchctl bootout "gui/$(id -u)/$DAEMON_LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$DAEMON_LABEL.plist"

# Kill app if running
killall "ClawdUsage" 2>/dev/null || true

# Remove app
rm -rf "$HOME/Applications/$APP_NAME.app"

# Remove vendored daemon
rm -rf "$HOME/Library/Application Support/ClawdUsage"

# Remove state file
rm -f "$HOME/.claude/usage-bar-state.json"

echo "Uninstalled."
