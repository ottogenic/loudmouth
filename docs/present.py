#!/usr/bin/env python3
"""
present.py -- a dependency-free terminal slide deck for the LOUDMOUTH talk.

Runs in the right split of a herdr terminal while the agent demo runs on the left.
Stdlib only (no pip install). Left/Right arrows move between slides.

  Controls
    Right l  space          next build step (rolls to next slide at the end)
    Left  h                 previous build step (rolls to prev slide at the start)
    Down  j  n  PgDn        reveal the whole slide, then advance to the next
    Up    k  p  b  PgUp     previous slide (a revisited slide rebuilds from scratch)
    g / Home                first slide
    G / End                 last slide
    1..9                    jump to slide N
    + / -                   zoom in / out (cell zoom -- every glyph scales up)
    0                       auto zoom (largest factor that fits the pane)
    q / Esc / Ctrl-C        quit

  Most slides have no build steps, so Left/Right just page through them. The
  REQUIREMENT 2 and runbook slides build out in stages -- Right clicks them in
  one element at a time; Down snaps a slide fully open before moving on.

  Preview without a TTY (for editing the art):
    python present.py --dump                 # all slides, 78x26, no color
    python present.py --dump --width 60 --height 20   # see the center-crop
    python present.py --dump --only 1 --color
    python present.py --dump --only 4 --step 3 --color   # a single build stage

The renderer keeps every slide centered in the terminal. When the pane is
smaller than a slide it crops symmetrically from the center (the edges trim in);
when larger it pads with centered whitespace. Resizing redraws automatically.
"""

import os
import re
import sys
import shutil
import argparse

IS_WIN = os.name == "nt"

# ---------------------------------------------------------------------------
# Styling
# ---------------------------------------------------------------------------

RESET = "\x1b[0m"
STYLES = {
    "b": "\x1b[1m",
    "d": "\x1b[2m",
    "i": "\x1b[3m",
    "u": "\x1b[4m",
    "strike": "\x1b[9m",
    "red": "\x1b[38;5;203m",
    "gold": "\x1b[38;5;220m",
    "white": "\x1b[97m",
    "cyan": "\x1b[38;5;80m",
    "green": "\x1b[38;5;114m",
    "grey": "\x1b[38;5;245m",
    "blue": "\x1b[38;5;75m",
    "orange": "\x1b[38;5;209m",
    "purple": "\x1b[38;5;141m",
    "steel": "\x1b[38;5;110m",
}

COLOR = True  # toggled off by --no-color / NO_COLOR / dump default

_TAGRE = re.compile(r"\[([a-z]+)\]")


def _sty(name):
    return STYLES.get(name, "") if COLOR else ""


def _reset():
    return RESET if COLOR else ""


def parse_markup(s):
    """Turn '[gold][b]hi[/][/]' into a list of (ansi_prefix, plain_text) spans.

    Only bracket groups whose name is a known style are treated as tags; every
    other '[' passes through as a literal character, so slide art can freely use
    brackets (e.g. '[override]')."""
    spans = []
    stack = []
    buf = []

    def ansi():
        if not COLOR or not stack:
            return ""
        return RESET + "".join(STYLES[t] for t in stack)

    def flush():
        if buf:
            spans.append((ansi(), "".join(buf)))
            buf.clear()

    i, n = 0, len(s)
    while i < n:
        if s[i] == "[":
            if s[i : i + 3] == "[/]" and stack:
                flush()
                stack.pop()
                i += 3
                continue
            m = _TAGRE.match(s, i)
            if m and m.group(1) in STYLES:
                flush()
                stack.append(m.group(1))
                i = m.end()
                continue
        buf.append(s[i])
        i += 1
    flush()
    return spans


def plain_len(spans):
    return sum(len(t) for _, t in spans)


def padline(mk, w, align="left"):
    """Pad a markup string with (color-neutral) spaces to visual width `w`."""
    pl = plain_len(parse_markup(mk))
    if pl >= w:
        return mk
    pad = w - pl
    if align == "left":
        return mk + " " * pad
    if align == "right":
        return " " * pad + mk
    left = pad // 2
    return " " * left + mk + " " * (pad - left)


def box(inner, iw, color="steel", title=None, lead="  "):
    """Build a framed box (list of markup lines) with borders guaranteed to
    align. `inner` lines are padded to interior width `iw`."""
    c = "[" + color + "]"
    e = "[/]"
    if title:
        t = "  " + title + "  "
        dash = iw - len(t)
        lft = dash // 2
        top = lead + c + "┌" + "─" * lft + t + "─" * (dash - lft) + "┐" + e
    else:
        top = lead + c + "┌" + "─" * iw + "┐" + e
    bottom = lead + c + "└" + "─" * iw + "┘" + e
    rows = [top]
    for m in inner:
        rows.append(lead + c + "│" + e + padline(m, iw) + c + "│" + e)
    rows.append(bottom)
    return rows


def compose(spans, width):
    """Render spans to exactly `width` visible cells, centered.

    Narrower than width -> centered with whitespace padding.
    Wider than width    -> center-cropped (edges trim in symmetrically)."""
    total = plain_len(spans)
    if total <= width:
        left = (width - total) // 2
        right = width - total - left
        body = "".join(a + t for a, t in spans)
        return " " * left + body + _reset() + " " * right
    # center-crop to columns [skip, skip+width)
    skip = (total - width) // 2
    out = []
    pos = 0
    used = 0
    for a, t in spans:
        if used >= width:
            break
        if pos + len(t) <= skip:
            pos += len(t)
            continue
        start = max(0, skip - pos)
        take = t[start : start + (width - used)]
        if take:
            out.append(a + take)
            used += len(take)
        pos += len(t)
    return "".join(out) + _reset()


# ---------------------------------------------------------------------------
# Cell zoom -- scale slides by an integer factor so text reads bigger on a
# projector. A terminal app cannot change the terminal's font (tmux windows all
# share one), so we scale in character cells: every glyph becomes a z-wide run
# and every line repeats z times. Box-drawing arms extend with line characters
# instead of repeating, so frames stay frames instead of stuttering corners.
# ---------------------------------------------------------------------------

ZOOM = None       # None = auto-fit (largest factor the pane can hold); int = fixed
ZOOM_MAX = 3
_LAST_ZOOM = 1    # effective factor of the last rendered frame (for +/- keys)

# Horizontal: box/block chars extend with line/fill segments so frames stay
# solid; everything else (prose) gets letterspacing, which reads far better
# than doubled letters ("N o" vs "NNoo").
_EXTEND_RIGHT = {"┌": "─", "└": "─", "├": "─", "┬": "─", "┴": "─", "┼": "─",
                 "╭": "─", "╰": "─", "─": "─", "═": "═",
                 "█": "█", "▀": "▀", "▄": "▄", "▟": "█", "▛": "█"}
_EXTEND_LEFT = {"┐": "─", "┘": "─", "┤": "─", "╮": "─", "╯": "─",
                "▙": "█", "▜": "█"}
# Vertical: what a char contributes to the duplicated row(s) BELOW it. Side
# borders and fills continue; text and horizontal rules leave clean air.
_EXTEND_DOWN = {"│": "│", "║": "║", "┌": "│", "┐": "│", "├": "│", "┤": "│",
                "┬": "│", "┼": "│", "╭": "│", "╮": "│",
                "█": "█", "▟": "█", "▙": "█", "▄": "█"}


def _hexpand(ch, z, pad_left=False):
    if z == 1:
        return ch
    if ch in _EXTEND_RIGHT:
        return ch + _EXTEND_RIGHT[ch] * (z - 1)
    if ch in _EXTEND_LEFT:
        return _EXTEND_LEFT[ch] * (z - 1) + ch
    if ch == " ":
        return " " * z
    if pad_left:  # closing border glyph: align with ┐/┘ which pad left too
        return " " * (z - 1) + ch
    return ch + " " * (z - 1)  # prose: letterspaced, not doubled


def zoom_canvas(canvas, z):
    """Scale a list of span-lines by integer factor z. Structure-aware:
    borders/fills scale as shapes, prose is letterspaced with blank rows."""
    if z <= 1:
        return canvas
    out = []
    for spans in canvas:
        # the line's LAST non-space char is its right edge: pad it left so a
        # closing │ lands in the same column as the ┐/┘ above and below it
        plain = "".join(t for _, t in spans)
        last = len(plain.rstrip()) - 1
        scaled = []
        pos = 0
        for a, t in spans:
            scaled.append((a, "".join(
                _hexpand(c, z, pad_left=(pos + k == last and c in "│║"))
                for k, c in enumerate(t))))
            pos += len(t)
        out.append(scaled)
        cont = [(a, "".join(_EXTEND_DOWN.get(c, " ") for c in t))
                for a, t in scaled]
        for _ in range(z - 1):
            out.append(cont)
    return out


def fit_zoom(canvas, cols, body_rows):
    """Largest factor (1..ZOOM_MAX) at which the slide still fits the pane."""
    w = max((plain_len(sp) for sp in canvas), default=1) or 1
    h = len(canvas) or 1
    return max(1, min(ZOOM_MAX, cols // w, body_rows // h))


# ---------------------------------------------------------------------------
# Slides -- each returns a list of entries.
#   * a plain str  -> a line CENTERED within the slide's block
#   * A(...)       -> a block of raw lines, LEFT-anchored to the block and kept
#                     internally aligned (ASCII art, diagrams, tables)
# Every line is padded to the widest line (the "block"), so the block is
# centered/cropped as one unit and art columns never drift.
# ---------------------------------------------------------------------------


class Art(list):
    pass


def A(*lines):
    return Art(lines)


def slide_title():
    return [
        "[grey]I  N  T  R  O  D  U  C  I  N  G[/]",
        "",
        "[red][b]L O U D M O U T H[/][/]",
        "",
        "[grey]a World of Warcraft Classic Era (Hardcore) addon[/]",
        "",
        A(
            "   [grey]╭────────────────────────────────────╮[/]",
            "   [grey]│[/]  [gold][b]HOW YOU LIKE ME NOW, CHINSTRAP?![/][/]  [grey]│[/]",
            "   [grey]╰─────────────────[grey]┬[/][grey]──────────────────╯[/]",
            "                     [grey]│[/]",
            "              [red]▟█████████████▙[/]",
            "              [red]█[/] [white]▀▀▀▀▀▀▀▀▀▀▀[/] [red]█[/]",
            "              [red]█[/]             [red]█[/]   [gold]) ) )[/]",
            "              [red]█[/] [white]▄▄▄▄▄▄▄▄▄▄▄[/] [red]█[/]",
            "              [red]▜█████████████▛[/]",
        ),
    ]


def slide_what(step=None):
    if step is None:
        step = slide_what.build_steps
    bubble = [  # the speech bubble + its tail down to the wizard's head
        "     [grey]╭──────────────────────────────────────╮[/]",
        "     [grey]│[/]  [cyan]Oooof... smells like malt liquor[/]    [grey]│[/]",
        "     [grey]│[/]  [cyan]and feet... Dwarfs are nasty.[/]       [grey]│[/]",
        "     [grey]╰──[grey]┬[/]───────────────────────────────────╯[/]",
        "        [grey]│[/]",
    ]
    # Each row is the wizard (cols < 14) beside the IRONFORGE signpost (cols >= 14).
    wizard = [
        "        [purple]/\\[/]",
        "       [purple]/  \\[/]              [gold] __________________[/]",
        "      [purple]/____\\[/]             [gold]|[/]                  [gold]\\[/]",
        "      [white]([/][gold]o  o[/][white])[/]             [gold]|[/]   [b][cyan]IRONFORGE[/][/]      [gold]▶[/]",
        "     [purple]<[/]  [gold]||[/]  [purple]>[/]            [gold]|__________________/[/]",
        "      [purple]/_[/][gold]||[/][purple]_\\[/]                   [gold]|[/]",
        "        [gold]||[/]                     [gold]|[/]",
        "       [purple]_[/][gold]||[/][purple]_[/]",
    ]
    # signpost is up from the start; the wizard walks in on click 1, bubble on 2.
    scene = reveal_split(wizard, 14, show_left=step >= 1, show_right=True)
    W = max(plain_len(parse_markup(ln)) for ln in bubble + scene)
    rows = [padline(ln, W) if step >= 2 else " " * W for ln in bubble]
    rows += [padline(ln, W) for ln in scene]
    return [
        "[gold][b]WHAT IT IS[/][/]",
        "",
        "[white]Personality-driven, context-aware banter.[/]",
        "[grey]reacting to spells, pets, mobs, and zones[/]",
        "",
        A(*rows),
    ]


slide_what.build_steps = 2  # 1: the wizard, 2: the speech bubble


def slide_spark():
    return [
        "[cyan][b]REQUIREMENT 1[/][/]",
        "[grey]─────────────────────[/]",
        "[gold][b]USE A DGX SPARK[/][/]",
        "",
        A(
            *box(
                [
                    "",
                    "      [blue]┌───────┐[/]                [green]┌───────┐[/]",
                    "      [blue]│ [b]ARM64[/] [blue]│[/][purple]══ NVLink-C2C ══[/][green]│  [b]GPU[/]  [green]│[/]",
                    "      [blue]└───[grey]┬[/][blue]───┘[/]                [green]└───[grey]┬[/][green]───┘[/]",
                    "          [grey]└───────────┬────────────┘[/]",
                    "      [gold]┌───────────────┴────────────────┐[/]",
                    "      [gold]│[/]    [white][b]128 GB LPDDR5X[/][/][grey] · unified[/]    [gold]│[/]",
                    "      [gold]└────────────────────────────────┘[/]",
                    "",
                ],
                iw=46,
                color="steel",
                title="GB10 SUPERCHIP",
            )
        ),
        "",
        A(
            "   [b][green]GPU[/][/]   [white]Blackwell[/] [grey]architecture · 5th-gen Tensor Cores[/]",
            "   [b][blue]CPU[/][/]   [white]20-core Arm64[/] [grey](Grace) · 10× X925 + 10× A725[/]",
            "   [b][gold]RAM[/][/]   [white]128 GB LPDDR5X[/] [grey]· unified · ~273 GB/s[/]",
            "   [b][cyan]AI[/][/]    [white]~1 PFLOP[/] [grey](1000 TFLOPS) at FP4[/]",
        ),
        "",
        "[green][b]Run AI models locally, for free[/][/][green]*[/]      [grey]([red]$5,000[/][grey])[/]",
    ]


# --- progressive "build" support (used by the harness slide) ----------------
#
# A build slide reveals itself in stages: up/down step through the stages and
# right fast-forwards to the fully-built slide. To keep every element anchored
# (things appear *in place* instead of the diagram re-centering as it grows),
# the diagram is always rendered onto a fixed DIAGRAM_H x DIAGRAM_W grid; hidden
# parts are blank cells. Each stage copies the relevant columns straight out of
# the finished art below, so colors and alignment stay pixel-identical to the
# original -- only the fan-out bus and two junction glyphs are regenerated.

DIAGRAM_W = 59
DIAGRAM_H = 13

# The finished diagram. harness_diagram() carves stages out of this so there is
# a single source of truth for the art.
HARNESS_DIAGRAM = [
    "                [blue]┌────────────┐[/]     [purple]┌──────────────────────┐[/]",
    "[grey]User prompt[/] [grey]──▶[/] [blue]│ [b]Lead Agent[/] [blue]│[/][grey]◀───▶[/][purple]│ [b]Python State Machine[/] [purple]│[/]",
    "                [blue]│[/]  [cyan]Opencode[/]  [blue]│[/]     [purple]│[/]   [grey]no model needed[/]    [purple]│[/]",
    "                [blue]└────────────┘[/]     [purple]└──────────[cyan]┬[/][purple]───────────┘[/]",
    "      [cyan]┌───────────────┬─────────────┬─────────┴─────┐[/]",
    "      [cyan]▼[/]               [cyan]▼[/]             [cyan]▼[/]               [cyan]▼[/]",
    "[green]┌───────────┐[/]     [green]┌───────┐[/]     [gold]┌────────┐[/]     [gold]┌──────────┐[/]",
    "[green]│ [b]Architect[/] [green]│[/] [grey]──▶[/] [green]│ [b]Coder[/] [green]│[/] [grey]──▶[/] [gold]│ [b]Tester[/] [gold]│[/] [grey]──▶[/] [gold]│ [b]Reviewer[/] [gold]│[/]",
    "[green]│ [gold]Opus 4.8[/]  [green]│[/]     [green]│ [steel]Qwen3[/] [green]│[/]     [gold]│ [steel]Qwen3[/]  [gold]│[/]     [gold]│ [gold]Opus 4.8[/] [gold]│[/]",
    "[green]└───────────┘[/]     [green]└───[orange]▲[/][green]───┘[/]     [gold]└───[orange]┬[/][gold]────┘[/]     [gold]└────[orange]┬[/][gold]─────┘[/]",
    "                      [orange]│[/]             [orange]│[/]               [orange]│[/]",
    "                      [orange]├─── test ────┘[/]               [orange]│[/]",
    "                      [orange]└───────── reviewer ──────────┘[/]",
]

_HARNESS_CELLS = None


def markup_cells(s):
    """Like parse_markup(), but return a per-character list of (char, styles)
    where `styles` is the tuple of active style tags at that column. Lets us
    slice the finished art by column while keeping each glyph's color."""
    cells = []
    stack = []
    i, n = 0, len(s)
    while i < n:
        if s[i] == "[":
            if s[i : i + 3] == "[/]" and stack:
                stack.pop()
                i += 3
                continue
            m = _TAGRE.match(s, i)
            if m and m.group(1) in STYLES:
                stack.append(m.group(1))
                i = m.end()
                continue
        cells.append((s[i], tuple(stack)))
        i += 1
    return cells


def cells_to_markup(row):
    """Coalesce a list of (char, styles) cells back into a markup string."""
    out = []
    i, n = 0, len(row)
    while i < n:
        st = row[i][1]
        j = i
        while j < n and row[j][1] == st:
            j += 1
        text = "".join(c for c, _ in row[i:j])
        if st:
            out.append("".join("[" + t + "]" for t in st) + text + "[/]" * len(st))
        else:
            out.append(text)
        i = j
    return "".join(out)


def reveal_split(lines, split, show_left=True, show_right=True):
    """Split each line at visual column `split` and reveal the two halves
    independently; hidden cells become spaces so nothing shifts or resizes."""
    out = []
    for ln in lines:
        cells = markup_cells(ln)
        left, right = cells[:split], cells[split:]
        if not show_left:
            left = [(" ", ())] * len(left)
        if not show_right:
            right = [(" ", ())] * len(right)
        out.append(cells_to_markup(left + right))
    return out


def _harness_cells():
    global _HARNESS_CELLS
    if _HARNESS_CELLS is None:
        _HARNESS_CELLS = [markup_cells(ln) for ln in HARNESS_DIAGRAM]
    return _HARNESS_CELLS


def harness_diagram(step):
    """Return the fan-out diagram built up to `step` (0 = base .. 5 = full)."""
    orig = _harness_cells()
    grid = [[(" ", ()) for _ in range(DIAGRAM_W)] for _ in range(DIAGRAM_H)]

    def copy(r, c0, c1):
        src = orig[r]
        for c in range(c0, c1 + 1):
            if 0 <= c < len(src):
                grid[r][c] = src[c]

    def put(r, c, ch, *styles):
        grid[r][c] = (ch, tuple(styles))

    # base (step 0) -- empty diagram; everything clicks in from here

    # 1 -- "User prompt ──▶" + Lead Agent box
    if step >= 1:
        copy(0, 16, 29)
        copy(1, 0, 14)
        copy(1, 16, 29)
        copy(2, 16, 29)
        copy(3, 16, 29)

    # 2 -- ◀───▶ link + Python State Machine box
    if step >= 2:
        copy(0, 35, 58)
        copy(1, 30, 34)
        copy(1, 35, 58)
        copy(2, 35, 58)
        copy(3, 35, 58)

    # 3 -- line to the architect + Architect box
    if step >= 3:
        copy(5, 6, 6)
        for r in (6, 7, 8, 9):
            copy(r, 0, 12)

    # 4 -- architect→coder arrow, state-machine→coder line, Coder box
    if step >= 4:
        copy(5, 22, 22)
        copy(6, 18, 26)
        copy(7, 13, 17)
        copy(7, 18, 26)
        copy(8, 18, 26)
        copy(9, 18, 21)
        copy(9, 23, 26)
        if step >= 5:
            copy(9, 22, 22)  # ▲ feedback target (once a loop feeds it)
        else:
            put(9, 22, "─", "green")  # closed box bottom until then

    # 5 -- Tester box + tester→coder (test) loop
    if step >= 5:
        copy(5, 36, 36)
        copy(6, 32, 41)
        copy(7, 27, 31)
        copy(7, 32, 41)
        copy(8, 32, 41)
        copy(9, 32, 41)
        copy(10, 22, 22)
        copy(10, 36, 36)
        copy(11, 23, 36)
        if step >= 6:
            copy(11, 22, 22)  # ├ once the reviewer loop also taps in
        else:
            put(11, 22, "└", "orange")

    # 6 -- Reviewer box + reviewer→coder loop
    if step >= 6:
        copy(5, 52, 52)
        copy(6, 47, 58)
        copy(7, 42, 46)
        copy(7, 47, 58)
        copy(8, 47, 58)
        copy(9, 47, 58)
        copy(10, 52, 52)
        copy(11, 52, 52)
        copy(12, 22, 52)

    # fan-out bus (row 4) -- regenerated so it only spans revealed workers
    if step >= 3:
        right = 52 if step >= 6 else 46
        taps = {6: "┌", 46: "┴"}
        if step >= 4:
            taps[22] = "┬"
        if step >= 5:
            taps[36] = "┬"
        if step >= 6:
            taps[52] = "┐"
        for c in range(6, right + 1):
            grid[4][c] = (taps.get(c, "─"), ("cyan",))

    return A(*[cells_to_markup(row) for row in grid])


def slide_harness(step=None):
    if step is None:
        step = slide_harness.build_steps
    done = step >= 7  # closing lines land after the diagram is fully built
    return [
        "[cyan][b]REQUIREMENT 2[/][/]  [grey](INHERITED FROM REQ 1)[/]",
        "[grey]────────────────────────────────────────────[/]",
        "[gold][b]CONFIGURABLE LOCAL TOKEN ROUTING[/][/]",
        "",
        harness_diagram(step),
        "",
        "[grey]The state machine drives all four workers.[/]" if done else "",
        "[grey][b]Test[/][grey] & [b]reviewer[/][grey] loop back to [b]coder[/][grey] until the gates pass.[/]"
        if done
        else "",
        "",
        "[gold][b]Match the size of the model to the size of the job.[/][/]" if done else "",
    ]


slide_harness.build_steps = 7  # 6 diagram stages + 1 for the closing lines


def slide_problem(step=None):
    if step is None:
        step = slide_problem.build_steps
    columns = [
        "  [green]omodel-manager[/]  [green][b]fluent[/][/]          [red]loudmouth[/]  [red][b]lost[/][/]",
        "  [grey]──────────────────────[/]        [grey]──────────────────────[/]",
        "  [green]›[/] vLLM / Docker / SSH           [red]›[/] Lua 5.1  [grey](no goto)[/]",
        "  [green]›[/] Python state machine          [red]›[/] Classic-Era WoW API",
        "  [green]›[/] sm_121 quant flags            [red]›[/] BackdropTemplate quirks",
        "  [green]›[/] model launch profiles         [red]›[/] macro & ToS safety",
    ]
    got_loudmouth = step >= 1  # right (red) column + the punchline click in together
    return [
        "[gold][b]THE PROBLEM[/][/]",
        "",
        "[white]The agent trained up its skills building [b]omodel-manager[/][white] ...[/]",
        "[white]then walked into [b]loudmouth[/][white] with all the wrong instincts.[/]"
        if got_loudmouth
        else "",
        "",
        A(*reveal_split(columns, 32, show_right=got_loudmouth)),
        "",
        "[grey]Great skills. [white][b]Wrong repo.[/][/][grey] The context reset to zero.[/]"
        if got_loudmouth
        else "",
    ]


slide_problem.build_steps = 1  # 1: the loudmouth (red) side + the punchline


def slide_solution(step=None):
    if step is None:
        step = slide_solution.build_steps

    def ko(s):  # final click knocks out the override branch (no override here)
        return "[strike]" + s + "[/]" if step >= 4 else s

    inner = [
        " [grey]Before the task, load your role skill:[/]",
        ko(" [orange]1.[/] If [orange]agent-code-override[/] is available:") if step >= 1 else "",
        ko("    load [b]only[/] that skill. Skip [cyan]2[/][grey]-[/][green]3[/][grey].[/]") if step >= 1 else "",
        " [cyan]2.[/] Load [cyan]agent-code[/][grey].[/]" if step >= 2 else "",
        " [green]3.[/] If [green]agent-code-extend[/] is available: load" if step >= 3 else "",
        "    it too. If it conflicts, follow [cyan]agent-code[/][grey].[/]" if step >= 3 else "",
    ]
    return [
        "[gold][b]THE SOLUTION???[/][/]   [grey]everything old is new again[/]",
        "",
        "[white][b]INHERITANCE[/][/]    [cyan]EXTEND[/][grey],[/] [orange]OVERRIDE[/]",
        "",
        A(
            *box(
                inner,
                iw=48,
                color="steel",
                title="the role-skill loader",
                lead="",
            )
        ),
        "",
        A(
            ko("  [orange]override[/]   [grey]<repo>/.agents/skills/[/][orange]agent-code-override[/][grey]/[/]"),
            "  [cyan]global[/]     [grey]~/.config/opencode/skills/[/][cyan]agent-code[/][grey]/[/]",
            "  [green]local[/]      [grey]<repo>/.agents/skills/[/][green]agent-code-extend[/][grey]/[/]",
        ),
        "",
        "[grey]The Lua expert was there all along -- one overlay away.[/]",
    ]


slide_solution.build_steps = 4  # 1/2/3 click in, then 4 strikes out the override branch


def slide_runbook(step=None):
    if step is None:
        step = slide_runbook.build_steps

    # The pipeline (the "perform ..." invocation -> inputs -> RUNBOOK REVIEW box)
    # is one build stage; the ABCDE table and the closing line are the next two.
    # Hidden stages leave equal-height blanks so the title never shifts.
    pipeline = [
        "[grey]\"perform a session review\"[/]",
        "",
        "[white]AGENTS.md[/] [grey]·[/] [white]REVIEW.md[/] [grey]·[/] [white].agents/skills/*[/] [grey]·[/] [white]session log [grey](sqlite)[/]",
        "[grey]│[/]",
        "[grey]▼[/]",
        A(*box(["  [b][cyan]SESSION REVIEW[/][/]  "], iw=18, color="cyan", lead="")),
        "[grey]│[/]",
        "[grey]▼[/]",
    ]
    abcde = A(
        "  [cyan]A[/]  [white]mine the session log[/]     [grey]recurring errors → notes[/]",
        "  [cyan]B[/]  [white]update/add skills[/]        [grey]extend vs override[/]",
        "  [cyan]C[/]  [white]draft any missing files[/]  [grey]AGENTS.md, REVIEW.md …[/]",
        "  [cyan]D[/]  [white]compact & de-duplicate[/]   [grey]one rule, one home[/]",
        "  [cyan]E[/]  [white]inventory & size skills[/]  [grey]≤40 lean · >80 LARGE[/]",
    )

    def blanks(block):  # same row count as `block`, but empty (keeps layout put)
        rows = sum(len(b) if isinstance(b, Art) else 1 for b in block) \
            if isinstance(block, list) else len(block)
        return [""] * rows

    return [
        "[gold][b]THE session-review SKILL[/][/]",
        "[grey]a periodic self-maintenance pass[/]",
        "",
        *(pipeline if step >= 1 else blanks(pipeline)),
        "",
        *([abcde] if step >= 2 else blanks(abcde)),
        "",
        "[cyan][b]Next session[/][/] [grey]=[/] [gold][b]smarter agents![/][/]" if step >= 3 else "",
    ]


slide_runbook.build_steps = 3  # pipeline, then ABCDE, then the closing line


def slide_end():
    return [
        "[grey]" + "─" * 54 + "[/]",
        "",
        A(
            "[white][b]\"No Adobe tokens were [strike][grey]harmed[/][/] consumed in the[/][/]",
            "[white][b] creation of this addon / presentation.\"[/][/]",
        ),
        "",
        "[grey]" + "─" * 54 + "[/]",
        "",
        "",
        "[red][b]<3[/][/]   [gold]thank you[/]",
    ]


SLIDES = [
    slide_title,
    slide_what,
    slide_spark,
    slide_harness,
    slide_runbook,
    slide_problem,
    slide_solution,
    slide_end,
]
N = len(SLIDES)


# ---------------------------------------------------------------------------
# Frame assembly
# ---------------------------------------------------------------------------


def max_steps(index):
    return getattr(SLIDES[index], "build_steps", 0)


def slide_entries(index, step):
    fn = SLIDES[index]
    steps = getattr(fn, "build_steps", 0)
    return fn(min(step, steps)) if steps else fn()


def footer_line(index, cols, step=0, steps=0):
    dots = "".join("●" if k == index else "○" for k in range(N))
    build = f"[cyan]←→ build {min(step, steps)}/{steps}[/]   " if steps else ""
    zoom = (f"[gold]{_LAST_ZOOM}x[/][grey]{'' if ZOOM else ' auto'}[/]   "
            if (_LAST_ZOOM > 1 or ZOOM) else "")
    mk = (
        f"[red]loudmouth[/]    [grey]{dots}[/]    "
        f"[white][b]{index + 1}[/][/][grey]/{N}[/]    "
        f"{build}{zoom}[d]◀ prev   next ▶   ·   +/- zoom   ·   q quit[/]"
    )
    return compose(parse_markup(mk), cols)


def _layout_block(entries):
    """Flatten slide entries into span lines ready to be centered by compose().

    A plain string is centered on its own. An Art block is padded to *its own*
    width and centered as a single unit -- so a narrow diagram next to a wider
    paragraph still lands in the middle instead of being shoved left."""
    out = []
    for item in entries:
        if isinstance(item, Art):
            parsed = [parse_markup(ln) for ln in item]
            bw = max((plain_len(sp) for sp in parsed), default=0)
            for sp in parsed:
                pad = bw - plain_len(sp)
                out.append(sp + ([("", " " * pad)] if pad else []))
        else:
            out.append(parse_markup(item))  # compose() centers single lines
    return out


def frame_lines(index, cols, rows, step=0):
    global _LAST_ZOOM
    canvas = _layout_block(slide_entries(index, step))
    reserve = 2 if rows >= 9 else 0  # blank spacer + footer
    body_rows = max(1, rows - reserve)

    z = ZOOM if ZOOM else fit_zoom(canvas, cols, body_rows)
    _LAST_ZOOM = z
    canvas = zoom_canvas(canvas, z)

    n = len(canvas)
    if n >= body_rows:
        top = (n - body_rows) // 2
        vis = canvas[top : top + body_rows]
    else:
        toppad = (body_rows - n) // 2
        botpad = body_rows - n - toppad
        vis = [[]] * toppad + canvas + [[]] * botpad

    out = [compose(l, cols) for l in vis]
    if reserve:
        out.append(" " * cols)
        out.append(footer_line(index, cols, step, max_steps(index)))
    return out[:rows]


# ---------------------------------------------------------------------------
# Terminal driver
# ---------------------------------------------------------------------------


def get_size():
    sz = shutil.get_terminal_size((80, 24))
    return max(1, sz.columns), max(1, sz.lines)


def enable_win_vt():
    """Enable ANSI/VT processing on legacy Windows consoles."""
    try:
        import ctypes

        k = ctypes.windll.kernel32
        h = k.GetStdHandle(-11)
        mode = ctypes.c_uint32()
        if k.GetConsoleMode(h, ctypes.byref(mode)):
            k.SetConsoleMode(h, mode.value | 0x0004)  # ENABLE_VT_PROCESSING
    except Exception:
        pass


# --- key decoding -----------------------------------------------------------
#
# Two axes. Left/Right walk a slide's build steps (and roll over to the
# neighbouring slide at the ends) -- Right also fast-forwards the current build
# to fully-open before crossing. Up/Down move whole slides; Down first snaps the
# build open in one shot, Up always leaves (resetting so a revisit starts fresh).

STEP_NEXT, STEP_PREV = "STEP_NEXT", "STEP_PREV"      # Right / Left
SLIDE_NEXT, SLIDE_PREV = "SLIDE_NEXT", "SLIDE_PREV"  # Down / Up
FIRST, LAST, QUIT = "FIRST", "LAST", "QUIT"
ZOOM_IN, ZOOM_OUT, ZOOM_AUTO = "ZOOM_IN", "ZOOM_OUT", "ZOOM_AUTO"  # + / - / 0


def _decode_unix(data):
    if data in (b"q", b"Q", b"\x1b", b"\x03"):
        return QUIT
    if data in (b"+", b"="):                                     # + (also unshifted =)
        return ZOOM_IN
    if data in (b"-", b"_"):
        return ZOOM_OUT
    if data == b"0":
        return ZOOM_AUTO
    if data in (b"\x1b[C", b"\x1bOC", b"l", b" ", b"\r"):       # Right / l / space
        return STEP_NEXT
    if data in (b"\x1b[D", b"\x1bOD", b"h"):                     # Left / h
        return STEP_PREV
    if data in (b"\x1b[B", b"\x1bOB", b"j", b"n", b"\x1b[6~"):   # Down / j / n / PgDn
        return SLIDE_NEXT
    if data in (b"\x1b[A", b"\x1bOA", b"k", b"p", b"b", b"\x7f", b"\x1b[5~"):
        return SLIDE_PREV                                        # Up / k / p / b / PgUp
    if data in (b"g", b"\x1b[H", b"\x1b[1~", b"\x1bOH"):
        return FIRST
    if data in (b"G", b"\x1b[F", b"\x1b[4~", b"\x1bOF"):
        return LAST
    if len(data) == 1 and data.isdigit() and data != b"0":
        return ("JUMP", int(data) - 1)
    return None


def _decode_win(ch, ch2=None):
    if ch2 is not None:
        return {"M": STEP_NEXT, "K": STEP_PREV,      # Right / Left
                "P": SLIDE_NEXT, "H": SLIDE_PREV,     # Down / Up
                "Q": SLIDE_NEXT, "I": SLIDE_PREV,     # PgDn / PgUp
                "G": FIRST, "O": LAST}.get(ch2)
    if ch in ("q", "Q", "\x1b", "\x03"):
        return QUIT
    if ch in ("+", "="):
        return ZOOM_IN
    if ch in ("-", "_"):
        return ZOOM_OUT
    if ch == "0":
        return ZOOM_AUTO
    if ch in ("l", " ", "\r"):
        return STEP_NEXT
    if ch == "h":
        return STEP_PREV
    if ch in ("j", "n"):
        return SLIDE_NEXT
    if ch in ("k", "p", "b", "\x08"):
        return SLIDE_PREV
    if ch == "g":
        return FIRST
    if ch == "G":
        return LAST
    if ch.isdigit() and ch != "0":
        return ("JUMP", int(ch) - 1)
    return None


def run_interactive(start):
    out = sys.stdout
    try:
        out.reconfigure(encoding="utf-8")
    except Exception:
        pass

    if IS_WIN:
        enable_win_vt()
        import msvcrt
        import time

        def wait_key(timeout):
            end = time.monotonic() + timeout
            while time.monotonic() < end:
                if msvcrt.kbhit():
                    ch = msvcrt.getwch()
                    if ch in ("\x00", "\xe0"):
                        return _decode_win(ch, msvcrt.getwch())
                    return _decode_win(ch)
                time.sleep(0.01)
            return None

        restore = lambda: None
    else:
        import termios
        import tty
        import select
        import signal

        fd = sys.stdin.fileno()
        old = termios.tcgetattr(fd)
        tty.setcbreak(fd)  # leaves ISIG on -> Ctrl-C still raises

        signal.signal(signal.SIGWINCH, lambda *_: None)  # just interrupt select

        def wait_key(timeout):
            try:
                r, _, _ = select.select([fd], [], [], timeout)
            except (InterruptedError, OSError):
                return None  # SIGWINCH woke us -> loop re-checks size
            if not r:
                return None
            return _decode_unix(os.read(fd, 32))

        def restore():
            termios.tcsetattr(fd, termios.TCSADRAIN, old)

    out.write("\x1b[?1049h\x1b[?25l")  # alt screen, hide cursor
    out.flush()

    global ZOOM
    index = max(0, min(N - 1, start))
    step = 0
    last = None
    try:
        while True:
            cols, rows = get_size()
            state = (index, step, cols, rows, ZOOM)
            if state != last:
                buf = "\x1b[H" + "\r\n".join(frame_lines(index, cols, rows, step))
                buf += _reset()
                out.write(buf)
                out.flush()
                last = state

            key = wait_key(0.12)  # also the resize-poll cadence
            if key is None:
                continue
            m = max_steps(index)
            if key == QUIT:
                break
            elif key == ZOOM_IN:             # pin zoom one step above what's shown
                ZOOM = min(ZOOM_MAX, _LAST_ZOOM + 1)
            elif key == ZOOM_OUT:
                ZOOM = max(1, _LAST_ZOOM - 1)
            elif key == ZOOM_AUTO:
                ZOOM = None
            elif key == STEP_NEXT:           # Down: next build step, else next slide
                if step < m:
                    step += 1
                elif index < N - 1:
                    index, step = index + 1, 0
            elif key == STEP_PREV:           # Up: previous build step, else prev slide
                if step > 0:
                    step -= 1
                elif index > 0:
                    index, step = index - 1, 0
            elif key == SLIDE_NEXT:          # Right: reveal all, then next slide
                if step < m:
                    step = m
                elif index < N - 1:
                    index, step = index + 1, 0
            elif key == SLIDE_PREV:          # Left: previous slide, build reset
                if index > 0:
                    index -= 1
                step = 0
            elif key == FIRST:
                index, step = 0, 0
            elif key == LAST:
                index, step = N - 1, 0
            elif isinstance(key, tuple) and key[0] == "JUMP":
                index, step = max(0, min(N - 1, key[1])), 0
    except KeyboardInterrupt:
        pass
    finally:
        out.write("\x1b[?25h\x1b[?1049l")  # show cursor, leave alt screen
        out.flush()
        restore()


def run_dump(width, height, only, step=None):
    idxs = range(N) if only is None else [only]
    bar = "+" + "-" * width + "+"
    for i in idxs:
        # default: show each slide fully built; --step pins a build stage
        s = max_steps(i) if step is None else max(0, min(step, max_steps(i)))
        print(bar)
        for line in frame_lines(i, width, height, s):
            # pad/trim to width for the frame (compose already sized it, but
            # ANSI-free width math only holds when COLOR is off)
            print("|" + line + "|" if not COLOR else "| " + line)
        print(bar)
        print()


def main():
    global COLOR
    ap = argparse.ArgumentParser(description="LOUDMOUTH terminal slide deck")
    ap.add_argument("--dump", action="store_true",
                    help="render slides to stdout (no TTY) for previewing")
    ap.add_argument("--width", type=int, default=78)
    ap.add_argument("--height", type=int, default=26)
    ap.add_argument("--only", type=int, default=None,
                    help="dump a single slide number (1-based)")
    ap.add_argument("--step", type=int, default=None,
                    help="dump a build slide at stage N (0=base); default=full")
    ap.add_argument("--start", type=int, default=1,
                    help="start on slide N (1-based)")
    ap.add_argument("--color", action="store_true", help="force color in --dump")
    ap.add_argument("--no-color", action="store_true", help="disable color")
    ap.add_argument("--zoom", type=int, default=None, choices=(1, 2, 3),
                    help="fixed cell-zoom factor (default: auto-fit the pane)")
    args = ap.parse_args()

    global ZOOM
    if args.zoom:
        ZOOM = args.zoom

    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

    if args.no_color or os.environ.get("NO_COLOR"):
        COLOR = False

    if args.dump:
        if not args.color:
            COLOR = False
        only = None if args.only is None else max(0, min(N - 1, args.only - 1))
        run_dump(max(20, args.width), max(8, args.height), only, args.step)
        return

    if not sys.stdin.isatty() or not sys.stdout.isatty():
        sys.stderr.write(
            "present.py needs an interactive terminal.\n"
            "Run it directly in a shell (e.g. the right pane), or preview with:\n"
            "    python present.py --dump\n"
        )
        sys.exit(1)

    run_interactive(args.start - 1)


if __name__ == "__main__":
    main()
