"""#32 review-only A/B assets; preserve every previous pass unchanged."""

import base64
import importlib.util
import io
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[2]
spec = importlib.util.spec_from_file_location("previous_gate", ROOT.parent / "build.py")
previous = importlib.util.module_from_spec(spec)
spec.loader.exec_module(previous)
SIZE = (128, 288)
CANDIDATE_X = 3412


class Canvas:
    def __init__(self):
        self.image = Image.new("RGBA", SIZE)
        self.svg = []

    def bitmap(self, image, x, y, name):
        self.image.alpha_composite(image, (x, y))
        stream = io.BytesIO()
        image.save(stream, format="PNG")
        data = base64.b64encode(stream.getvalue()).decode("ascii")
        self.svg.append(f'<image id="{name}" x="{x}" y="{y}" '
                        f'width="{image.width}" height="{image.height}" '
                        f'href="data:image/png;base64,{data}"/>')

    def rect(self, x, y, w, h, color):
        color = previous.PALETTE.get(color, color)
        ImageDraw.Draw(self.image).rectangle((x, y, x+w-1, y+h-1), fill=color)
        self.svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{color}"/>')

    def save(self, variant, name):
        target = ROOT / variant
        target.mkdir(exist_ok=True)
        self.image.save(target / f"{name}.png")
        (target / f"{name}.svg").write_text(
            '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="288" '
            'viewBox="0 0 128 288" shape-rendering="crispEdges">\n'
            + '\n'.join(self.svg) + '\n</svg>\n', encoding="utf-8")


def shoe(c, x, y, width):
    c.rect(x, y, width, 12, "ink")
    c.rect(x+1, y+1, width-2, 9, "steel")
    c.rect(x+2, y+1, width-4, 1, "edge")
    c.rect(x+3, y+8, width-6, 2, "bronze")
    c.rect(x+2, y+11, width-4, 1, "shadow")


def pillar_variant(depth, warning=False, closed=False):
    c = Canvas()
    old = previous.gate(depth, warning, closed)
    # Keep the editable original vector groups; only the #22 pillar is bitmap.
    c.image.alpha_composite(old.image)
    c.svg.extend(old.svg)
    # Extend the rear guide to the visible forward deck plane. No floor strip
    # across the open lane; feet and projectiles always draw in front.
    c.rect(73, 250, 6, 5, "steel")
    shoe(c, 72, 252, 12)
    if closed:
        shoe(c, 57, 252, 14)
    return c


def wall_variant(depth, warning=False, closed=False):
    c = Canvas()
    with Image.open(REPO / "assets/pixel/hangar_deck.png") as deck:
        # Reuse #22 deck-panel vocabulary without inventing a new wall palette.
        upper = deck.crop((240, 24, 368, 104)).convert("RGBA")
        lower = deck.crop((480, 24, 608, 36)).convert("RGBA")
        floor = deck.crop(((CANDIDATE_X-64) % 1440, 12,
                           (CANDIDATE_X-64) % 1440+128, 36)).convert("RGBA")
    c.bitmap(upper, 0, 0, "deck-material-upper-wall")
    c.bitmap(lower, 0, 80, "deck-material-lower-wall")
    c.rect(0, 0, 4, 104, "ink")
    c.rect(124, 0, 4, 104, "ink")
    for x in (5, 121):
        c.rect(x, 2, 2, 99, "steel")
    c.rect(0, 92, 128, 12, "ink")
    c.rect(2, 93, 124, 2, "edge")
    c.rect(4, 96, 120, 5, "steel")
    c.rect(4, 101, 120, 2, "shadow")
    for x in range(12, 122, 24):
        c.rect(x, 97, 2, 2, "glint")
    # Two continuous rear-plane jambs make the shutter a central inset. They
    # end on the rear deck plane; only the moving shoe reaches the front shine.
    for x in (48, 72):
        c.rect(x, 101, 8, 151, "ink")
        c.rect(x+1, 103, 5, 147, "shadow")
        c.rect(x+1, 104, 1, 145, "steel")
        for y in range(112, 244, 22):
            c.rect(x+1, y, 6, 3, "steel")
            c.rect(x+2, y, 1, 1, "face")
        shoe(c, x-3, 252, 14)
    # The middle opening is transparent. Jambs are in the rear scenic plane,
    # not extra solid side walls: the production collision remains only 14px.
    visible_depth = 160 if closed else depth
    if visible_depth:
        c.rect(57, 104, 14, visible_depth, "ink")
        c.rect(58, 104, 1, visible_depth, "edge")
        for y in range(104, 104+visible_depth-3, 16):
            h = min(14, 104+visible_depth-2-y)
            c.rect(59, y, 10, h, "steel")
            c.rect(60, y+1, 7, max(1, h-2), "face")
            c.rect(60, y+1, 6, 1, "edge")
        c.rect(58, 104+visible_depth-2, 12, 2, "amber" if warning else "bronze")
    # Below the feet, match the exact world-aligned deck strip pixel for pixel.
    c.bitmap(floor, 0, 264, "world-aligned-existing-deck-foundation")
    c.rect(52, 264, 24, 4, "shadow")
    c.rect(54, 264, 20, 1, "edge")
    for x in (53, 73):
        c.rect(x, 266, 2, 1, "bronze")
    lamp = "light" if warning else "amber" if closed else "cool"
    c.rect(54, 81, 21, 9, "ink")
    c.rect(57, 83, 15, 3, lamp)
    if warning:
        for y, x, w in ((89, 60, 8), (90, 61, 6), (91, 62, 4)):
            c.rect(x, y, w, 1, "amber")
    return c


def main():
    for variant, make, depths in (
        ("A", pillar_variant, (8, 16, 28, 44, 62, 80)),
        ("B", wall_variant, (8, 16, 28, 44, 62, 80)),
    ):
        make(0).save(variant, "open")
        for index, depth in enumerate(depths):
            make(depth, warning=True).save(variant, f"warning-{index}")
        make(148 if variant == "A" else 160, closed=True).save(variant, "closed")
    print("Built A/B: candidate x=3412, shoe last visible y=263, no production edits")


if __name__ == "__main__":
    main()
