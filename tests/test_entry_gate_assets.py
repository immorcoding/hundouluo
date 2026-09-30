"""The production atlas must preserve every approved #32 export pixel."""
from pathlib import Path
import unittest

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


class EntryGateAssetsTests(unittest.TestCase):
    def test_runtime_frames_equal_approved_b_left16_exports(self):
        source = ROOT / "art/entry_gate/b-left/left16"
        states = ["open", *(f"warning-{i}" for i in range(6)), "closed"]
        with Image.open(ROOT / "assets/entry_gate_v011/gate.png") as atlas:
            self.assertEqual(atlas.size, (1024, 288))
            for index, state in enumerate(states):
                with self.subTest(state=state), Image.open(source / f"{state}.png") as approved:
                    frame = atlas.crop((index * 128, 0, (index + 1) * 128, 288))
                    self.assertEqual(frame.convert("RGBA").tobytes(), approved.convert("RGBA").tobytes())


if __name__ == "__main__":
    unittest.main()
