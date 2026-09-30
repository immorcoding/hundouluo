"""Assemble native-resolution captures into original-speed APNG evidence."""
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CAPTURE_DIR = ROOT / "docs" / "art" / "issue-34" / "after" / "soldier-standing"
RAW_DIR = ROOT / ".godot" / "issue-34-frames"
OUTPUTS = {
    "move_right": CAPTURE_DIR / "walk-right-loop.png",
    "move_left": CAPTURE_DIR / "walk-left-loop.png",
}


def main() -> int:
    report_path = CAPTURE_DIR / "pixel-comparison.json"
    report = json.loads(report_path.read_text(encoding="utf-8"))
    captures = {
        case["input_action"]: int(case["motion_frame_count"])
        for case in report["cases"]
        if case.get("actor_state") == "running"
    }
    results = {"native_size": [640, 360], "fps": 60, "loops": []}
    for action, output_path in OUTPUTS.items():
        frame_count = captures.get(action, 0)
        if frame_count < 2:
            raise SystemExit(f"missing motion frames for {action}")
        paths = [RAW_DIR / action / f"frame-{frame:03d}.png" for frame in range(frame_count)]
        if any(not path.is_file() for path in paths):
            raise SystemExit(f"incomplete raw capture for {action}")
        images = [Image.open(path).convert("RGBA") for path in paths]
        if any(image.size != (640, 360) for image in images):
            raise SystemExit(f"non-native image in {action} capture")
        images[0].save(
            output_path,
            format="PNG",
            save_all=True,
            append_images=images[1:],
            duration=17,
            loop=0,
            disposal=2,
            blend=0,
            optimize=False,
        )
        results["loops"].append({
            "action": action,
            "file": output_path.name,
            "frames": frame_count,
            "frame_duration_ms": 17,
            "resolution": [640, 360],
        })
        print(f"PASS: {action} {frame_count} native frames -> {output_path.relative_to(ROOT)}")
    (CAPTURE_DIR / "motion-results.json").write_text(
        json.dumps(results, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
