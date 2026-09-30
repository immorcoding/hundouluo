"""Present native Godot frames; GIF palettes affect previews, never runtime art."""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "docs/art/issue-33"


def native(path):
    with Image.open(path) as image:
        if image.size != (640, 360):
            raise ValueError(f"Non-native capture: {path}")
        return image.convert("RGB")


def main():
    for sequence in ("entry", "cancel", "boundary", "walk", "jump", "advance"):
        files = sorted((ROOT / "frames").glob(f"{sequence}-*.png"))[::2]
        frames = [native(path) for path in files]
        sample = Image.new("RGB", (640, 360 * 6))
        for row in range(6):
            sample.paste(frames[min(len(frames) - 1, row * (len(frames) // 6))], (0, row * 360))
        palette = sample.quantize(colors=256)
        previews = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
        # 30fps with centisecond durations; each 3 frames retains 100ms.
        durations = [30, 40, 30] * (len(previews) // 3)
        previews[0].save(ROOT / f"{sequence}.gif", save_all=True,
                         append_images=previews[1:], duration=durations, loop=0,
                         optimize=True, disposal=1)
        with Image.open(ROOT / f"{sequence}.gif") as preview:
            duration = sum((preview.seek(i), preview.info["duration"])[1]
                           for i in range(preview.n_frames))
        if duration != len(files) * 1000 // 30:
            raise ValueError(f"Preview time changed: {sequence} {duration}")
        print(f"{sequence}: 640x360 / {duration}ms / {(ROOT / f'{sequence}.gif').stat().st_size} bytes")

    sheet = Image.new("RGB", (1280, 392 * 3), "#101c26")
    labels = ImageDraw.Draw(sheet)
    for row, state in enumerate(("open", "warning", "closed")):
        for col, suffix in enumerate(("-approved", "")):
            labels.text((col * 640 + 12, row * 392 + 10),
                        f"{'Approved #32 B-left16' if col == 0 else 'Production #33'} / {state}",
                        fill="#e6bc78")
            sheet.paste(native(ROOT / f"entry-{state}{suffix}.png"), (col * 640, row * 392 + 32))
    sheet.save(ROOT / "approved-comparison.png")
    with Image.open(ROOT / "entry-closed.png") as image:
        image.crop((48, 76, 228, 284)).resize((540, 624), Image.Resampling.NEAREST).save(ROOT / "gate-edge-3x.png")


if __name__ == "__main__":
    main()
