"""Verify native merged-level evidence and encode exact-speed lossless APNGs.

Only captured frame presentation; production art is never edited. The corpse
comparison uses actual visibility component renders. Muzzle evidence reports
runtime geometric checks only, not independent atlas pixel-match acceptance.
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image

from present_issue_35 import exact_speed

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/art/issue-31-rc2"
RAW = ROOT / ".godot/issue31-rc2/frames"


def rgb(path):
    image = Image.open(path).convert("RGB")
    if image.size != (640, 360):
        raise ValueError(f"Non-native viewport: {path}")
    return image


def layer_probe(name):
    images = {
        key: np.asarray(rgb(OUT / f"{name}-{key}.png"))
        for key in ("background", "corpse-only", "actor-only", "combined")
    }
    background, corpse, actor, mixed = [images[key] for key in images]
    actor_visible = np.any(actor != background, axis=2)
    corpse_visible = np.any(corpse != background, axis=2)
    overlap = actor_visible & corpse_visible & np.any(actor != corpse, axis=2)
    front = overlap & np.all(mixed == actor, axis=2)
    behind = overlap & np.all(mixed == corpse, axis=2)
    count = int(overlap.sum())
    result = {
        "name": name, "overlap_pixels": count,
        "operative_front_pixels": int(front.sum()),
        "corpse_front_pixels": int(behind.sum()),
        "other_pixels": int(count - front.sum() - behind.sum()),
        "corpse_visible_pixels": int(corpse_visible.sum()),
        "operative_front_ratio": float(front.sum() / max(count, 1)),
    }
    if count < 8 or result["operative_front_ratio"] < .95 or corpse_visible.sum() < 100:
        raise ValueError(f"Rendered corpse foreground check failed: {result}")
    return result


def animation(sequence, fps):
    paths = sorted((RAW / sequence).glob("*.png"))
    frames = [rgb(path) for path in paths]
    if not frames:
        raise ValueError(f"No raw frames: {sequence}")
    output = OUT / f"{sequence}-loop.png"
    frames[0].save(output, save_all=True, append_images=frames[1:],
                   duration=1000 / fps, loop=0, disposal=0, blend=0)
    exact_speed(output, fps)
    index = 0
    seconds = 0
    with Image.open(output) as saved:
        for frame in range(saved.n_frames):
            saved.seek(frame)
            repeat = round(saved.info["duration"] * fps / 1000)
            for _ in range(repeat):
                if saved.convert("RGB").tobytes() != frames[index].tobytes():
                    raise ValueError(f"Lossless mismatch: {sequence}/{index}")
                index += 1
            seconds += saved.info["duration"] / 1000
    if index != len(frames) or abs(seconds - len(frames) / fps) > .000001:
        raise ValueError(f"Duration mismatch: {sequence}")
    return {"sequence": sequence, "native_size": [640, 360], "frames": len(frames),
            "fps": fps, "seconds": seconds, "lossless": True,
            "sampling": "Every physics frame" if fps == 60 else
            "Legal run sampled every 12 physics frames; exact 5fps sampling cadence, not a 60fps recording"}


def main():
    capture = json.loads((OUT / "capture-results.json").read_text(encoding="utf-8"))
    if capture["failures"]:
        raise ValueError(capture["failures"])
    results = {
        "animations": [animation("legal-run", 5), animation("corpse-follow", 60),
                       animation("gate-fixed", 60)],
        "corpse_pixel_checks": [layer_probe(name) for name in
            ("soldier-standing", "soldier-moving-right", "soldier-moving-left", "mech-victory")],
        "muzzle_pixel_probe": "Not reclassified: prior #35 three low-confidence atlas probes remain inconclusive. New evidence uses visible native motion plus <=1px runtime muzzle and <0.05px independent projectile trajectory checks.",
    }
    (OUT / "presentation-results.json").write_text(
        json.dumps(results, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(results, ensure_ascii=False))


if __name__ == "__main__":
    main()
