"""Deterministically assemble generated source art into Godot-sized layers.

Sources are built-in ImageGen outputs, NOT hand-drawn pixel artwork. Resizing,
alpha cleanup, palette reduction and atlas layout are technical postprocessing.
See assets/art_source/README.md for prompts and provenance.
"""

import json
from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/art_source"
OUT = ROOT / "assets/pixel"


def reduced(image, colors=128):
    """A finite, non-dithered palette prevents noisy subpixel texture at 1x."""
    alpha = image.getchannel("A")
    result = image.convert("RGB").quantize(colors, dither=Image.Dither.NONE).convert("RGBA")
    result.putalpha(alpha)
    return result


def source_image(name):
    with Image.open(SOURCE / name) as image:
        return image.convert("RGBA")


def prop(sheet, bounds, size):
    image = sheet.crop(bounds)
    # Ignore extremely faint generator glow when finding the physical object.
    bounds = image.getchannel("A").point(lambda a: 255 if a > 96 else 0).getbbox()
    if bounds is None:
        raise ValueError("Empty source prop")
    image = image.crop(bounds).resize(size, Image.Resampling.LANCZOS)
    # ImageGen uses 254 for some solid pixels; keep glows, snap near-solid alpha.
    image.putalpha(image.getchannel("A").point(lambda a: 255 if a >= 245 else a))
    return image


def assemble_environment():
    far = source_image("hangar-background.png").resize((1440, 360), Image.Resampling.LANCZOS)
    reduced(far).save(OUT / "hangar_far.png")

    sheet = source_image("props.png")
    pillar = prop(sheet, (80, 0, 450, 1024), (62, 260))
    crane = prop(sheet, (500, 0, 850, 1024), (46, 172))
    cases = prop(sheet, (880, 620, 1510, 1024), (100, 54))
    mid = Image.new("RGBA", (1440, 360))
    for x in (28, 646, 1300):
        mid.alpha_composite(pillar, (x, -8))
    for x in (166, 989):
        mid.alpha_composite(crane, (x, -16))
    for x in (95, 590, 1188):
        mid.alpha_composite(cases, (x, 198))
    reduced(mid).save(OUT / "hangar_mid.png")

    # A long source strip repeats only every 720px, beyond one viewport.
    section = source_image("platform.png").resize((720, 240), Image.Resampling.LANCZOS)
    section = section.crop((0, 0, 720, 108))
    deck = Image.new("RGBA", (1440, 108))
    for x in (0, 720):
        deck.alpha_composite(section, (x, 0))
    reduced(deck).save(OUT / "hangar_deck.png")


def assemble_characters():
    manifest = json.loads((SOURCE / "frames.json").read_text(encoding="utf-8"))
    metadata = {}
    for name, spec in manifest.items():
        sheet = source_image(spec["source"])
        frames = []
        for frame in spec["frames"]:
            image = sheet.crop(frame["crop"])
            image.putalpha(image.getchannel("A").point(lambda a: 255 if a >= 128 else 0))
            image.putalpha(clean_sprite_alpha(image.getchannel("A")))
            bounds = image.getbbox()
            if bounds is None:
                raise ValueError(f"Empty {name} frame: {frame['name']}")
            frames.append(image.crop(bounds))
        scale = spec["standing_height"] / frames[0].height
        width, height = spec["frame_size"]
        strip = Image.new("RGBA", (width * len(frames), height))
        for index, (image, frame) in enumerate(zip(frames, spec["frames"])):
            size = (round(image.width * scale), round(image.height * scale))
            image = image.resize(size, Image.Resampling.LANCZOS)
            image.putalpha(image.getchannel("A").point(lambda a: 255 if a >= 128 else 0))
            x = round(width / 2 - image.width * frame.get("anchor_x", spec["anchor_x"]))
            y = frame.get("top", height - image.height)
            if x < 0 or x + image.width > width or y < 0 or y + image.height > height:
                raise ValueError(f"{name}/{frame['name']} exceeds atlas cell: {(x, y, size)}")
            strip.alpha_composite(image, (index * width + x, y))
        # 47 RGB colors plus transparent pixels: at most 48 RGBA entries.
        strip = reduced(strip, 47)
        transparent = Image.new("RGBA", strip.size)
        transparent.paste(strip, mask=strip.getchannel("A"))
        transparent.save(OUT / f"{name}.png")
        metadata[name] = {
            "image": f"{name}.png", "frame_size": spec["frame_size"],
            "layout": {"columns": len(frames), "rows": 1, "margin": 0, "separation": 0},
            "frames": {frame["name"]: i for i, frame in enumerate(spec["frames"])},
            "animations": spec["animations"], "suggested_fps": spec["fps"],
            "origin": "bottom-center", "facing": spec["facing"], "filter": "nearest",
            "ground_baseline_y": height - 1, "palette_limit": 48,
            "loop_notes": "down is terminal; hurt/fire are event frames",
            "source": f"assets/art_source/{spec['source']} (ImageGen + atlas postprocessing)",
        }
    return metadata


def clean_sprite_alpha(alpha):
    """Remove isolated generator specks and tiny fragments of adjacent cells.

    Keep substantial detached muzzle flashes, not just the largest silhouette.
    Operates on binary alpha before resizing; source PNGs remain untouched.
    """
    width, height = alpha.size
    remaining = {index for index, value in enumerate(alpha.getdata()) if value}
    components = []
    while remaining:
        start = remaining.pop()
        queue = deque([start])
        component = [start]
        while queue:
            index = queue.popleft()
            x, y = index % width, index // width
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                neighbor = ny * width + nx
                if 0 <= nx < width and 0 <= ny < height and neighbor in remaining:
                    remaining.remove(neighbor)
                    queue.append(neighbor)
                    component.append(neighbor)
        components.append(component)
    result = bytearray(width * height)
    minimum = max((len(part) for part in components), default=0) * 0.01
    for component in components:
        if len(component) >= minimum:
            for index in component:
                result[index] = 255
    return Image.frombytes("L", alpha.size, bytes(result))


if __name__ == "__main__":
    assemble_environment()
