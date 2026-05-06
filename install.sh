#!/bin/bash
# Installs Clawd Usage plasmoid + daemon service.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Install icon to user theme so plasmoid Icon field resolves
install -Dm644 "$PROJECT_DIR/plasmoid/contents/icons/clawd-logo.svg" \
    "$HOME/.local/share/icons/hicolor/scalable/apps/clawd-logo.svg" 2>/dev/null || \
    {
        # No SVG yet — generate from PNG
        python3 -c "
import base64
b = base64.b64encode(open('$PROJECT_DIR/plasmoid/contents/icons/clawd-logo.png', 'rb').read()).decode()
import os
os.makedirs(os.path.expanduser('~/.local/share/icons/hicolor/scalable/apps'), exist_ok=True)
open(os.path.expanduser('~/.local/share/icons/hicolor/scalable/apps/clawd-logo.svg'), 'w').write(
    f'<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" viewBox=\"0 0 114 81\" width=\"114\" height=\"81\"><image x=\"0\" y=\"0\" width=\"114\" height=\"81\" xlink:href=\"data:image/png;base64,{b}\"/></svg>'
)"
    }

# Install plasmoid
kpackagetool6 --type Plasma/Applet --install "$PROJECT_DIR/plasmoid" 2>/dev/null \
    || kpackagetool6 --type Plasma/Applet --upgrade "$PROJECT_DIR/plasmoid"

# Install systemd user service
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/clawd-usage.service << EOF
[Unit]
Description=Clawd Usage state daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 main.py
WorkingDirectory=$PROJECT_DIR
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now clawd-usage.service

echo "Installed. Add widget: right-click panel -> Add Widgets -> Clawd Usage."
