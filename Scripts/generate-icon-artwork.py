#!/usr/bin/env python3
"""Regenerate Skein's app icon artwork from its parametric description.

The icon is a figure-eight traced by a bundle of parallel cords — a skein of
thread coiled into a loop with no end.

This script owns three outputs:

  Skein/AppIcon.icon/Assets/rope.svg   the layer Icon Composer composites
  Skein/Assets.xcassets/AppIcon.appiconset/*.png
                                       the classic PNG set, for the macOS 14
                                       floor and for README.md's header image
  Skein/Assets.xcassets/SkeinMarkStroke.imageset/SkeinMarkStroke.png
                                       the single-colour template mark

The PNG set is rendered from the .icon bundle by `ictool`, so the two can never
drift: Icon Composer's material is the single source of the artwork.

Requires Xcode (for ictool) and Pillow.

    python3 Scripts/generate-icon-artwork.py
"""
import math
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
ICON_BUNDLE = ROOT / "Skein" / "AppIcon.icon"
APPICONSET = ROOT / "Skein" / "Assets.xcassets" / "AppIcon.appiconset"
MARK_PNG = (ROOT / "Skein" / "Assets.xcassets" / "SkeinMarkStroke.imageset"
            / "SkeinMarkStroke.png")

ICTOOL = Path("/Applications/Xcode.app/Contents/Applications/Icon Composer.app"
              "/Contents/Executables/ictool")

# ---------------------------------------------------------------- geometry --

CANVAS = 1024.0
CX = CY = CANVAS / 2.0

# Outer extent of the drawn rope, measured from the centre of the canvas. The
# loops are pitched taller than a rope laid flat would be: the two holes are
# what make the figure read as a loop rather than a lump, and at 16 pt they are
# the first thing to close up.
OUTER_HALF_W = 420.0
OUTER_HALF_H = 248.0

STRANDS = 4       # cords in the bundle
PITCH = 38.0      # centre-to-centre spacing between cords
TUBE = 46.0       # outer diameter of one cord

# Light comes from above, tipped slightly to the left.
LIGHT = (-0.30, -1.0)

SAMPLES = 720

# How far the outermost cord sits from the centreline, plus its own radius.
BUNDLE_REACH = (STRANDS - 1) / 2.0 * PITCH + TUBE / 2.0

XH = OUTER_HALF_W - BUNDLE_REACH    # half-width of the centreline
YH = OUTER_HALF_H - BUNDLE_REACH    # half-height of the centreline

# ----------------------------------------------------------------- shading --

SHADING_STEPS = 20    # strokes used to model one cord's cross-section
CROWN = 0.72          # where the highlight sits, as a fraction of cord radius

# Cross-section colours, from the shadow side of a cord to its crown.
CORD_RAMP = [
    (0.00, (0x7A, 0x31, 0x03)),
    (0.14, (0xA9, 0x4A, 0x05)),
    (0.32, (0xD9, 0x70, 0x09)),
    (0.52, (0xF2, 0x97, 0x1C)),
    (0.74, (0xFB, 0xC1, 0x48)),
    (1.00, (0xFD, 0xDE, 0x7A)),
]

# The traversal reaches the middle at 1/4 and 3/4 of the way round. Redrawing
# the second pass lets that branch cross over the first, the way a laid rope
# actually sits. The slice is butt-ended so its seams repaint the very pixels
# already beneath them and leave no visible join.
OVER_ARC = (0.75 - 0.135, 0.75 + 0.135)


def unit(vx, vy):
    m = math.hypot(vx, vy)
    return (vx / m, vy / m) if m else (0.0, 0.0)


LX, LY = unit(*LIGHT)


def ramp(f):
    """Colour at position f across a cord's cross-section, as #rrggbb."""
    for (f0, c0), (f1, c1) in zip(CORD_RAMP, CORD_RAMP[1:]):
        if f <= f1:
            u = 0.0 if f1 == f0 else (f - f0) / (f1 - f0)
            return "#%02X%02X%02X" % tuple(
                round(a + (b - a) * u) for a, b in zip(c0, c1)
            )
    return "#%02X%02X%02X" % CORD_RAMP[-1][1]


def cord_stack():
    """(width, colour, slide) for each stroke making up one cord.

    Successive strokes narrow while sliding toward the light, so the stack
    sweeps its lower edge from the shadow side up to the crown and brings its
    upper edge back down. The colour ramp then lands as a round bar: dark
    underneath, bright along the crown, and a thin turned-away rim on top that
    reads as the gap to the cord above.
    """
    radius = TUBE / 2.0
    stack = []
    for k in range(SHADING_STEPS):
        f = k / (SHADING_STEPS - 1)
        width = TUBE * (1.0 - f)
        stack.append((width, ramp(f), (radius - width / 2.0) * CROWN))
    return stack


def centreline(n, half_w=None, half_h=None, cx=CX, cy=CY):
    """Sample the centreline: a Gerono lemniscate, in image coordinates.

    x = XH cos t, y = YH sin 2t — a figure-eight whose loops stretch sideways
    and meet in a single crossing at the middle.
    """
    hw = XH if half_w is None else half_w
    hh = YH if half_h is None else half_h
    return [
        (cx + hw * math.cos(2.0 * math.pi * i / n),
         cy - hh * math.sin(4.0 * math.pi * i / n))
        for i in range(n)
    ]


def normals(pts):
    """Unit normal at each sample, from a central difference along the curve."""
    n = len(pts)
    out = []
    for i in range(n):
        ax, ay = pts[(i - 1) % n]
        bx, by = pts[(i + 1) % n]
        tx, ty = unit(bx - ax, by - ay)
        out.append((-ty, tx))
    return out


BASE = centreline(SAMPLES)
NORMALS = normals(BASE)


def cord_path(offset, slide, arc=None):
    """One cord of the bundle, offset sideways and slid toward the light.

    `arc` limits the result to a slice of the traversal, given as a pair of
    fractions; the slice is left open so its ends tuck under what covers them.
    """
    base, norms = BASE, NORMALS
    if arc is not None:
        lo, hi = (int(round(v * SAMPLES)) for v in arc)
        idx = [i % SAMPLES for i in range(lo, hi + 1)]
        base = [BASE[i] for i in idx]
        norms = [NORMALS[i] for i in idx]
    pts = []
    for (px, py), (nx, ny) in zip(base, norms):
        # Shift toward the light, but only by the amount this part of the
        # surface actually turns into it.
        facing = nx * LX + ny * LY
        d = offset + slide * facing
        pts.append((px + nx * d, py + ny * d))
    head = f"M{pts[0][0]:.1f},{pts[0][1]:.1f}"
    rest = "".join(f"L{x:.1f},{y:.1f}" for x, y in pts[1:])
    return head + rest + ("" if arc is not None else "Z")


def rope_svg():
    """The rope layer: every cord, then the branch that crosses over."""
    stack = cord_stack()
    span = (STRANDS - 1) / 2.0

    def pass_(arc):
        cap = "butt" if arc is not None else "round"
        out = []
        for k in range(STRANDS):
            offset = (k - span) * PITCH
            for width, colour, slide in stack:
                if width < 0.4:
                    continue
                out.append(
                    f'<path d="{cord_path(offset, slide, arc)}" fill="none" '
                    f'stroke="{colour}" stroke-width="{width:.2f}" '
                    f'stroke-linecap="{cap}" stroke-linejoin="round"/>'
                )
        return out

    body = "\n".join(pass_(None) + pass_(OVER_ARC))
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{CANVAS:.0f}" '
        f'height="{CANVAS:.0f}" viewBox="0 0 {CANVAS:.0f} {CANVAS:.0f}">\n'
        f"{body}\n</svg>\n"
    )


# ------------------------------------------------------------ the PNG set --

# The classic macOS icon grid: the squircle covers 824 of the 1024 canvas,
# inset 100 on each side, with a soft shadow below it.
ART_FRACTION = 824.0 / 1024.0
INSET_FRACTION = 100.0 / 1024.0

APPICONSET_SLOTS = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]


def render_icon(size, dest):
    """Ask Icon Composer for the icon's Default rendition at `size` pixels."""
    subprocess.run(
        [str(ICTOOL), str(ICON_BUNDLE), "--export-image",
         "--output-file", str(dest), "--platform", "macOS",
         "--rendition", "Default", "--width", str(size),
         "--height", str(size), "--scale", "1"],
        check=True, capture_output=True,
    )


def compose_slot(art, canvas_px):
    """Place the squircle on the macOS grid and lay its shadow beneath it."""
    inset = round(canvas_px * INSET_FRACTION)
    out = Image.new("RGBA", (canvas_px, canvas_px), (0, 0, 0, 0))

    scale = canvas_px / 1024.0
    blur = max(0.6, 6.0 * scale)
    drop = max(1, round(5.0 * scale))

    shadow = Image.new("RGBA", (canvas_px, canvas_px), (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 115), (inset, inset + drop), art.split()[3])
    out.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))
    out.alpha_composite(art, (inset, inset))
    return out


def write_appiconset(tmp):
    """Render each distinct art size once, then fill every slot that uses it."""
    APPICONSET.mkdir(parents=True, exist_ok=True)
    cache = {}
    for name, canvas_px in APPICONSET_SLOTS:
        art_px = round(canvas_px * ART_FRACTION)
        if art_px not in cache:
            path = tmp / f"art-{art_px}.png"
            render_icon(art_px, path)
            cache[art_px] = Image.open(path).convert("RGBA")
        compose_slot(cache[art_px], canvas_px).save(APPICONSET / name)
        print(f"  {name}  {canvas_px}px")


# --------------------------------------------------------------- the mark --

MARK_PX = 40          # matches the imageset's 2x slot
MARK_STROKE = 4.6     # cord thickness at the rendered size
MARK_PAD = 0.5
SUPERSAMPLE = 8


def write_mark():
    """The template mark: one cord of the same figure-eight, as a silhouette.

    Template images are tinted wholesale by the system, so this carries no
    colour and no interior detail — only a shape that still reads at 16 pt.
    """
    px = MARK_PX * SUPERSAMPLE
    stroke = MARK_STROKE * SUPERSAMPLE
    half_w = (MARK_PX / 2.0 - MARK_PAD) * SUPERSAMPLE - stroke / 2.0
    half_h = half_w * (YH / XH)

    img = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    r = stroke / 2.0
    for x, y in centreline(SAMPLES * 2, half_w, half_h, px / 2.0, px / 2.0):
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(0, 0, 0, 255))

    MARK_PNG.parent.mkdir(parents=True, exist_ok=True)
    img.resize((MARK_PX, MARK_PX), Image.LANCZOS).save(MARK_PNG)
    print(f"  {MARK_PNG.name}  {MARK_PX}px")


# ------------------------------------------------------------------- main --

def main():
    if not ICTOOL.exists():
        sys.exit(f"ictool not found at {ICTOOL} — Xcode 26 or later required.")

    svg = ICON_BUNDLE / "Assets" / "rope.svg"
    svg.parent.mkdir(parents=True, exist_ok=True)
    svg.write_text(rope_svg())
    print(f"rope layer\n  {svg.relative_to(ROOT)}  {svg.stat().st_size} bytes")

    tmp = ROOT / ".icon-render-cache"
    tmp.mkdir(exist_ok=True)
    try:
        print("PNG fallback set")
        write_appiconset(tmp)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    print("template mark")
    write_mark()


if __name__ == "__main__":
    main()
