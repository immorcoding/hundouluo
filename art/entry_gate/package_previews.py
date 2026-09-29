"""Package unscaled Godot captures into native-size, real-speed review loops."""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent


def main():
    for prefix in ("scene", "boundary", "retreat"):
        paths = sorted((ROOT / "capture-frames").glob(f"{prefix}-*.png"))
        if len(paths) != 132:
            raise ValueError(f"Expected 132 actual 640x360 Godot frames for {prefix}")
        frames = [Image.open(path).convert("RGB") for path in paths]
        if any(frame.size != (640, 360) for frame in frames):
            raise ValueError("Review frames must be native 640x360")
        # GIF's clock has 10ms resolution: 20/10/20ms = 3 frames per 50ms.
        durations = [20, 10, 20] * 44
        palette_sheet = Image.new("RGB", (640, 360 * 8))
        for row, index in enumerate((0, 32, 43, 46, 65, 80, 95, 120)):
            palette_sheet.paste(frames[index], (0, row * 360))
        palette = palette_sheet.quantize(colors=256)
        gif_frames = [frame.quantize(palette=palette, dither=Image.Dither.NONE)
                      for frame in frames]
        gif_frames[0].save(ROOT / f"{prefix}-loop.gif", save_all=True,
                           append_images=gif_frames[1:], duration=durations, loop=0,
                           optimize=True, disposal=1)
        # Lossless full-color companion, with millisecond clock quantization.
        frames[0].save(ROOT / f"{prefix}-loop.png", save_all=True,
                       append_images=frames[1:], duration=[17, 16, 17] * 44, loop=0)
        for frame in frames:
            frame.close()
    # Contact sheet only: each viewport copied 1:1 with labels outside it.
    names = [("baseline-closed", "MAIN #28 / same pose"), ("scene-closed", "#32 / CLOSED"),
             ("scene-open", "#32 / OPEN"), ("scene-warning", "#32 / WARNING"),
             ("boundary-combat", "#32 / LEFT LIMIT"), ("scene-combat", "#32 / PROJECTILES")]
    sheet = Image.new("RGB", (1280, 1176), "#101c26")
    draw = ImageDraw.Draw(sheet)
    for index, (name, label) in enumerate(names):
        x, y = (index % 2) * 640, (index // 2) * 392
        draw.text((x + 12, y + 9), label, fill="#e6bc78")
        with Image.open(ROOT / f"{name}.png") as frame:
            sheet.paste(frame, (x, y + 32))
    sheet.save(ROOT / "review-sheet.png")
    comparison = Image.new("RGB", (1280, 784), "#101c26")
    labels = ImageDraw.Draw(comparison)
    for row, state in enumerate(("closed", "open")):
        for column, folder in enumerate((ROOT / "first-pass", ROOT)):
            x, y = column * 640, row * 392
            label = "FIRST PASS / " if column == 0 else "ENVIRONMENT REVISION / "
            labels.text((x + 12, y + 9), label + state.upper(), fill="#e6bc78")
            with Image.open(folder / f"scene-{state}.png") as frame:
                comparison.paste(frame, (x, y + 32))
    comparison.save(ROOT / "first-pass-comparison.png")
    print("Packaged three 2.2s loops (GIF + lossless APNG) and 1:1 review sheet")


if __name__ == "__main__":
    main()
