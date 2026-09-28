"""Public deliverable contracts for the rescue-hangar art pass."""

import json
import unittest
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]


class HangarArtTests(unittest.TestCase):
    def test_character_frames_are_detailed_at_playable_scale(self):
        atlases = json.loads((ROOT / "assets/pixel/atlas.json").read_text(encoding="utf-8"))
        for name, minimum in (("operative", (48, 60)),
                              ("mechanical_soldier", (48, 60)),
                              ("defense_mech", (100, 88))):
            with self.subTest(name=name):
                width, height = atlases[name]["frame_size"]
                self.assertGreaterEqual(width, minimum[0])
                self.assertGreaterEqual(height, minimum[1])
                with Image.open(ROOT / "assets/pixel" / atlases[name]["image"]) as image:
                    self.assertEqual(image.size, (width * len(atlases[name]["frames"]), height))
        self.assertTrue(54 <= atlases["operative"]["frame_size"][1] <= 65)

    def test_far_and_midground_are_separate_original_pixel_layers(self):
        for name in ("hangar_far.png", "hangar_mid.png"):
            with self.subTest(name=name), Image.open(ROOT / "assets/pixel" / name) as image:
                self.assertEqual(image.size, (1440, 360))
                self.assertEqual(image.mode, "RGBA")
                alphas = set(image.getchannel("A").getdata())
                if name == "hangar_far.png":
                    self.assertEqual(alphas, {255})
                else:
                    self.assertIn(0, alphas)
                    self.assertIn(255, alphas)
                    self.assertTrue(any(0 < value < 255 for value in alphas))
        with Image.open(ROOT / "assets/pixel/hangar_deck.png") as image:
            self.assertEqual(image.size, (1440, 108))

    def test_display_is_integer_scaled_from_640_by_360(self):
        project = (ROOT / "project.godot").read_text(encoding="utf-8")
        for setting in ("window/size/viewport_width=640", "window/size/viewport_height=360",
                        "window/size/window_width_override=1280",
                        "window/size/window_height_override=720",
                        'window/stretch/mode="viewport"', 'window/stretch/scale_mode="integer"'):
            with self.subTest(setting=setting):
                self.assertIn(setting, project)


if __name__ == "__main__":
    unittest.main()
