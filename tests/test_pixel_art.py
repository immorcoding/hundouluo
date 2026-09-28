"""Static checks for the deliverable, independent of a Godot project."""

import json
import unittest
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "pixel"


class PixelArtTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.atlases = json.loads((OUT / "atlas.json").read_text(encoding="utf-8"))

    def test_atlas_dimensions_alpha_and_palette(self):
        for name, info in self.atlases.items():
            with self.subTest(name=name), Image.open(OUT / info["image"]) as image:
                w, h = info["frame_size"]
                self.assertEqual(image.mode, "RGBA")
                self.assertEqual(image.size, (w * info["layout"]["columns"], h))
                self.assertEqual(info["layout"]["columns"], len(info["frames"]))
                self.assertEqual(set(info["frames"].values()), set(range(len(info["frames"]))))
                self.assertEqual(set(image.getchannel("A").getdata()) <= {0, 255}, True)
                # Generated-assisted actors use 48 RGBA entries; original tiles
                # keep their 24-color contract. Runtime art stays finite-palette.
                limit = 24 if name == "base_tiles" else 48
                self.assertEqual(info["palette_limit"], limit)
                self.assertLessEqual(len(image.getcolors(image.width * image.height)), limit)
                for i in range(info["layout"]["columns"]):
                    self.assertIsNotNone(image.crop((i * w, 0, (i + 1) * w, h)).getbbox())

    def test_animation_refs_facing_and_gap_edge_variants(self):
        for name, info in self.atlases.items():
            with self.subTest(name=name):
                for sequence in info["animations"].values():
                    self.assertTrue(sequence)
                    self.assertTrue(set(sequence) <= set(info["frames"]))
        self.assertEqual(self.atlases["operative"]["facing"], "right")
        self.assertEqual(self.atlases["mechanical_soldier"]["facing"], "left")
        self.assertGreater(self.atlases["defense_mech"]["frame_size"][0],
                           self.atlases["mechanical_soldier"]["frame_size"][0] * 2)
        with Image.open(OUT / "base_tiles.png") as tiles:
            left = tiles.crop((2 * 24, 0, 3 * 24, 24))
            right = tiles.crop((3 * 24, 0, 4 * 24, 24))
            self.assertNotEqual(left.tobytes(), right.tobytes())


if __name__ == "__main__":
    unittest.main()
