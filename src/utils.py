"""Small IO + math helpers reused across modules."""

import json
import os
import tempfile
from pathlib import Path
from typing import Any
from urllib.request import Request, urlopen

HTTP_TIMEOUT_S = 15


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
