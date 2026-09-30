"""Native lossless evidence and exact-speed original-scene APNG verification."""
import json
from pathlib import Path
from PIL import Image, ImageDraw
from present_issue_35 import exact_speed

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/bugs/issue-36"


def main():
    records = []
    for phase in ("before", "after"):
        for scenario in ("spawn", "follow", "fixed"):
            name = phase + "-original-" + scenario
            files = sorted((OUT / name / "frames").glob("*.png"))
            frames = [Image.open(p).convert("RGB") for p in files]
            if len(frames) != 180 or any(f.size != (640, 360) for f in frames):
                raise ValueError("Expected 180 native original-loop frames")
            path = OUT / (name + "-loop.png")
            frames[0].save(path, save_all=True, append_images=frames[1:], duration=1000/60,
                           loop=0, disposal=0, blend=0)
            exact_speed(path, 60)
            index = 0
            seconds = 0
            with Image.open(path) as animation:
                for i in range(animation.n_frames):
                    animation.seek(i)
                    count = round(animation.info["duration"]*60/1000)
                    for _ in range(count):
                        if animation.convert("RGB").tobytes() != frames[index].tobytes():
                            raise ValueError("APNG source-frame pixel mismatch")
                        index += 1
                    seconds += animation.info["duration"]/1000
            if index != 180 or abs(seconds-3) > .000001:
                raise ValueError("APNG does not preserve exact original 60fps timing")
            frames[13].save(OUT / (name + "-tick-013.png"))
            trace = json.loads((OUT / (phase + "-paired-" + scenario) / "trace.json").read_text())
            samples = [r for r in trace if r.get("flash_count", 0)]
            records.append(dict(name=name, native_size=[640, 360], raw_frames=180,
                seconds=seconds, lossless=True, paired_samples=len(samples),
                flash_samples=sum(r["flash_count"] for r in samples),
                max_changed_gun_pixels=max(r["changed_gun_pixels"] for r in samples),
                max_rear_error_px=max(abs(r["visible_rear_error_px"]) for r in samples)))
    sheet = Image.new("RGB", (1280, 760), "#101c26")
    draw = ImageDraw.Draw(sheet)
    for column, phase in enumerate(("before", "after")):
        for row, state in enumerate(("on", "off")):
            source = OUT / (phase + "-minimal") / "frames" / ("000-" + state + ".png")
            native = Image.open(source).convert("RGB")
            native.save(OUT / (phase + "-native-" + state + ".png"))
            sheet.paste(native, (column*640, row*380+20))
            draw.text((column*640+10, row*380+4), phase + " / own feedback " + state,
                      fill="#e6bc78")
    sheet.save(OUT / "native-paired-comparison.png")
    (OUT / "presentation-results.json").write_text(json.dumps(records, indent=2)+"\n")
    print(json.dumps(records, indent=2))


if __name__ == "__main__":
    main()
