#!/bin/bash
# Diagnose Clawd Usage install.

ok()  { echo "  [ok]   $1"; }
bad() { echo "  [bad]  $1"; }
warn(){ echo "  [warn] $1"; }

echo "Clawd Usage diagnostics"

for cmd in python3 kpackagetool6 systemctl; do
    command -v "$cmd" >/dev/null 2>&1 && ok "$cmd present" || bad "$cmd missing"
done

PLASMA_VER="$(plasmashell --version 2>/dev/null | awk '{print $2}')"
case "$PLASMA_VER" in
    6.*) ok "Plasma $PLASMA_VER" ;;
    "")  warn "plasmashell not found" ;;
    *)   warn "Plasma $PLASMA_VER (need 6.x)" ;;
esac

[ -f "$HOME/.claude/.credentials.json" ] \
    && ok "claude credentials present" \
    || bad "$HOME/.claude/.credentials.json missing — run 'claude login'"

kpackagetool6 --type Plasma/Applet --show com.john.clawdusage >/dev/null 2>&1 \
    && ok "plasmoid installed" \
    || bad "plasmoid not installed — run ./install.sh"

[ -f "$HOME/.local/share/icons/hicolor/scalable/apps/clawd-logo.svg" ] \
    && ok "icon installed" \
    || warn "icon missing — Add Widgets shows generic placeholder"

if systemctl --user is-active --quiet clawd-usage.service; then
    ok "daemon active"
else
    bad "daemon inactive — systemctl --user start clawd-usage.service"
fi

STATE="$HOME/.claude/usage-bar-state.json"
if [ -f "$STATE" ]; then
    AGE=$(( $(date +%s) - $(stat -c %Y "$STATE") ))
    if [ "$AGE" -lt 120 ]; then
        ok "state fresh (${AGE}s)"
    else
        warn "state stale (${AGE}s) — daemon may be failing"
    fi
else
    bad "state file missing — daemon never ran successfully"
fi
