#!/usr/bin/env python3
"""
present.py -- a dependency-free terminal slide deck for the LOUDMOUTH talk.

Runs in the right split of a herdr terminal while the agent demo runs on the left.
Stdlib only (no pip install). Left/Right arrows move between slides.

  Controls
    ->  l  space  j  PgDn  n   next slide
    <-  h  b      k  PgUp  p   previous slide
    g / Home                   first slide
    G / End                    last slide
    1..9                       jump to slide N
    q / Esc / Ctrl-C           quit

  Preview without a TTY (for editing the art):
    python present.py --dump                 # all slides, 78x26, no color
    python present.py --dump --width 60 --height 20   # see the center-crop
    python present.py --dump --only 1 --color

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


def slide_what():
    return [
        "[gold][b]WHAT IT IS[/][/]",
        "",
        "[white]Personality-driven, context-aware banter.[/]",
        "[grey]reacting to spells, pets, mobs, and zones[/]",
        "",
        A(
            "     [grey]╭──────────────────────────────────────╮[/]",
            "     [grey]│[/]  [cyan]Oooof... smells like malt liquor[/]    [grey]│[/]",
            "     [grey]│[/]  [cyan]and feet... Dwarfs are nasty.[/]       [grey]│[/]",
            "     [grey]╰──[grey]┬[/]───────────────────────────────────╯[/]",
            "        [grey]│[/]",
            "        [purple]/\\[/]",
            "       [purple]/  \\[/]              [gold] __________________[/]",
            "      [purple]/____\\[/]             [gold]|[/]                  [gold]\\[/]",
            "      [white]([/][gold]o  o[/][white])[/]             [gold]|[/]   [b][cyan]IRONFORGE[/][/]      [gold]▶[/]",
            "     [purple]<[/]  [gold]||[/]  [purple]>[/]            [gold]|__________________/[/]",
            "      [purple]/_[/][gold]||[/][purple]_\\[/]                   [gold]|[/]",
            "        [gold]||[/]                     [gold]|[/]",
            "       [purple]_[/][gold]||[/][purple]_[/]",
        ),
    ]


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


def slide_harness():
    return [
        "[cyan][b]REQUIREMENT 2[/][/]  [grey](INHERITED FROM REQ 1)[/]",
        "[grey]────────────────────────────────────────────[/]",
        "[gold][b]CONFIGURABLE LOCAL TOKEN ROUTING[/][/]",
        "",
        A(
            "                             [blue]┌────────────┐[/]     [purple]┌──────────────────────┐[/]",
            "             [grey]User prompt[/] [grey]──▶[/] [blue]│ [b]Lead Agent[/] [blue]│[/][grey]◀───▶[/][purple]│ [b]Python State Machine[/] [purple]│[/]",
            "                             [blue]│[/]  [cyan]Opencode[/]  [blue]│[/]     [purple]│[/]   [grey]no model needed[/]    [purple]│[/]",
            "                             [blue]└────────────┘[/]     [purple]└──────────[cyan]┬[/][purple]───────────┘[/]",
            "                   [cyan]┌───────────────┬─────────────┬─────────┴─────┐[/]",
            "                   [cyan]▼[/]               [cyan]▼[/]             [cyan]▼[/]               [cyan]▼[/]",
            "             [green]┌───────────┐[/]     [green]┌───────┐[/]     [gold]┌────────┐[/]     [gold]┌──────────┐[/]",
            "             [green]│ [b]Architect[/] [green]│[/] [grey]──▶[/] [green]│ [b]Coder[/] [green]│[/] [grey]──▶[/] [gold]│ [b]Tester[/] [gold]│[/] [grey]──▶[/] [gold]│ [b]Reviewer[/] [gold]│[/]",
            "             [green]│ [gold]Opus 4.8[/]  [green]│[/]     [green]│ [steel]Qwen3[/] [green]│[/]     [gold]│ [steel]Qwen3[/]  [gold]│[/]     [gold]│ [gold]Opus 4.8[/] [gold]│[/]",
            "             [green]└───────────┘[/]     [green]└───[orange]▲[/][green]───┘[/]     [gold]└───[orange]┬[/][gold]────┘[/]     [gold]└────[orange]┬[/][gold]─────┘[/]",
            "                                   [orange]│[/]             [orange]│[/]               [orange]│[/]",
            "                                   [orange]├─── test ────┘[/]               [orange]│[/]",
            "                                   [orange]└───────── reviewer ──────────┘[/]",
        ),
        "",
        "[grey]The state machine drives all four workers.[/]",
        "[grey][b]Test[/][grey] & [b]reviewer[/][grey] loop back to [b]coder[/][grey] until the gates pass.[/]",
        "",
        "[gold][b]Match the size of the model to the size of the job.[/][/]",
    ]


def slide_problem():
    return [
        "[gold][b]THE PROBLEM[/][/]",
        "",
        "[white]The agent trained up its skills building [b]omodel-manager[/][white] ...[/]",
        "[white]then walked into [b]loudmouth[/][white] with all the wrong instincts.[/]",
        "",
        A(
            "  [green]omodel-manager[/]  [green][b]fluent[/][/]          [red]loudmouth[/]  [red][b]lost[/][/]",
            "  [grey]──────────────────────[/]        [grey]──────────────────────[/]",
            "  [green]›[/] vLLM / Docker / SSH           [red]›[/] Lua 5.1  [grey](no goto)[/]",
            "  [green]›[/] Python state machine          [red]›[/] Classic-Era WoW API",
            "  [green]›[/] sm_121 quant flags            [red]›[/] BackdropTemplate quirks",
            "  [green]›[/] model launch profiles         [red]›[/] macro & ToS safety",
        ),
        "",
        "[grey]Great skills. [white][b]Wrong repo.[/][/][grey] The context reset to zero.[/]",
    ]


def slide_solution():
    return [
        "[gold][b]THE SOLUTION[/][/]   [grey]everything old is new again[/]",
        "",
        "[white][b]INHERITANCE[/][/]    [cyan]EXTEND[/][grey],[/] [orange]OVERRIDE[/]",
        "",
        A(
            *box(
                [
                    " [grey]Before the task, load your role skill:[/]",
                    " [orange]1.[/] If [orange]agent-code-override[/] is available:",
                    "    load [b]only[/] that skill. Skip [cyan]2[/][grey]-[/][green]3[/][grey].[/]",
                    " [cyan]2.[/] Load [cyan]agent-code[/][grey].[/]",
                    " [green]3.[/] If [green]agent-code-extend[/] is available: load",
                    "    it too. If it conflicts, follow [cyan]agent-code[/][grey].[/]",
                ],
                iw=48,
                color="steel",
                title="the role-skill loader",
                lead="",
            )
        ),
        "",
        A(
            "  [orange]override[/]   [grey]<repo>/.agents/skills/[/][orange]agent-code-override[/][grey]/[/]",
            "  [cyan]global[/]     [grey]~/.config/opencode/skills/[/][cyan]agent-code[/][grey]/[/]",
            "  [green]local[/]      [grey]<repo>/.agents/skills/[/][green]agent-code-extend[/][grey]/[/]",
        ),
        "",
        "[grey]The Lua expert was there all along -- one overlay away.[/]",
    ]


def slide_runbook():
    return [
        "[gold][b]THE agent-runbook-review SKILL[/][/]",
        "[grey]\"perform an agent runbook review\"[/]",
        "",
        "[grey]a periodic self-maintenance pass over the repo's agent docs[/]",
        "",
        "[white]AGENTS.md[/] [grey]·[/] [white]REVIEW.md[/] [grey]·[/] [white].agents/skills/*[/] [grey]·[/] [white]session log [grey](sqlite)[/]",
        "[grey]│[/]",
        "[grey]▼[/]",
        A(
            *box(
                ["  [b][cyan]RUNBOOK REVIEW[/][/]  "],
                iw=18,
                color="cyan",
                lead="",
            )
        ),
        "[grey]│[/]",
        "[grey]▼[/]",
        "[white]a Report:[/] [grey]proposed diffs  +  a change ledger[/]",
        "[grey](report-first — never a silent rewrite)[/]",
        "",
        A(
            "  [cyan]A[/]  [white]inventory & size skills[/]   [grey]≤40 lean · >80 LARGE[/]",
            "  [cyan]B[/]  [white]compact & de-duplicate[/]    [grey]one rule, one home[/]",
            "  [cyan]C[/]  [white]mine the session log[/]      [grey]recurring errors → notes[/]",
            "  [cyan]D[/]  [white]new project skill?[/]        [grey]extend vs override[/]",
            "  [cyan]E[/]  [white]draft any missing files[/]   [grey]AGENTS.md, REVIEW.md …[/]",
        ),
        "",
        "[orange][b]Consolidation only[/][/][grey] — never drops a MUST / NEVER / invariant.[/]",
    ]


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


def footer_line(index, cols):
    dots = "".join("●" if k == index else "○" for k in range(N))
    mk = (
        f"[red]loudmouth[/]    [grey]{dots}[/]    "
        f"[white][b]{index + 1}[/][/][grey]/{N}[/]    "
        f"[d]◀ prev   next ▶   ·   q quit[/]"
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


def frame_lines(index, cols, rows):
    canvas = _layout_block(SLIDES[index]())
    reserve = 2 if rows >= 9 else 0  # blank spacer + footer
    body_rows = max(1, rows - reserve)

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
        out.append(footer_line(index, cols))
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

NEXT, PREV, FIRST, LAST, QUIT = "NEXT", "PREV", "FIRST", "LAST", "QUIT"


def _decode_unix(data):
    if data in (b"q", b"Q", b"\x1b", b"\x03"):
        return QUIT
    if data in (b"\x1b[C", b"\x1bOC", b"\x1b[B", b"\x1bOB", b" ", b"l", b"j",
                b"n", b"\r", b"\x1b[6~"):
        return NEXT
    if data in (b"\x1b[D", b"\x1bOD", b"\x1b[A", b"\x1bOA", b"h", b"k", b"p",
                b"b", b"\x7f", b"\x1b[5~"):
        return PREV
    if data in (b"g", b"\x1b[H", b"\x1b[1~", b"\x1bOH"):
        return FIRST
    if data in (b"G", b"\x1b[F", b"\x1b[4~", b"\x1bOF"):
        return LAST
    if len(data) == 1 and data.isdigit() and data != b"0":
        return ("JUMP", int(data) - 1)
    return None


def _decode_win(ch, ch2=None):
    if ch2 is not None:
        return {"K": PREV, "M": NEXT, "H": PREV, "P": NEXT,
                "G": FIRST, "O": LAST, "I": PREV, "Q": NEXT}.get(ch2)
    if ch in ("q", "Q", "\x1b", "\x03"):
        return QUIT
    if ch in (" ", "l", "j", "n", "\r"):
        return NEXT
    if ch in ("h", "k", "p", "b", "\x08"):
        return PREV
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

    index = max(0, min(N - 1, start))
    last = None
    try:
        while True:
            cols, rows = get_size()
            state = (index, cols, rows)
            if state != last:
                buf = "\x1b[H" + "\r\n".join(frame_lines(index, cols, rows))
                buf += _reset()
                out.write(buf)
                out.flush()
                last = state

            key = wait_key(0.12)  # also the resize-poll cadence
            if key is None:
                continue
            if key == QUIT:
                break
            elif key == NEXT:
                index = min(N - 1, index + 1)
            elif key == PREV:
                index = max(0, index - 1)
            elif key == FIRST:
                index = 0
            elif key == LAST:
                index = N - 1
            elif isinstance(key, tuple) and key[0] == "JUMP":
                index = max(0, min(N - 1, key[1]))
    except KeyboardInterrupt:
        pass
    finally:
        out.write("\x1b[?25h\x1b[?1049l")  # show cursor, leave alt screen
        out.flush()
        restore()


def run_dump(width, height, only):
    idxs = range(N) if only is None else [only]
    bar = "+" + "-" * width + "+"
    for i in idxs:
        print(bar)
        for line in frame_lines(i, width, height):
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
    ap.add_argument("--start", type=int, default=1,
                    help="start on slide N (1-based)")
    ap.add_argument("--color", action="store_true", help="force color in --dump")
    ap.add_argument("--no-color", action="store_true", help="disable color")
    args = ap.parse_args()

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
        run_dump(max(20, args.width), max(8, args.height), only)
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
