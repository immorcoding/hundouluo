"""Pack the approved #32 B-left16 exports at 1:1, without changing pixels."""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parents[1] / "art/entry_gate/b-left/left16"
STATES = ("open", *(f"warning-{i}" for i in range(6)), "closed")
FRAME_SIZE = (128, 288)


def build():
    atlas = Image.new("RGBA", (FRAME_SIZE[0] * len(STATES), FRAME_SIZE[1]))
    for index, state in enumerate(STATES):
        with Image.open(SOURCE / f"{state}.png") as frame:
            if frame.size != FRAME_SIZE:
                raise ValueError(f"Unexpected approved frame size: {state} {frame.size}")
            atlas.paste(frame.convert("RGBA"), (index * FRAME_SIZE[0], 0))
    return atlas


if __name__ == "__main__":
    build().save(ROOT / "gate.png")
    print("Packed 8 approved B-left16 frames: 1024x288, anchor (64,252)")
