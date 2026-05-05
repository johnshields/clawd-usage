"""Headless daemon: polls Anthropic usage API + writes state file for plasmoid."""

import logging
import time

from src.oauth import OAuthPoller

POLL_INTERVAL_S = 300

logging.basicConfig(level=logging.WARNING)


def main():
    poller = OAuthPoller()
    while True:
        poller.poll_once()
        time.sleep(POLL_INTERVAL_S)


if __name__ == "__main__":
    main()
