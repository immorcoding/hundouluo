"""Small Git delivery: static evidence tracked, loops reproducible + attached to issue."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
NAMES = ("left16", "left24")


def main():
    for sequence in ("entry", "cancel", "boundary", "walk", "jump"):
        pairs = []
        for index in range(150):
            pair = Image.new("RGB", (1280, 392), "#101c26")
            labels = ImageDraw.Draw(pair)
            labels.text((12, 9), "B -16 / x3396 / candidate", fill="#e6bc78")
            labels.text((652, 9), "B -24 / x3388 / RANGE GAP - visual comparison only", fill="#e6bc78")
            for col, name in enumerate(NAMES):
                with Image.open(ROOT / "frames" / name / f"{sequence}-{index:03d}.png") as frame:
                    if frame.size != (640, 360):
                        raise ValueError("Native viewport changed")
                    pair.paste(frame, (col*640, 32))
            pairs.append(pair)
        sample = Image.new("RGB", (1280, 392*6))
        for row, index in enumerate((20, 32, 41, 50, 90, 125)):
            sample.paste(pairs[index], (0, row*392))
        palette = sample.quantize(colors=256)
        scrolling = sequence in ("walk", "jump")
        # Scroll loops at 30fps keep full 256-color readability and small uploads.
        chosen = pairs[::2] if scrolling else pairs
        frames = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in chosen]
        durations = [30, 40, 30]*25 if scrolling else [20, 10, 20]*50
        frames[0].save(ROOT / f"{sequence}-paired.gif", save_all=True,
                       append_images=frames[1:], duration=durations, loop=0,
                       optimize=True, disposal=1)
    sheet = Image.new("RGB", (1280, 1176), "#101c26")
    labels = ImageDraw.Draw(sheet)
    for row, state in enumerate(("open", "warning", "closed")):
        for col, name in enumerate(NAMES):
            x, y = col*640, row*392
            label = "B -16 / x3396 / candidate" if col == 0 else "B -24 / x3388 / RANGE GAP - visual only"
            labels.text((x+12, y+9), label + " / " + state.upper(), fill="#e6bc78")
            with Image.open(ROOT / name / f"entry-{state}.png") as frame:
                sheet.paste(frame, (x, y+32))
    sheet.save(ROOT / "states-paired.png")
    history = Image.new("RGB", (1920, 392), "#101c26")
    labels = ImageDraw.Draw(history)
    for col, (path, label) in enumerate((
        (ROOT.parent / "ab/B/entry-closed.png", "B baseline / x3412"),
        (ROOT / "left16/entry-closed.png", "B -16 / x3396"),
        (ROOT / "left24/entry-closed.png", "B -24 / x3388 / NOT safe for direct integration"),
    )):
        labels.text((col*640+12, 9), label, fill="#e6bc78")
        with Image.open(path) as frame:
            history.paste(frame, (col*640, 32))
    history.save(ROOT / "history-paired.png")
    # Auxiliary integer-scale edge inspection, never a substitute for native QA.
    with Image.open(ROOT / "left16/closed.png") as art:
        art.resize((384, 864), Image.Resampling.NEAREST).save(ROOT / "edge-3x.png")
    print("Native stills and 5x 2.5s loops ready; GIFs intentionally stay out of Git")


if __name__ == "__main__":
    main()
