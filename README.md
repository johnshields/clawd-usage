# Claude Donut

Linux system tray donut showing Claude Code 5-hour rate limit usage. KDE/GNOME/XFCE.

## Install

```sh
# Arch
sudo pacman -S python-cairo python-gobject gtk3 libappindicator-gtk3
# Debian/Ubuntu
sudo apt install python3-cairo python3-gi gir1.2-gtk-3.0 gir1.2-appindicator3-0.1
```

Requires Claude Code logged in (`~/.claude/.credentials.json` exists).

## Run

```sh
python3 main.py
```

## Boot via systemd

```sh
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/claude-donut.service << 'EOF'
[Unit]
Description=Claude Donut tray indicator
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

systemctl --user enable --now claude-donut.service
```

## Layout

```
main.py    entry
src/
  oauth.py  token refresh + usage API
  icon.py   Cairo donut
  tray.py   GTK AppIndicator
```
