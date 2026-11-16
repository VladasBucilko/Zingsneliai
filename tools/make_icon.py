"""Generate the Žingsneliai app icon (icon.svg): little footprints stepping upward.

Run: python3 tools/make_icon.py
Four pastel footprints alternate left/right along a gentle diagonal,
growing slightly as they go: small steps forward.
"""
import math, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SIZE = 512

BG = "#F5F2E8"
COLORS = ["#A8C9B4", "#A9CCE3", "#F4C7A1", "#CDBFE3"]  # sage, sky, peach, lavender


def foot(mirror: bool) -> str:
    """A child's right foot pointing up at the origin (big toe on the left).
    mirror=True gives a left foot."""
    sole = ("M 2 -42 C 22 -42 30 -22 28 0 C 26 24 18 46 1 46 "
            "C -15 46 -22 28 -22 6 C -22 -18 -18 -42 2 -42 Z")
    toes = [(-12, -55, 10.5), (5, -59, 8), (17.5, -54.5, 7), (26, -46, 6), (31, -35.5, 5)]
    parts = [f'<path d="{sole}"/>'] + [f'<circle cx="{x}" cy="{y}" r="{r}"/>' for x, y, r in toes]
    flip = ' transform="scale(-1,1)"' if mirror else ""
    return f"<g{flip}>{''.join(parts)}</g>"


def icon(background=True) -> str:
    start, end = (196, 400), (316, 128)
    dx, dy = end[0] - start[0], end[1] - start[1]
    length = math.hypot(dx, dy)
    ux, uy = dx / length, dy / length      # walking direction
    px, py = -uy, ux                         # perpendicular (to the right of travel)
    heading = math.degrees(math.atan2(dx, -dy))  # rotation from "pointing up"
    prints = []
    n = len(COLORS)
    for i, col in enumerate(COLORS):
        t = i / (n - 1)
        right = i % 2 == 1
        side = 40 if right else -40
        cx = start[0] + dx * t + px * side
        cy = start[1] + dy * t + py * side
        s = 1.3 + 0.15 * t
        tilt = heading + (-4 if right else 4)  # offsets the sole's natural lean
        prints.append(
            f'<g fill="{col}" transform="translate({cx:.1f} {cy:.1f}) rotate({tilt:.1f}) scale({s:.3f})">'
            f"{foot(mirror=not right)}</g>")
    bg = f'<rect width="{SIZE}" height="{SIZE}" rx="112" fill="{BG}"/>' if background else ""
    # The app icon keeps its padding; the bare mark is cropped to the footprints.
    box = f"0 0 {SIZE} {SIZE}" if background else "96 36 344 424"
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" '
            f'viewBox="{box}">{bg}{"".join(prints)}</svg>\n')


if __name__ == "__main__":
    (ROOT / "icon.svg").write_text(icon(True))
    (ROOT / "assets" / "brand").mkdir(parents=True, exist_ok=True)
    (ROOT / "assets" / "brand" / "steps_mark.svg").write_text(icon(False))
    print("wrote icon.svg and assets/brand/steps_mark.svg")
