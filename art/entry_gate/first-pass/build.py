"""Original pixel geometry for #32. Emit editable SVG and identical RGBA PNG.

Run from any directory: python art/entry_gate/build.py
Only this review-art directory is written; no production assets are replaced.
"""

from pathlib import Path
from xml.sax.saxutils import escape

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
SIZE = (40, 176)
PALETTE = {
    "ink": "#101c26", "shadow": "#1c2a34", "steel": "#34434a",
    "face": "#4b595b", "edge": "#728181", "glint": "#9ca59b",
    "rust": "#514132", "bronze": "#83613b", "amber": "#cf963c",
    "light": "#ffce6a", "cool": "#568989",
}


class Drawing:
    def __init__(self):
        self.image = Image.new("RGBA", SIZE)
        self.draw = ImageDraw.Draw(self.image)
        self.svg = []

    def rect(self, x, y, width, height, color):
        color = PALETTE[color]
        self.draw.rectangle((x, y, x + width - 1, y + height - 1), fill=color)
        self.svg.append(f'<rect x="{x}" y="{y}" width="{width}" '
                        f'height="{height}" fill="{color}"/>')

    def group(self, name):
        self.svg.append(f'<g id="{escape(name)}">')

    def end(self):
        self.svg.append('</g>')

    def save(self, name):
        self.image.save(ROOT / f"{name}.png")
        source = ('<svg xmlns="http://www.w3.org/2000/svg" width="40" height="176" '
                  'viewBox="0 0 40 176" shape-rendering="crispEdges">\n'
                  + '\n'.join(self.svg) + '\n</svg>\n')
        (ROOT / f"{name}.svg").write_text(source, encoding="utf-8")


def gate(depth, warning=False, closed=False):
    p = Drawing()
    # 14px active silhouette, matching the existing collision width exactly.
    p.group("segmented-steel-shutter")
    if depth:
        p.rect(13, 28, 14, depth, "ink")
        p.rect(14, 28, 1, depth, "edge")
        p.rect(25, 28, 1, depth, "steel")
        for y in range(28, 28 + depth - 5, 18):
            h = min(16, 28 + depth - 4 - y)
            if h < 4:
                continue
            p.rect(15, y, 10, h, "steel")
            p.rect(16, y + 1, 7, h - 2, "face")
            p.rect(16, y + 1, 7, 1, "edge")
            p.rect(17, y + 4, 5, 2, "shadow")
            p.rect(23, y + 3, 1, max(1, h - 5), "shadow")
            p.rect(16, y + h - 2, 5, 1, "rust")
            p.rect(15, y + 2, 1, 1, "glint")
        # Weighted bottom shoe: visible direction, no particles or floor bloom.
        p.rect(13, 28 + depth - 4, 14, 4, "ink")
        p.rect(14, 28 + depth - 4, 12, 1, "bronze")
        p.rect(16, 28 + depth - 3, 8, 1, "amber" if warning else "edge")
        if closed:
            for y in (67, 121):
                p.rect(16, y, 8, 4, "ink")
                p.rect(17, y + 1, 6, 2, "bronze")
                p.rect(19, y + 1, 2, 1, "amber")
    p.end()
    p.group("ceiling-bracket-and-retraction-cassette")
    p.rect(5, 4, 30, 19, "ink")
    p.rect(2, 8, 4, 13, "shadow")
    p.rect(34, 8, 4, 13, "shadow")
    p.rect(6, 5, 28, 2, "edge")
    p.rect(6, 7, 28, 13, "steel")
    p.rect(7, 8, 4, 10, "face")
    p.rect(29, 8, 4, 10, "face")
    for x in (7, 30):
        p.rect(x, 9, 2, 2, "glint")
        p.rect(x, 16, 2, 2, "ink")
    p.rect(12, 8, 16, 9, "ink")
    for y in (9, 12, 15):
        p.rect(13, y, 14, 1, "bronze" if y == 15 else "face")
    p.rect(7, 20, 26, 3, "shadow")
    p.rect(10, 22, 20, 3, "ink")
    p.rect(11, 23, 18, 1, "edge")
    # Short guide horns stop above the passage; open does not read as a wall.
    for x in (10, 28):
        p.rect(x, 24, 2, 12, "shadow")
        p.rect(x, 24, 1, 8, "edge")
    p.end()
    p.group("status-lamps-and-direction-chevron")
    lamp = "light" if warning else "amber" if closed else "cool"
    for x in (4, 33):
        p.rect(x, 11, 3, 6, "ink")
        p.rect(x + 1, 12, 1, 4, lamp)
    p.rect(15, 19, 10, 1, "light" if warning else "bronze")
    if warning:
        for y, x, w in ((24, 16, 8), (25, 17, 6), (26, 18, 4), (27, 19, 2)):
            p.rect(x, y, w, 1, "amber")
    elif closed:
        p.rect(17, 25, 6, 2, "amber")
    else:
        p.rect(17, 25, 2, 1, "cool")
        p.rect(21, 25, 2, 1, "cool")
    p.end()
    return p


def main():
    gate(0).save("open")
    # Hold a full standing passage until the existing collision closes.
    # These are art poses, not replacement physics or a new warning duration.
    for index, depth in enumerate((8, 16, 28, 44, 62, 80)):
        gate(depth, warning=True).save(f"warning-{index}")
    gate(148, closed=True).save("closed")
    print("Built 8 editable SVG poses and matching PNGs in", ROOT)


if __name__ == "__main__":
    main()
