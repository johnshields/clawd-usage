# Clawd Usage

![clawd_usage](/img/clawd-usage_linux.png) ![clawd_usage](/img/clawd-usage_mac.png)

Shows Claude Code rate limit usage in your desktop panel. Claw'd mascot fills bottom-up; popup shows 5h/7d bars + reset countdown.

Two parts:
- **Daemon** — Python (stdlib only). Refreshes OAuth token, polls `api.anthropic.com/api/oauth/usage`, writes `~/.claude/usage-bar-state.json`. Shared across platforms.
- **UI** — Platform-native widget reads state file, renders Claw'd icon.

Requires Claude Code logged in (`claude auth login`).

## Linux (KDE Plasma 6)

```sh
git clone https://github.com/johnshields/clawd-usage ~/Projects/clawd-usage
cd ~/Projects/clawd-usage/linux
./install.sh
```

Ships plasmoid via `kpackagetool6`, installs icon, starts systemd user service.

Add widget: right-click panel → **Add Widgets** → search **Clawd Usage**.

**Diagnose:** `./doctor.sh` · **Uninstall:** `./uninstall.sh`

**Update plasmoid after edits:**
```sh
kpackagetool6 --type Plasma/Applet --upgrade linux/plasmoid
kquitapp6 plasmashell && kstart plasmashell
```

## macOS

```sh
git clone https://github.com/johnshields/clawd-usage ~/Projects/clawd-usage
cd ~/Projects/clawd-usage/macos
./install.sh
```

Compiles SwiftUI menu bar app, installs to `~/Applications`, starts launchd daemon.

Left-click → usage popup. Right-click → Settings / Quit.

**Diagnose:** `./doctor.sh` · **Uninstall:** `./uninstall.sh`

To start on login: System Settings → General → Login Items → add **Clawd Usage**.

## Layout

```
main.py                          daemon entry (stdlib only)
src/oauth.py                     OAuth refresh + usage API + state writer
src/constants.py                 paths, endpoints, tunables
src/utils.py                     IO helpers, keychain support (macOS)

linux/install.sh / uninstall.sh / doctor.sh   Linux scripts
linux/plasmoid/                              KDE Plasma 6 widget (QML)

macos/install.sh / uninstall.sh / doctor.sh  macOS scripts
macos/Sources/                               SwiftUI menu bar app
```

## Requires

**Linux:** KDE Plasma 6, Python 3.10+, `kpackagetool6`, `systemctl`

**macOS:** macOS 13+, Python 3.10+, Xcode Command Line Tools (`xcode-select --install`)
