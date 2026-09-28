"""Build current game art from checked-in ImageGen sources and original tiles.

Requires Pillow 10+. No network or generation call is needed to rebuild.
"""

import json

from PIL import Image

from assemble_hangar_art import OUT, ROOT, assemble_characters, assemble_environment
from legacy_pixel_art import tile


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    metadata = assemble_characters()
    tiles = ["floor", "floor_vent", "gap_left", "gap_right", "wall", "wall_vent",
             "repair", "rescue_sign", "beacon_off", "beacon_on", "floor_sub",
             "gap_wall_left", "gap_wall_right"]
    image = Image.new("RGBA", (len(tiles) * 24, 24))
    for index, name in enumerate(tiles):
        image.alpha_composite(tile(name), (index * 24, 0))
    image.save(OUT / "base_tiles.png", optimize=True)
    metadata["base_tiles"] = {
        "image": "base_tiles.png", "frame_size": [24, 24],
        "layout": {"columns": len(tiles), "rows": 1, "margin": 0, "separation": 0},
        "frames": {name: index for index, name in enumerate(tiles)},
        "animations": {"beacon": ["beacon_off", "beacon_on"]},
        "suggested_fps": 1, "origin": "bottom-center", "facing": "left",
        "filter": "nearest", "palette_limit": 24,
        "source": "tools/legacy_pixel_art.py (programmatic original tiles)",
    }
    (OUT / "atlas.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    assemble_environment()
    preview_dir = ROOT / "docs/art"
    for name in metadata:
        with Image.open(OUT / f"{name}.png") as image:
            preview = Image.new("RGBA", image.size, "#253747")
            preview.alpha_composite(image)
            preview.resize((image.width * 3, image.height * 3), Image.Resampling.NEAREST).convert(
                "RGB").save(preview_dir / f"{name}-frames-3x.png", optimize=True)


if __name__ == "__main__":
    main()
