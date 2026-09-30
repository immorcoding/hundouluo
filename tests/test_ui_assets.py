"""Approved artwork, licensing and live-render acceptance boundaries for #30."""

import hashlib
import json
from pathlib import Path
import unittest

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
UI = ROOT / "assets/ui_v011"
DESIGN = ROOT / "prototypes/issue-27-ui"
EVIDENCE = ROOT / "docs/art/issue-30"
STATES = (
    "start", "gap-left", "mech-full", "combat", "hurt", "low", "mech-one",
    "failure", "fall", "complete", "retry-failure", "retry-fall", "retry-complete",
)


class ApprovedUIAssetsTests(unittest.TestCase):
    def test_frozen_s6_sources_and_reference_images_are_unchanged(self):
        manifest = json.loads((DESIGN / "outcome-review/approved-hud.json").read_text())
        for relative, record in manifest["files"].items():
            with self.subTest(file=relative):
                data = (ROOT / relative).read_bytes()
                if record["normalization"] == "LF":
                    data = data.replace(b"\r\n", b"\n")
                self.assertEqual(hashlib.sha256(data).hexdigest(), record["sha256"])

    def test_runtime_crops_preserve_approved_source_pixels(self):
        # Rectangles come from the approved handoff, independent of the builder.
        cuts = (
            ("portrait", "throwaway-ab/source/operative-portrait.png", (310, 184, 966, 816)),
            ("rifle", "throwaway-portrait-match/source/rifle.png", (136, 118, 2064, 658)),
            ("outcome-top", "source/console-panel.png", (20, 92, 1754, 192)),
            ("outcome-bottom", "source/console-panel.png", (20, 674, 1754, 774)),
        )
        for name, source, rectangle in cuts:
            with self.subTest(asset=name):
                with Image.open(DESIGN / source) as original, Image.open(UI / (name + ".png")) as actual:
                    expected = original.convert("RGBA").crop(rectangle)
                    self.assertEqual(actual.size, expected.size)
                    self.assertEqual(actual.convert("RGBA").tobytes(), expected.tobytes())

    def test_font_is_original_and_distribution_manifest_carries_complete_notices(self):
        font = UI / "fusion-pixel-12px-proportional-zh_hans.otf"
        self.assertEqual(hashlib.sha256(font.read_bytes()).hexdigest(),
                         "e84b6d1ab8f2e25084761eb61c88b373bf1fa0b0c5e9b559d5b1d90e4d658c86")
        distributed_manifest = (ROOT / "docs/assets-manifest.md").read_text(encoding="utf-8-sig")
        for notice in (UI / "OFL.txt", *sorted((UI / "LICENSES").rglob("*.txt"))):
            with self.subTest(notice=notice.relative_to(UI)):
                self.assertIn(notice.read_text(encoding="utf-8-sig").strip(), distributed_manifest)

    def test_live_ui_matches_approved_overlay_with_local_color_tolerances(self):
        for state in STATES:
            with self.subTest(state=state):
                with Image.open(EVIDENCE / (state + ".png")) as actual, Image.open(EVIDENCE / (state + "-approved-overlay.png")) as expected:
                    self.assertEqual(actual.size, (640, 360))
                    difference = ImageChops.difference(actual.convert("RGB"), expected.convert("RGB"))
                    outcome = state in ("failure", "fall", "complete")
                    regions = (((176, 88, 464, 104), 5), ((176, 220, 464, 236), 5)) if outcome else (
                        ((16, 296, 64, 344), 3), ((70, 298, 146, 322), 3))
                    for rectangle, tolerance in regions:
                        self.assertLessEqual(max(high for low, high in difference.crop(rectangle).getextrema()), tolerance)
                        x1, y1, x2, y2 = rectangle
                        ImageDraw.Draw(difference).rectangle((x1, y1, x2 - 1, y2 - 1), fill=(0, 0, 0))
                    self.assertLessEqual(max(high for low, high in difference.getextrema()), 1 if outcome else 0)

    def test_acceptance_images_use_exact_nearest_integer_double(self):
        for state in STATES:
            with self.subTest(state=state):
                with Image.open(EVIDENCE / (state + ".png")) as native, Image.open(EVIDENCE / (state + "-2x.png")) as doubled:
                    self.assertEqual(doubled.size, (1280, 720))
                    expected = native.convert("RGB").resize((1280, 720), Image.Resampling.NEAREST)
                    self.assertEqual(doubled.convert("RGB").tobytes(), expected.tobytes())


if __name__ == "__main__":
    unittest.main()
