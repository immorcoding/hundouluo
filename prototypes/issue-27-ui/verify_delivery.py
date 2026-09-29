"""Read-only delivery checks: dimensions, exact 2x pixels, safe area and provenance."""
from pathlib import Path
import hashlib
import re
import unittest

from PIL import Image, ImageChops
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent
STATES = ("start", "hud", "low-health", "death", "fall", "complete")
BOUNDARIES = ("life-two", "boss-full", "boss-one")


def rgb(path):
    with Image.open(ROOT / path) as image:
        return image.convert("RGB")


class DeliveryChecks(unittest.TestCase):
    def test_six_native_captures_and_exact_double_exports(self):
        for state in STATES:
            with self.subTest(state=state):
                native = rgb(f"previews/{state}.png")
                self.assertEqual(native.size, (640, 360))
                self.assertEqual(rgb(f"captures/{state}.png").size, (640, 360))
                double = rgb(f"previews-2x/{state}.png")
                self.assertEqual(double.size, (1280, 720))
                expected = native.resize((1280, 720), Image.Resampling.NEAREST)
                self.assertIsNone(ImageChops.difference(expected, double).getbbox())

    def test_gameplay_safe_area_is_unchanged(self):
        for state in ("start", "hud", "low-health"):
            with self.subTest(state=state):
                preview = rgb(f"previews/{state}.png").crop((0, 64, 640, 360))
                capture = rgb(f"captures/{state}.png").crop((0, 64, 640, 360))
                self.assertIsNone(ImageChops.difference(preview, capture).getbbox())
        # No boss module in the ordinary gap scene.
        self.assertIsNone(ImageChops.difference(
            rgb("previews/start.png").crop((350, 0, 640, 64)),
            rgb("captures/start.png").crop((350, 0, 640, 64)),
        ).getbbox())

    def test_boundary_exports_and_remaining_health(self):
        for state in BOUNDARIES:
            native = rgb(f"boundaries/{state}.png")
            self.assertEqual(native.size, (640, 360))
            self.assertIsNone(ImageChops.difference(
                native.resize((1280, 720), Image.Resampling.NEAREST),
                rgb(f"boundaries/{state}-2x.png"),
            ).getbbox())
        # A remaining point has visible amber fill; it is not lost to a tick mark.
        amber = (255, 203, 123)
        self.assertEqual(rgb("boundaries/boss-one.png").getpixel((380, 40)), amber)
        self.assertNotEqual(rgb("boundaries/boss-one.png").getpixel((381, 40)), amber)
        self.assertEqual(rgb("boundaries/boss-full.png").getpixel((611, 40)), amber)

    def test_approved_frame_source_is_unchanged(self):
        digest = hashlib.sha256((ROOT / "source/console-panel.png").read_bytes()).hexdigest()
        self.assertEqual(digest, "069e44a40374c8028cb62864f9d212609a9c782d59a045fb5097912a82a4eba0")

    def test_original_font_license_and_glyph_coverage(self):
        font_path = ROOT / "source/fonts/fusion-pixel-12px-proportional-zh_hans.otf"
        self.assertEqual(hashlib.sha256(font_path.read_bytes()).hexdigest(),
                         "e84b6d1ab8f2e25084761eb61c88b373bf1fa0b0c5e9b559d5b1d90e4d658c86")
        license_text = (ROOT / "source/fonts/OFL.txt").read_text(encoding="utf-8")
        self.assertIn("Copyright (c) 2022, TakWolf", license_text)
        self.assertIn("SIL OPEN FONT LICENSE Version 1.1", license_text)
        for path in ("ark-pixel/OFL.txt", "cubic-11/OFL.txt", "galmuri/LICENSE.txt"):
            self.assertTrue((ROOT / "source/fonts/LICENSES" / path).is_file())
        source = (ROOT / "design_ui.gd").read_text(encoding="utf-8")
        required = re.search(r'const REQUIRED_GLYPHS := "([^"]+)"', source).group(1)
        with TTFont(font_path) as font:
            cmap = font.getBestCmap()
            self.assertEqual([char for char in required if ord(char) not in cmap], [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
