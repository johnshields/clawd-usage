#!/bin/bash
# Removes Clawd Usage plasmoid + daemon.
set -euo pipefail

systemctl --user disable --now clawd-usage.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/clawd-usage.service"
systemctl --user daemon-reload || true

kpackagetool6 --type Plasma/Applet --remove com.john.clawdusage 2>/dev/null || true

rm -f "$HOME/.local/share/icons/hicolor/scalable/apps/clawd-logo.svg"
rm -f "$HOME/.claude/usage-bar-state.json"

echo "Uninstalled."
