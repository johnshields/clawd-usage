# Clawd Usage

![clawd_usage](/img/clawd_usage.png)

KDE Plasma 6 widget showing Claude Code 5h rate limit usage. Claw'd mascot fills bottom-up; popup shows 5h/7d bars + reset countdown.

Two parts:
- **Daemon** — Python (stdlib only). Refreshes OAuth token, polls `api.anthropic.com/api/oauth/usage`, writes `~/.claude/usage-bar-state.json`.
- **Plasmoid** — QML widget. Reads state file every 5s, renders Claw'd icon.

Requires Claude Code logged in (`~/.claude/.credentials.json` exists).

## Install

```sh
git clone https://github.com/johnshields/clawd-usage ~/Projects/clawd-usage
cd ~/Projects/clawd-usage
./install.sh
```

`install.sh` ships the plasmoid via `kpackagetool6`, installs the icon to `~/.local/share/icons`, and sets up + starts the systemd user service.

Add widget: right-click panel → **Add Widgets** → search **Clawd Usage**.

## Diagnose

```sh
./doctor.sh
```

Reports daemon status, state freshness, plasmoid install, credentials, icon. Use first when something looks off.

## Uninstall

```sh
./uninstall.sh
```

Removes systemd service, plasmoid, icon, state file.

## Update plasmoid after edits

```sh
kpackagetool6 --type Plasma/Applet --upgrade plasmoid
kquitapp6 plasmashell && kstart plasmashell
```

## Layout

```
install.sh / uninstall.sh / doctor.sh
main.py                          daemon entry (stdlib only)
src/oauth.py                     OAuth refresh + usage API + state writer
src/constants.py                 paths, endpoints, tunables
src/utils.py                     read/atomic-write JSON, request_json, backoff
plasmoid/metadata.json           plasmoid manifest
plasmoid/contents/ui/main.qml    widget UI (Canvas creature + popup)
plasmoid/contents/ui/ClawdIcon.qml  reusable filling-creature component
plasmoid/contents/config/        KConfig schema + config UI
plasmoid/contents/icons/         silhouette + eyes + logo SVG
```

## Requires

- Linux + KDE Plasma 6
- Python 3.10+
- `kpackagetool6`, `systemctl` (standard with Plasma 6)
- Claude Code authenticated (`~/.claude/.credentials.json`)
