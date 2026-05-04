"""Anthropic OAuth token management + usage API polling."""

import json
import logging
import os
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

log = logging.getLogger("claude_donut")

CREDENTIALS_FILE = Path.home() / ".claude" / ".credentials.json"
STATE_FILE       = Path.home() / ".claude" / "usage-bar-state.json"

CLAUDE_CODE_CLIENT_ID  = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
TOKEN_ENDPOINT         = "https://api.anthropic.com/v1/oauth/token"
USAGE_ENDPOINT         = "https://api.anthropic.com/api/oauth/usage"
ANTHROPIC_BETA_HEADER  = "oauth-2025-04-20"
HTTP_TIMEOUT_S         = 15
DEFAULT_TOKEN_TTL_S    = 28800
TOKEN_REFRESH_BUFFER_S = 300


def _atomic_write_json(path: Path, data: dict) -> bool:
    try:
        tmp_fd, tmp_path = tempfile.mkstemp(dir=str(path.parent), suffix=".tmp")
        with os.fdopen(tmp_fd, "w", encoding="utf-8") as f:
            json.dump(data, f)
        os.rename(tmp_path, str(path))
        return True
    except OSError:
        return False


class OAuthPoller:
    def __init__(self):
        self._access_token     = None
        self._refresh_token    = None
        self._token_expires_at = 0.0
        self._rate_limit_until = 0.0
        self._consecutive_429s = 0
        self._load_credentials()

    def _load_credentials(self) -> bool:
        try:
            data  = json.loads(CREDENTIALS_FILE.read_text(encoding="utf-8"))
            oauth = data.get("claudeAiOauth", {})
            self._refresh_token    = oauth.get("refreshToken")
            self._access_token     = oauth.get("accessToken")
            expires_ms             = oauth.get("expiresAt", 0)
            self._token_expires_at = expires_ms / 1000 if expires_ms else 0
            return bool(self._refresh_token)
        except (json.JSONDecodeError, OSError) as e:
            log.warning("Failed to load credentials: %s", e)
            return False

    def _refresh_access_token(self) -> bool:
        if not self._refresh_token:
            return False
        payload = json.dumps({
            "grant_type":    "refresh_token",
            "refresh_token": self._refresh_token,
            "client_id":     CLAUDE_CODE_CLIENT_ID,
        }).encode("utf-8")
        req = Request(TOKEN_ENDPOINT, data=payload,
                      headers={"Content-Type": "application/json"}, method="POST")
        try:
            with urlopen(req, timeout=HTTP_TIMEOUT_S) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            self._access_token     = data["access_token"]
            self._token_expires_at = time.time() + data.get("expires_in", DEFAULT_TOKEN_TTL_S)
            new_refresh = data.get("refresh_token")
            if new_refresh:
                self._refresh_token = new_refresh
                self._save_credentials(data)
            self._consecutive_429s = 0
            self._rate_limit_until = 0
            return True
        except (HTTPError, URLError, json.JSONDecodeError, KeyError) as e:
            log.warning("Token refresh failed: %s", e)
            return False

    def _save_credentials(self, token_data: dict) -> None:
        try:
            existing = json.loads(CREDENTIALS_FILE.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            existing = {}
        oauth = existing.setdefault("claudeAiOauth", {})
        oauth["accessToken"]  = token_data["access_token"]
        oauth["refreshToken"] = token_data.get("refresh_token", self._refresh_token)
        oauth["expiresAt"]    = int(self._token_expires_at * 1000)
        _atomic_write_json(CREDENTIALS_FILE, existing)

    def _ensure_valid_token(self) -> bool:
        if self._access_token and time.time() < (self._token_expires_at - TOKEN_REFRESH_BUFFER_S):
            return True
        return self._refresh_access_token()

    def fetch_usage(self) -> dict | None:
        if time.time() < self._rate_limit_until:
            return None
        if not self._ensure_valid_token():
            return None
        req = Request(USAGE_ENDPOINT, headers={
            "Authorization":  f"Bearer {self._access_token}",
            "anthropic-beta": ANTHROPIC_BETA_HEADER,
        }, method="GET")
        try:
            with urlopen(req, timeout=HTTP_TIMEOUT_S) as resp:
                self._consecutive_429s = 0
                return json.loads(resp.read().decode("utf-8"))
        except HTTPError as e:
            if e.code == 401 and self._refresh_access_token():
                return self.fetch_usage()
            if e.code == 429:
                self._consecutive_429s += 1
                if self._consecutive_429s <= 2 and self._refresh_access_token():
                    return self.fetch_usage()
                backoff = min(600, 60 * (2 ** (self._consecutive_429s - 2)))
                self._rate_limit_until = time.time() + backoff
                return None
            log.warning("Usage fetch failed: HTTP %s", e.code)
            return None
        except (URLError, json.JSONDecodeError) as e:
            log.warning("Usage fetch failed: %s", e)
            return None

    def write_state(self, usage: dict) -> None:
        five_hour = usage.get("five_hour") or {}
        seven_day = usage.get("seven_day") or {}
        state = {
            "used_percentage":      five_hour.get("utilization", 0),
            "resets_at":            five_hour.get("resets_at"),
            "seven_day_percentage": seven_day.get("utilization", 0),
            "seven_day_resets_at":  seven_day.get("resets_at"),
            "updated_at":           datetime.now(timezone.utc).isoformat(),
            "source":               "oauth_api",
        }
        _atomic_write_json(STATE_FILE, state)

    def poll_once(self) -> dict | None:
        usage = self.fetch_usage()
        if usage:
            self.write_state(usage)
        return usage
