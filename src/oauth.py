"""Anthropic OAuth token management + usage API polling."""

import json
import logging
import time
from datetime import datetime, timezone
from urllib.error import HTTPError, URLError

from .constants import *  # noqa: F401, F403
from .utils import (
    atomic_write_json, exponential_backoff, read_json,
    read_keychain_credentials, request_json, write_keychain_credentials,
)

log = logging.getLogger("clawd_usage")


class OAuthPoller:
    def __init__(self):
        self._access_token     = None
        self._refresh_token    = None
        self._token_expires_at = 0.0
        self._rate_limit_until = 0.0
        self._consecutive_429s = 0
        self._load_credentials()

    def _load_credentials(self) -> None:
        if IS_MACOS:
            store = read_keychain_credentials()
        else:
            store = read_json(CREDENTIALS_FILE, default={}) or {}
        oauth = store.get("claudeAiOauth", {})
        self._refresh_token    = oauth.get("refreshToken")
        self._access_token     = oauth.get("accessToken")
        expires_ms             = oauth.get("expiresAt", 0)
        self._token_expires_at = expires_ms / 1000 if expires_ms else 0

    def _save_credentials(self) -> None:
        if IS_MACOS:
            existing = read_keychain_credentials()
        else:
            existing = read_json(CREDENTIALS_FILE, default={}) or {}
        oauth = existing.setdefault("claudeAiOauth", {})
        oauth["accessToken"]  = self._access_token
        oauth["refreshToken"] = self._refresh_token
        oauth["expiresAt"]    = int(self._token_expires_at * 1000)
        if IS_MACOS:
            write_keychain_credentials(existing)
        else:
            atomic_write_json(CREDENTIALS_FILE, existing)

    def _refresh_access_token(self) -> bool:
        if not self._refresh_token:
            return False
        body = json.dumps({
            "grant_type":    "refresh_token",
            "refresh_token": self._refresh_token,
            "client_id":     CLAUDE_CODE_CLIENT_ID,
        }).encode("utf-8")
        try:
            data = request_json(TOKEN_ENDPOINT, method="POST",
                                headers={"Content-Type": "application/json"}, body=body)
            self._access_token = data["access_token"]
        except (HTTPError, URLError, json.JSONDecodeError, KeyError) as e:
            log.warning("Token refresh failed: %s", e)
            return False
        self._token_expires_at = time.time() + data.get("expires_in", DEFAULT_TOKEN_TTL_S)
        self._refresh_token    = data.get("refresh_token") or self._refresh_token
        self._save_credentials()
        self._consecutive_429s = 0
        self._rate_limit_until = 0
        return True

    def _ensure_valid_token(self) -> bool:
        if self._access_token and time.time() < (self._token_expires_at - TOKEN_REFRESH_BUFFER_S):
            return True
        return self._refresh_access_token()

    def fetch_usage(self) -> dict | None:
        if time.time() < self._rate_limit_until or not self._ensure_valid_token():
            return None
        headers = {
            "Authorization":  f"Bearer {self._access_token}",
            "anthropic-beta": ANTHROPIC_BETA_HEADER,
        }
        try:
            data = request_json(USAGE_ENDPOINT, method="GET", headers=headers)
            self._consecutive_429s = 0
            return data
        except HTTPError as e:
            if e.code == 401 and self._refresh_access_token():
                return self.fetch_usage()
            if e.code == 429:
                self._consecutive_429s += 1
                if self._consecutive_429s <= MAX_429_REFRESH_RETRIES and self._refresh_access_token():
                    return self.fetch_usage()
                self._rate_limit_until = time.time() + exponential_backoff(
                    self._consecutive_429s - MAX_429_REFRESH_RETRIES, BACKOFF_BASE_S, MAX_BACKOFF_S)
            else:
                log.warning("Usage fetch failed: HTTP %s", e.code)
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
        atomic_write_json(STATE_FILE, state)

    def poll_once(self) -> dict | None:
        usage = self.fetch_usage()
        if usage:
            self.write_state(usage)
        return usage
