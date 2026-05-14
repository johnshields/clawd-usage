#!/bin/bash
# Diagnose Clawd Usage macOS install.

ok()  { echo "  [ok]   $1"; }
bad() { echo "  [bad]  $1"; }
warn(){ echo "  [warn] $1"; }

echo "Clawd Usage (macOS) diagnostics"
echo ""

# Tools
command -v python3 >/dev/null 2>&1 && ok "python3 present" || bad "python3 missing"
command -v swiftc >/dev/null 2>&1 && ok "swiftc present" || bad "swiftc missing (xcode-select --install)"

# macOS version
SW_VER=$(sw_vers -productVersion 2>/dev/null || echo "")
MAJOR=$(echo "$SW_VER" | cut -d. -f1)
if [ -z "$SW_VER" ]; then
    warn "could not detect macOS version"
elif [ "$MAJOR" -ge 13 ] 2>/dev/null; then
    ok "macOS $SW_VER"
else
    warn "macOS $SW_VER (need 13+)"
fi

# Claude credentials (keychain on macOS, file on Linux)
if security find-generic-password -s "Claude Code-credentials" -a "$(whoami)" -w >/dev/null 2>&1; then
    ok "claude credentials present (keychain)"
elif [ -f "$HOME/.claude/.credentials.json" ]; then
    ok "claude credentials present (file)"
else
    bad "claude credentials missing — run 'claude auth login'"
fi

# App installed
APP_PATH="$HOME/Applications/Clawd Usage.app"
[ -d "$APP_PATH" ] \
    && ok "app installed" \
    || bad "app not installed — run ./install.sh"

# Daemon
DAEMON_LABEL="com.john.clawdusage.daemon"
if launchctl print "gui/$(id -u)/$DAEMON_LABEL" >/dev/null 2>&1; then
    ok "daemon active"
else
    bad "daemon inactive — run ./install.sh"
fi

# State file
STATE="$HOME/.claude/usage-bar-state.json"
if [ -f "$STATE" ]; then
    AGE=$(( $(date +%s) - $(stat -f %m "$STATE") ))
    if [ "$AGE" -lt 120 ]; then
        ok "state fresh (${AGE}s)"
    else
        warn "state stale (${AGE}s) — daemon may be failing"
    fi
else
    bad "state file missing — daemon never ran successfully"
fi

# Menu bar app running
if pgrep -x "ClawdUsage" >/dev/null 2>&1; then
    ok "menu bar app running"
else
    warn "menu bar app not running — open '$APP_PATH'"
fi
