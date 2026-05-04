"""Donut-style usage icon rendering via Cairo."""

import math
import os
import tempfile

import cairo

ICON_SIZE = 64

CLAUDE_ORANGE = (0.89, 0.44, 0.25)
ORANGE_DARK   = (1.00, 0.55, 0.10)
RED           = (0.95, 0.25, 0.25)
TRACK_GREY    = (0.70, 0.70, 0.70, 0.45)
TEXT_WHITE    = (1.00, 1.00, 1.00, 1.00)
ERROR_RED     = (0.95, 0.30, 0.30, 1.00)

_icon_paths = [None, None]
_icon_idx = 0


def _make_icon_path() -> str:
    """Alternate paths so AppIndicator detects the icon change."""
    global _icon_idx
    _icon_idx = 1 - _icon_idx
    if _icon_paths[_icon_idx] is None:
        fd, path = tempfile.mkstemp(suffix=".png", prefix="claude_usage_")
        os.close(fd)
        _icon_paths[_icon_idx] = path
    return _icon_paths[_icon_idx]


def _arc_colour(frac: float) -> tuple:
    if frac < 0.5:
        return CLAUDE_ORANGE
    if frac < 0.75:
        return ORANGE_DARK
    return RED


def render_icon(pct: float, error: bool = False) -> str:
    size    = ICON_SIZE
    path    = _make_icon_path()
    surf    = cairo.ImageSurface(cairo.FORMAT_ARGB32, size, size)
    ctx     = cairo.Context(surf)
    cx, cy  = size / 2, size / 2
    r_outer = size / 2 - 4
    stroke  = size * 0.18
    frac    = max(0.0, min(1.0, pct / 100.0))

    ctx.set_source_rgba(0, 0, 0, 0)
    ctx.paint()

    ctx.set_source_rgba(*TRACK_GREY)
    ctx.set_line_width(stroke)
    ctx.arc(cx, cy, r_outer, 0, 2 * math.pi)
    ctx.stroke()

    if error:
        ctx.set_source_rgba(*ERROR_RED)
        ctx.set_line_width(stroke * 0.8)
        ctx.set_line_cap(cairo.LINE_CAP_ROUND)
        off = r_outer * 0.5
        ctx.move_to(cx - off, cy - off); ctx.line_to(cx + off, cy + off); ctx.stroke()
        ctx.move_to(cx + off, cy - off); ctx.line_to(cx - off, cy + off); ctx.stroke()
    else:
        ctx.set_source_rgba(*_arc_colour(frac), 1.0)
        ctx.set_line_width(stroke)
        ctx.set_line_cap(cairo.LINE_CAP_ROUND)
        if frac > 0:
            start = -math.pi / 2
            end   = start + frac * 2 * math.pi
            ctx.arc(cx, cy, r_outer, start, end)
            ctx.stroke()

        label = f"{int(round(pct))}"
        ctx.select_font_face("Sans", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
        ctx.set_font_size(size * (0.42 if len(label) <= 2 else 0.34))
        x_bearing, y_bearing, w, h, _, _ = ctx.text_extents(label)
        ctx.set_source_rgba(*TEXT_WHITE)
        ctx.move_to(cx - w / 2 - x_bearing, cy - h / 2 - y_bearing)
        ctx.show_text(label)

    surf.write_to_png(path)
    return path
