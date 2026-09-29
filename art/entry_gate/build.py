"""Original pixel geometry for #32. Emit editable SVG and identical RGBA PNG.

Run from any directory: python art/entry_gate/build.py
Only this review-art directory is written; no production assets are replaced.
"""

import base64
import io
from pathlib import Path
from xml.sax.saxutils import escape

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
SIZE = (96, 252)
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

    def pillar(self):
        # Reuse the approved #22 environment pillar, not a third-party asset.
        # The first pillar has no cases overlapping it, unlike the middle one.
        with Image.open(ROOT.parents[1] / "assets/pixel/hangar_mid.png") as source:
            pillar = source.crop((28, 0, 90, 252)).convert("RGBA")
        self.image.alpha_composite(pillar)
        stream = io.BytesIO()
        pillar.save(stream, format="PNG")
        data = base64.b64encode(stream.getvalue()).decode("ascii")
        self.svg.append('<g id="approved-22-pillar"><image x="0" y="0" '
                        'width="62" height="252" href="data:image/png;base64,'
                        + data + '"/></g>')

    def save(self, name):
        self.image.save(ROOT / f"{name}.png")
        source = ('<svg xmlns="http://www.w3.org/2000/svg" width="96" height="252" '
                  'viewBox="0 0 96 252" shape-rendering="crispEdges">\n'
                  + '\n'.join(self.svg) + '\n</svg>\n')
        (ROOT / f"{name}.svg").write_text(source, encoding="utf-8")


def gate(depth, warning=False, closed=False):
    p = Drawing()
    p.pillar()
    # Physical connection to the ceiling and the approved column, with a narrow
    # guide behind the walk plane. Decorative structure is never a collider.
    p.group("ceiling-tie-conduit-and-guide")
    p.rect(36, 0, 47, 6, "ink")
    p.rect(38, 1, 43, 2, "steel")
    p.rect(71, 4, 9, 79, "ink")
    p.rect(72, 6, 3, 75, "steel")
    p.rect(75, 8, 1, 71, "edge")
    for y in (18, 42, 66):
        p.rect(70, y, 10, 4, "shadow")
        p.rect(71, y, 8, 1, "face")
    p.rect(73, 100, 6, 143, "ink")
    p.rect(73, 102, 2, 140, "steel")
    p.rect(76, 104, 1, 136, "shadow")
    for y in (121, 161, 201, 235):
        p.rect(73, y, 6, 3, "face")
        p.rect(75, y, 1, 1, "edge")
    # Footing belongs to the background plane, stops before the deck surface.
    p.rect(72, 242, 12, 9, "ink")
    p.rect(74, 243, 8, 6, "steel")
    p.rect(74, 243, 8, 1, "edge")
    p.rect(77, 246, 3, 2, "bronze")
    p.end()
    p.group("column-connected-winding-beam")
    p.rect(35, 80, 48, 22, "ink")
    p.rect(37, 81, 44, 2, "edge")
    p.rect(38, 83, 43, 16, "steel")
    p.rect(39, 84, 9, 13, "face")
    p.rect(49, 84, 28, 12, "shadow")
    for x in range(50, 77, 5):
        p.rect(x, 85, 2, 9, "face")
        p.rect(x, 85, 2, 1, "edge")
    p.rect(40, 98, 40, 3, "shadow")
    for x in (40, 77):
        p.rect(x, 86, 2, 2, "glint")
        p.rect(x, 94, 2, 2, "ink")
    p.rect(54, 100, 21, 4, "ink")
    p.rect(55, 101, 19, 1, "edge")
    p.end()
    # 14px active silhouette, matching the existing collision width exactly.
    p.group("segmented-steel-shutter")
    if depth:
        p.rect(57, 104, 14, depth, "ink")
        p.rect(58, 104, 1, depth, "edge")
        p.rect(69, 104, 1, depth, "steel")
        for y in range(104, 104 + depth - 5, 18):
            h = min(16, 104 + depth - 4 - y)
            if h < 4:
                continue
            p.rect(59, y, 10, h, "steel")
            p.rect(60, y + 1, 7, h - 2, "face")
            p.rect(60, y + 1, 7, 1, "edge")
            p.rect(61, y + 4, 5, 2, "shadow")
            p.rect(67, y + 3, 1, max(1, h - 5), "shadow")
            p.rect(60, y + h - 2, 5, 1, "rust")
            p.rect(59, y + 2, 1, 1, "glint")
        # Weighted bottom shoe: visible direction, no particles or floor bloom.
        p.rect(57, 104 + depth - 4, 14, 4, "ink")
        p.rect(58, 104 + depth - 4, 12, 1, "bronze")
        p.rect(60, 104 + depth - 3, 8, 1, "amber" if warning else "edge")
        if closed:
            for y in (143, 197):
                p.rect(60, y, 8, 4, "ink")
                p.rect(61, y + 1, 6, 2, "bronze")
                p.rect(63, y + 1, 2, 1, "amber")
    p.end()
    p.group("status-lamps-and-direction-chevron")
    lamp = "light" if warning else "amber" if closed else "cool"
    p.rect(78, 104, 5, 10, "ink")
    p.rect(79, 105, 3, 7, lamp)
    p.rect(59, 98, 10, 2, "light" if warning else "bronze")
    if warning:
        for y, x, w in ((103, 60, 8), (104, 61, 6), (105, 62, 4), (106, 63, 2)):
            p.rect(x, y, w, 1, "amber")
    elif closed:
        p.rect(61, 103, 6, 2, "amber")
    else:
        p.rect(61, 103, 2, 1, "cool")
        p.rect(65, 103, 2, 1, "cool")
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
