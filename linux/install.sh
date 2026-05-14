#!/bin/bash
# Installs Clawd Usage plasmoid + daemon service.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Preflight checks
for cmd in python3 kpackagetool6 systemctl; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "missing: $cmd"; exit 1; }
done

PYTHON_BIN="$(command -v python3)"

# Need ~/.claude/.credentials.json from Claude Code login
[ -f "$HOME/.claude/.credentials.json" ] || {
    echo "warning: $HOME/.claude/.credentials.json missing. Run 'claude login' first."
}

# Install icon to user hicolor theme
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$ICON_DIR"
install -m644 "$SCRIPT_DIR/plasmoid/contents/icons/clawd-logo.svg" "$ICON_DIR/clawd-logo.svg"

# Refresh icon cache if tool available + theme index exists
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    [ -f "$HOME/.local/share/icons/hicolor/index.theme" ] && \
        gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

# Install / upgrade plasmoid
kpackagetool6 --type Plasma/Applet --install "$SCRIPT_DIR/plasmoid" 2>/dev/null \
    || kpackagetool6 --type Plasma/Applet --upgrade "$SCRIPT_DIR/plasmoid"

# Install systemd user service
SYSTEMD_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_DIR"
cat > "$SYSTEMD_DIR/clawd-usage.service" << EOF
[Unit]
Description=Clawd Usage state daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=$PYTHON_BIN main.py
WorkingDirectory=$PROJECT_DIR
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now clawd-usage.service

echo "Installed. Add widget: right-click panel -> Add Widgets -> Clawd Usage."
