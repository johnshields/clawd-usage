# Clawd Usage

![claude_orange](img/claude_orange.png) ![claude_red](img/claude_red.png)

KDE Plasma 6 widget showing Claude Code 5h rate limit usage. Claw'd mascot fills bottom-up; popup shows 5h/7d bars + reset countdown.

Two parts:
- **Daemon** — Python (stdlib only). Refreshes OAuth token, polls `api.anthropic.com/api/oauth/usage`, writes `~/.claude/usage-bar-state.json`.
- **Plasmoid** — QML widget. Reads state file every 5s, renders Claw'd icon.

Requires Claude Code logged in (`~/.claude/.credentials.json` exists).

## Install

```sh
git clone https://github.com/johnshields/clawd-usage ~/Projects/clawd-usage
cd ~/Projects/clawd-usage
kpackagetool6 --type Plasma/Applet --install plasmoid
```

Add widget: right-click panel → **Add Widgets** → search **Clawd Usage**.

## Daemon (systemd)

```sh
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/clawd-usage.service << 'EOF'
[Unit]
Description=Clawd Usage state daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 main.py
WorkingDirectory=%h/Projects/clawd-usage
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now clawd-usage.service
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
