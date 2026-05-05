# Claude Donut

KDE Plasma 6 widget showing Claude Code 5h rate limit usage. Asterisk fills bottom-up; popup shows 5h/7d bars + reset countdown.

Two parts:
- **Daemon** — Python (stdlib only). Refreshes OAuth token, polls `api.anthropic.com/api/oauth/usage`, writes `~/.claude/usage-bar-state.json`.
- **Plasmoid** — QML widget. Reads state file every 5s, renders Claude asterisk.

Requires Claude Code logged in (`~/.claude/.credentials.json` exists).

## Install

```sh
git clone https://github.com/johnshields/claude-donut ~/Projects/claude-donut
cd ~/Projects/claude-donut
kpackagetool6 --type Plasma/Applet --install plasmoid
```

Add widget: right-click panel → **Add Widgets** → search **Claude Donut**.

## Daemon (systemd)

```sh
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/claude-donut.service << 'EOF'
[Unit]
Description=Claude Donut state daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 main.py
WorkingDirectory=%h/Projects/claude-donut
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now claude-donut.service
```

## Update plasmoid after edits

```sh
kpackagetool6 --type Plasma/Applet --upgrade plasmoid
kquitapp6 plasmashell && kstart plasmashell
```

## Layout

```
main.py                       daemon entry (stdlib only)
src/oauth.py                  OAuth refresh + usage API + state writer
plasmoid/metadata.json        plasmoid manifest
plasmoid/contents/ui/main.qml widget UI (Canvas asterisk + popup)
```
