"""Lossless APNG evidence from native frames; no runtime art is edited."""
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "docs/art/issue-31"


def native(path):
    with Image.open(path) as image:
        if image.size != (640, 360):
            raise ValueError(f"Non-native capture: {path}")
        return image.convert("RGB")


def main():
    loops = []
    evidence = json.loads((ROOT / "capture-results.json").read_text(encoding="utf-8"))
    records = {record["sequence"]: record for record in evidence["sequences"]}
    for sequence in ("run-jump", "soldier", "gap", "entry", "cancel", "boundary", "advance", "legal-run"):
        record = records[sequence]
        last_tick = record["timeline"][-1]["tick"] if sequence == "legal-run" else record["frames"] - 1
        files = sorted(path for path in (ROOT / "frames").glob(f"{sequence}-*.png")
                       if int(path.stem.rsplit("-", 1)[1]) <= last_tick)
        step = 1 if sequence == "legal-run" else 2
        selected = files[::step]
        frames = [native(path) for path in selected]
        duration = 200 if sequence == "legal-run" else 1000 / 30
        durations = [duration] * len(frames)
        if sequence == "legal-run":
            # Keep the final sampled still only until the real finishing tick.
            last_sample = int(selected[-1].stem.rsplit("-", 1)[1])
            durations[-1] = (last_tick + 1 - last_sample) * 1000 / 60
        path = ROOT / f"{sequence}-loop.png"
        frames[0].save(path, format="PNG", save_all=True, append_images=frames[1:],
                       duration=durations, loop=0, disposal=0, blend=0)
        with Image.open(path) as image:
            if image.size != (640, 360) or image.n_frames < 2:
                raise ValueError(f"Invalid loop: {path}")
            actual = sum((image.seek(i), image.info["duration"])[1] for i in range(image.n_frames))
            if abs(actual - sum(durations)) > 1:
                raise ValueError(f"Loop timing changed: {path}")
            # APNG may merge consecutive equal frames; validate native playback
            # pixels against the source sequence at the retained durations.
            source_index = 0
            for index in range(image.n_frames):
                image.seek(index)
                if image.convert("RGB").tobytes() != frames[source_index].tobytes():
                    raise ValueError(f"Lossless playback mismatch: {path} frame {index}")
                source_index += round(image.info["duration"] / duration)
        loops.append({"sequence": sequence, "path": path.name, "native_size": [640, 360],
                      "source_frames": len(frames), "duration_ms": actual, "lossless": True})
        print(f"{sequence}: 640x360 / {actual:.2f}ms / {path.stat().st_size} bytes")
    states = ("run-jump-motion", "soldier-motion", "soldier-late", "gap-airborne",
              "entry-early", "entry-warning", "entry-closed", "cancel-late",
              "boundary-wait-hit", "boundary-peek-hit", "advance-late", "legal-victory",
              "health-death", "fall-death", "fixture-victory", "legal-retry")
    sheet = Image.new("RGB", (1280, 392 * 8), "#101c26")
    draw = ImageDraw.Draw(sheet)
    for index, state in enumerate(states):
        x, y = index % 2 * 640, index // 2 * 392
        draw.text((x + 12, y + 10), state + " / native Godot 640x360", fill="#e6bc78")
        sheet.paste(native(ROOT / f"{state}.png"), (x, y + 32))
    sheet.save(ROOT / "state-contact-sheet.png")
    (ROOT / "presentation-results.json").write_text(json.dumps(loops, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
