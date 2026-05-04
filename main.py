"""Entry point: python3 main.py"""

import logging

from src.tray import UsageTray

logging.basicConfig(level=logging.WARNING)

if __name__ == "__main__":
    UsageTray().run()
