"""Project-wide constants."""

from pathlib import Path

# Paths
CREDENTIALS_FILE = Path.home() / ".claude" / ".credentials.json"
STATE_FILE       = Path.home() / ".claude" / "usage-bar-state.json"

# OAuth + API
CLAUDE_CODE_CLIENT_ID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
TOKEN_ENDPOINT        = "https://api.anthropic.com/v1/oauth/token"
USAGE_ENDPOINT        = "https://api.anthropic.com/api/oauth/usage"
ANTHROPIC_BETA_HEADER = "oauth-2025-04-20"

# Token lifecycle
DEFAULT_TOKEN_TTL_S    = 28800
TOKEN_REFRESH_BUFFER_S = 300

# 429 backoff
MAX_429_REFRESH_RETRIES = 2
BACKOFF_BASE_S          = 60
MAX_BACKOFF_S           = 600
