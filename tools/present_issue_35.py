"""Native, lossless exact-speed APNGs and an independent rendered-pixel probe.

No runtime art is edited. Opaque flash cores are matched in the actual captured
viewport against the approved atlas, not against production muzzle offsets.
"""
import json
from pathlib import Path
import struct
import zlib

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/bugs/issue-35"


def exact_speed(path, fps):
    data = path.read_bytes()
    result = bytearray(data[:8])
    offset = 8
    while offset < len(data):
        size = struct.unpack_from(">I", data, offset)[0]
        kind = data[offset + 4:offset + 8]
        payload = data[offset + 8:offset + 8 + size]
        if kind == b"fcTL":
            numerator, denominator = struct.unpack_from(">HH", payload, 20)
            frames = round(numerator / denominator * fps)
            payload = payload[:20] + struct.pack(">HH", frames, fps) + payload[24:]
        result += struct.pack(">I", len(payload)) + kind + payload
        result += struct.pack(">I", zlib.crc32(kind + payload) & 0xffffffff)
        offset += size + 12
    path.write_bytes(result)


def pixel_probe(directory, trace):
    atlas = np.asarray(Image.open(ROOT / "assets/combat_v011/atlas.png").convert("RGBA"))
    records = []
    for frame in trace:
        if not frame["flashes"]:
            continue
        flash = frame["flashes"][-1]
        if flash["frame"] == 15:  # dim, translucent residue has no opaque core
            continue
        cell = atlas[120:160, (flash["frame"] - 12) * 48:(flash["frame"] - 11) * 48]
        if flash["mirrored"]:
            cell = cell[:, ::-1]
        py, px = np.where(cell[:, :, 3] > 240)
        rgb = np.asarray(Image.open(directory / "frames" / f'{frame["tick"]:03}.png').convert("RGB"), dtype=np.int16)
        bx, by = frame["screen_barrel"]
        xs = np.arange(max(24, round(bx) - 80), min(616, round(bx) + 81))
        ys = np.arange(max(20, round(by) - 60), min(340, round(by) + 61))
        score = np.zeros((len(ys), len(xs)))
        for y, x in zip(py, px):
            actual = rgb[(ys + y - 20)[:, None], (xs + x - 24)[None, :]]
            # Atlas cores are >94% opaque; <=25 RGB error tolerates their
            # blend with an unknown real background without reconstructing it.
            score += (np.abs(actual - cell[y, x, :3]).max(axis=2) <= 25)
        score /= len(px)
        best = score.max()
        candidates = np.argwhere(score == best)
        closest = min(candidates, key=lambda p: (xs[p[1]] - bx) ** 2 + (ys[p[0]] - by) ** 2)
        x, y = int(xs[closest[1]]), int(ys[closest[0]])
        error = float(np.hypot(x - bx, y - by))
        records.append({"tick": frame["tick"], "flash_frame": flash["frame"],
                        "matched_core_fraction": float(best), "pixel_center": [x, y],
                        "visible_barrel": [bx, by], "pixel_error": error,
                        "aligned": bool(best >= .75 and error <= 1.5),
                        "status": "inconclusive" if best < .75 else ("aligned" if error <= 1.5 else "misaligned")})
    return {"samples": len(records), "aligned": sum(r["aligned"] for r in records),
            "misaligned": sum(r["status"] == "misaligned" for r in records),
            "inconclusive": sum(r["status"] == "inconclusive" for r in records),
            "note": "Independent viewport/atlas core match; 1.5px diagonal raster tolerance. Translucent frame15 excluded. No production offset read.",
            "frames": records}


def main():
    results = []
    sheet = Image.new("RGB", (1280, 392 * 6), "#101c26")
    draw = ImageDraw.Draw(sheet)
    for row, scenario in enumerate(("spawn", "follow", "fixed")):
        for column, phase in enumerate(("before", "after")):
            name = phase + "-" + scenario
            directory = OUT / name
            trace = json.loads((directory / "trace.json").read_text(encoding="utf-8"))["trace"]
            files = sorted((directory / "frames").glob("*.png"))
            raw_frames = [Image.open(path).convert("RGB") for path in files]
            first, last = {"spawn": (5, 125), "follow": (5, 65), "fixed": (5, 95)}[scenario]
            frames = raw_frames[first:last]
            if any(frame.size != (640, 360) for frame in frames):
                raise ValueError("Non-native capture")
            path = OUT / (name + "-loop.png")
            frames[0].save(path, save_all=True, append_images=frames[1:],
                           duration=1000 / 60, loop=0, disposal=0, blend=0)
            exact_speed(path, 60)
            index = 0
            seconds = 0
            with Image.open(path) as animation:
                for i in range(animation.n_frames):
                    animation.seek(i)
                    count = round(animation.info["duration"] * 60 / 1000)
                    for _ in range(count):
                        if animation.convert("RGB").tobytes() != frames[index].tobytes():
                            raise ValueError(f"Lossless frame mismatch: {name}/{index}")
                        index += 1
                    seconds += animation.info["duration"] / 1000
            if index != len(frames) or abs(seconds - len(frames) / 60) > .000001:
                raise ValueError("Loop duration differs from source")
            for state_index, tick in enumerate((13, 70)):
                selected = raw_frames[tick]
                selected.save(OUT / f"{name}-tick-{tick:03}.png")
                x, y = column * 640, (row * 2 + state_index) * 392
                draw.text((x + 12, y + 10), f"{name} / tick {tick} / native 640x360", fill="#e6bc78")
                sheet.paste(selected, (x, y + 32))
            pixels = pixel_probe(directory, trace)
            results.append({"name": name, "source_frames": len(frames), "raw_frames": len(raw_frames),
                            "first_tick": first, "last_tick_exclusive": last,
                            "seconds": seconds, "lossless": True, "pixels": pixels})
            print(f"{name}: {len(frames)} exact 60fps frames, pixel alignment {pixels['aligned']}/{pixels['samples']}")
    sheet.save(OUT / "contact-sheet.png")
    (OUT / "presentation-results.json").write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
