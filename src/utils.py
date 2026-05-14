"""Small IO + math helpers reused across modules."""

import json
import os
import subprocess
import tempfile
from pathlib import Path
from typing import Any
from urllib.request import Request, urlopen

from .constants import HTTP_TIMEOUT_S, IS_MACOS, KEYCHAIN_SERVICE


def read_json(path: Path, default: Any = None) -> Any:
    """Read + parse JSON. Return default on missing/corrupt file."""
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return default


def atomic_write_json(path: Path, data: dict) -> bool:
    """Write JSON atomically via temp file + rename. Return False on failure."""
    try:
        tmp_fd, tmp_path = tempfile.mkstemp(dir=str(path.parent), suffix=".tmp")
        with os.fdopen(tmp_fd, "w", encoding="utf-8") as f:
            json.dump(data, f)
        os.rename(tmp_path, str(path))
        return True
    except OSError:
        return False


def request_json(url: str, *, method: str, headers: dict, body: bytes | None = None) -> dict:
    """HTTP wrapper returning parsed JSON. Raises HTTPError/URLError on failure."""
    req = Request(url, data=body, headers=headers, method=method)
    with urlopen(req, timeout=HTTP_TIMEOUT_S) as resp:
        return json.loads(resp.read().decode("utf-8"))


def exponential_backoff(attempt: int, base_s: int, cap_s: int) -> int:
    """Return min(cap, base * 2^attempt). Clamps negative attempt to 0."""
    return min(cap_s, base_s * (2 ** max(0, attempt)))


def _get_macos_user() -> str:
    """Return current macOS username for keychain account lookup."""
    return os.environ.get("USER", os.getlogin())


def read_keychain_credentials() -> dict:
    """Read Claude Code credentials from macOS Keychain. Return parsed JSON or {}."""
    try:
        result = subprocess.run(
            ["security", "find-generic-password",
             "-s", KEYCHAIN_SERVICE, "-a", _get_macos_user(), "-w"],
            capture_output=True, text=True, timeout=5,
        )
        if result.returncode == 0 and result.stdout.strip():
            return json.loads(result.stdout.strip())
    except (subprocess.TimeoutExpired, json.JSONDecodeError, OSError):
        pass
    return {}


def write_keychain_credentials(data: dict) -> bool:
    """Write Claude Code credentials to macOS Keychain. Return False on failure."""
    try:
        payload = json.dumps(data)
        account = _get_macos_user()
        subprocess.run(
            ["security", "delete-generic-password",
             "-s", KEYCHAIN_SERVICE, "-a", account],
            capture_output=True, timeout=5,
        )
        result = subprocess.run(
            ["security", "add-generic-password",
             "-s", KEYCHAIN_SERVICE, "-a", account,
             "-w", payload, "-U"],
            capture_output=True, timeout=5,
        )
        return result.returncode == 0
    except (subprocess.TimeoutExpired, OSError):
        return False
