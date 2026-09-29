"""Native-size paired #32 A/B evidence; both views share one frozen game instant."""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
SEQUENCES = ("entry", "cancel", "boundary", "passage-walk", "passage-jump")


def gif(frames, path):
    sample = Image.new("RGB", (frames[0].width, frames[0].height * 6))
    for row, index in enumerate((20, 32, 41, 50, 90, 110)):
        sample.paste(frames[index], (0, row * frames[0].height))
    palette = sample.quantize(colors=256)
    indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
    indexed[0].save(path, save_all=True, append_images=indexed[1:],
                    duration=[20, 10, 20] * 50, loop=0, optimize=True, disposal=1)


def main():
    for sequence in SEQUENCES:
        sets = []
        for variant in ("A", "B"):
            paths = sorted((ROOT / "capture-frames" / variant).glob(sequence + "-*.png"))
            if len(paths) != 150:
                raise ValueError(f"Expected 150 frames: {variant}/{sequence}")
            frames = [Image.open(path).convert("RGB") for path in paths]
            if any(frame.size != (640, 360) for frame in frames):
                raise ValueError("Viewports must remain native 640x360")
            gif(frames, ROOT / variant / (sequence + "-loop.gif"))
            sets.append(frames)
        paired = []
        for a, b in zip(*sets):
            pair = Image.new("RGB", (1280, 392), "#101c26")
            draw = ImageDraw.Draw(pair)
            draw.text((12, 9), "A / PILLAR   x=3412   shoe y=263", fill="#e6bc78")
            draw.text((652, 9), "B / WALL PASSAGE   x=3412   shoe y=263", fill="#e6bc78")
            pair.paste(a, (0, 32))
            pair.paste(b, (640, 32))
            paired.append(pair)
        gif(paired, ROOT / (sequence + "-paired.gif"))
        for frames in sets:
            for frame in frames:
                frame.close()
    sheet = Image.new("RGB", (1280, 1176), "#101c26")
    draw = ImageDraw.Draw(sheet)
    for row, state in enumerate(("open", "warning", "closed")):
        for column, variant in enumerate(("A", "B")):
            x, y = column * 640, row * 392
            draw.text((x+12, y+9), variant + " / " + state.upper(), fill="#e6bc78")
            with Image.open(ROOT / variant / ("entry-" + state + ".png")) as frame:
                sheet.paste(frame, (x, y+32))
    sheet.save(ROOT / "states-paired.png")
    # Previous pass and candidate use the same near-boundary camera x=3580.
    history = Image.new("RGB", (1920, 392), "#101c26")
    draw = ImageDraw.Draw(history)
    for col, (file, label) in enumerate((
        (ROOT.parent / "boundary-closed.png", "PREVIOUS / x=3444 / bottom y=251"),
        (ROOT / "A/entry-closed.png", "A / x=3412 / bottom y=263"),
        (ROOT / "B/entry-closed.png", "B / x=3412 / bottom y=263"),
    )):
        draw.text((col*640+12, 9), label, fill="#e6bc78")
        with Image.open(file) as frame:
            history.paste(frame, (col*640, 32))
    history.save(ROOT / "history-paired.png")
    print("Packaged five native A/B sequences, 2500ms each, and comparison sheets")


if __name__ == "__main__":
    main()
