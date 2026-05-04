"""GTK system tray indicator."""

import threading
from datetime import datetime, timezone

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('AppIndicator3', '0.1')
from gi.repository import Gtk, GLib
from gi.repository import AppIndicator3 as AppIndicator

from .icon import render_icon
from .oauth import OAuthPoller

API_POLL_INTERVAL_S = 300


def _format_resets(resets_at: str | None) -> str:
    if not resets_at:
        return ""
    try:
        dt   = datetime.fromisoformat(resets_at.replace("Z", "+00:00"))
        mins = int((dt - datetime.now(timezone.utc)).total_seconds() / 60)
        hrs, m = divmod(max(0, mins), 60)
        return f"Resets in {hrs}h {m:02d}m"
    except ValueError:
        return f"Resets: {resets_at[:16]}"


class UsageTray:
    AUTH_ERROR_LABEL = "5h: auth error — run: claude logout && claude login"

    def __init__(self):
        self.poller      = OAuthPoller()
        self.five_pct    = 0.0
        self.seven_pct   = 0.0
        self.resets_at   = None
        self.error       = False
        self._stop_event = threading.Event()

        self.ind = AppIndicator.Indicator.new(
            "1claude-donut",
            render_icon(0),
            AppIndicator.IndicatorCategory.APPLICATION_STATUS,
        )
        self.ind.set_status(AppIndicator.IndicatorStatus.ACTIVE)
        self.ind.set_title("1Claude Donut")

        self.item_5h    = Gtk.MenuItem(label="5h: --")
        self.item_7d    = Gtk.MenuItem(label="7d: --")
        self.item_reset = Gtk.MenuItem(label="Resets: --")
        item_refresh    = Gtk.MenuItem(label="Refresh now")
        item_quit       = Gtk.MenuItem(label="Quit")
        item_refresh.connect("activate", self._on_refresh)
        item_quit.connect("activate", self._on_quit)

        menu = Gtk.Menu()
        for item in (self.item_5h, self.item_7d, self.item_reset,
                     Gtk.SeparatorMenuItem(), item_refresh, item_quit):
            menu.append(item)
        menu.show_all()
        self.ind.set_menu(menu)

        threading.Thread(target=self._poll_loop, daemon=True).start()

    def _poll_loop(self):
        while not self._stop_event.is_set():
            self._do_poll()
            self._stop_event.wait(API_POLL_INTERVAL_S)

    def _do_poll(self):
        usage = self.poller.poll_once()
        if usage:
            fh = usage.get("five_hour") or {}
            sd = usage.get("seven_day") or {}
            self.five_pct  = float(fh.get("utilization", 0))
            self.seven_pct = float(sd.get("utilization", 0))
            self.resets_at = fh.get("resets_at")
            self.error     = False
        else:
            self.error = True
        GLib.idle_add(self._update_ui)

    def _update_ui(self):
        pct_int = int(self.five_pct)
        self.ind.set_icon_full(render_icon(self.five_pct, self.error), f"{pct_int}%")
        self.ind.set_title(f"1Donut {pct_int}%")

        if self.error:
            self.item_5h.set_label(self.AUTH_ERROR_LABEL)
            self.item_7d.set_label("")
            self.item_reset.set_label("")
        else:
            self.item_5h.set_label(f"5h:  {self.five_pct:.0f}%")
            self.item_7d.set_label(f"7d:  {self.seven_pct:.0f}%")
            self.item_reset.set_label(_format_resets(self.resets_at))
        return False

    def _on_refresh(self, _):
        threading.Thread(target=self._do_poll, daemon=True).start()

    def _on_quit(self, _):
        self._stop_event.set()
        Gtk.main_quit()

    def run(self):
        Gtk.main()
