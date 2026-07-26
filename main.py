"""Headless daemon: polls Anthropic usage API + writes state file for plasmoid."""

import logging
import os
import signal
import time

from src.constants import PID_FILE
from src.oauth import OAuthPoller

POLL_INTERVAL_S = 60

logging.basicConfig(level=logging.WARNING)


class _WakeUp(Exception):
    """Raised by SIGUSR1 handler to cut a poll cycle short."""


def _handle_wake(signum, frame):
    raise _WakeUp()


def main():
    PID_FILE.write_text(str(os.getpid()))
    signal.signal(signal.SIGUSR1, _handle_wake)

    poller = OAuthPoller()
    while True:
        try:
            poller.poll_once()
            time.sleep(POLL_INTERVAL_S)
        except _WakeUp:
            continue


if __name__ == "__main__":
    main()
