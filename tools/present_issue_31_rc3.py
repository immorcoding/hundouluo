"""Native lossless APNGs and rendered corpse/gun/seam measurements, per target."""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

from present_issue_35 import exact_speed


def image(path):
    result = Image.open(path).convert("RGB")
    if result.size != (640, 360):
        raise ValueError("Non-native frame: " + str(path))
    return result


def animation(paths, destination, fps, count=None):
    frames = [image(path) for path in paths]
    if not frames or (count is not None and len(frames) != count):
        raise ValueError("Unexpected raw frame count: " + str(destination))
    frames[0].save(destination, save_all=True, append_images=frames[1:],
        duration=1000/fps, loop=0, disposal=0, blend=0)
    exact_speed(destination, fps)
    index, seconds = 0, 0
    with Image.open(destination) as saved:
        for tick in range(saved.n_frames):
            saved.seek(tick)
            repeat = round(saved.info["duration"] * fps / 1000)
            for _ in range(repeat):
                if index >= len(frames) or saved.convert("RGB").tobytes() != frames[index].tobytes():
                    raise ValueError("APNG/source pixel mismatch")
                index += 1
            seconds += saved.info["duration"]/1000
    if index != len(frames) or abs(seconds-len(frames)/fps) > .000001:
        raise ValueError("APNG source cadence mismatch")
    return dict(file=destination.name, frames=len(frames), fps=fps,
        seconds=seconds, native_size=[640, 360], lossless=True,
        sampling="Every physics frame" if fps == 60 else "Every 12 physics frames at 5fps; not a 60fps recording")


def layer(directory, name):
    background, corpse, actor, combined = [np.asarray(image(directory / (name+"-"+key+".png")))
        for key in ("background", "corpse-only", "actor-only", "combined")]
    actor_visible = np.any(actor != background, axis=2)
    corpse_visible = np.any(corpse != background, axis=2)
    overlap = actor_visible & corpse_visible & np.any(actor != corpse, axis=2)
    front = overlap & np.all(combined == actor, axis=2)
    count = int(overlap.sum())
    result = dict(name=name, overlap_pixels=count, operative_front_pixels=int(front.sum()),
        corpse_visible_pixels=int(corpse_visible.sum()), foreground_ratio=float(front.sum()/max(count, 1)))
    if count < 8 or result["foreground_ratio"] < .95 or corpse_visible.sum() < 100:
        raise ValueError("Corpse foreground pixel check failed: " + repr(result))
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    raw, output = args.input.resolve(), args.out.resolve()
    if output.drive.upper() != "E:" or output.exists():
        raise ValueError("Presentation output must be new and on E:")
    run = json.loads((raw / "run-record.json").read_text(encoding="utf-8"))
    if not run["strict_pass"]:
        raise ValueError("Cannot present failed capture as a success")
    output.mkdir(parents=True)
    animations, pairs, flights = [], [], []
    for scenario in ("spawn", "follow", "fixed"):
        motion = raw / ("motion-"+scenario)
        frames = sorted((motion / "frames").glob("*.png"))
        animations.append(animation(frames, output / ("motion-"+scenario+"-loop.png"), 60, 180))
        image(frames[13]).save(output / ("motion-"+scenario+"-013.png"))
        paired = raw / ("paired-"+scenario)
        trace = json.loads((paired / "trace.json").read_text(encoding="utf-8"))
        samples = [r for r in trace if r.get("flash_count", 0)]
        if len(trace) != 180 or not samples:
            raise ValueError("Missing paired visible flash samples")
        result = dict(scenario=scenario, paired_frames=len(trace), paired_samples=len(samples),
            flash_samples=sum(r["flash_count"] for r in samples),
            max_changed_gun_pixels=max(r["changed_gun_pixels"] for r in samples),
            max_visible_rear_error_px=max(abs(r["visible_rear_error_px"]) for r in samples),
            max_mask_pixels=max(r["mask_pixels"] for r in samples),
            camera_min=min(r["camera_x"] for r in trace), camera_max=max(r["camera_x"] for r in trace),
            poses=sorted({str(r["pose"])+":"+str(r["flip"]) for r in trace}))
        if result["max_changed_gun_pixels"] != 0 or result["max_visible_rear_error_px"] > 1:
            raise ValueError("Gun/seam pixels failed: " + repr(result))
        if scenario == "fixed" and (result["camera_min"] != 3580 or result["camera_max"] != 3580):
            raise ValueError("Fixed camera changed")
        if scenario == "follow" and result["camera_min"] == result["camera_max"]:
            raise ValueError("Follow camera did not move")
        pairs.append(result)
        for state in ("on", "off"):
            image(paired / "frames" / ("013-"+state+".png")).save(output / ("paired-"+scenario+"-013-"+state+".png"))
        (output / ("paired-"+scenario+"-trace.json")).write_text(json.dumps(trace, indent=2)+"\n")
        motion_trace = json.loads((motion / "trace.json").read_text(encoding="utf-8"))
        if motion_trace["failures"]:
            raise ValueError("Motion fixture failed")
        shots = motion_trace["shots"]
        flight = [p for r in motion_trace["trace"] for p in r["projectiles"]]
        flights.append(dict(scenario=scenario, shots=len(shots),
            flash_samples=motion_trace["flash_samples"], flight_samples=len(flight),
            max_birth_error=max(s["birth_error"] for s in shots),
            max_flight_error=max(p["flight_error"] for p in flight)))
        (output / ("motion-"+scenario+"-trace.json")).write_text(json.dumps(motion_trace, indent=2)+"\n")
    integrated = raw / "integrated"
    capture = json.loads((integrated / "capture-results.json").read_text(encoding="utf-8"))
    if capture["failures"]:
        raise ValueError("Integrated fixture failed")
    layers = [layer(integrated, name) for name in
        ("soldier-standing", "soldier-moving-right", "soldier-moving-left", "mech-victory")]
    legal_paths = sorted((integrated / "frames/legal-run").glob("*.png"))
    legal_samples = [r for r in capture["frame_samples"] if r["sequence"] == "legal-run"]
    if len(legal_samples) != len(legal_paths) or len(legal_samples) < 2 \
        or capture["physics_hz"] != 60:
        raise ValueError("Missing actual legal-run physics sampling provenance")
    for sample, path in zip(legal_samples, legal_paths):
        if path.stem != f'{sample["tick"]:04}':
            raise ValueError("Legal-run sample/file identity mismatch")
    cadence = [b["physics_frame"]-a["physics_frame"] for a, b in zip(legal_samples, legal_samples[1:])]
    if any(delta != 12 for delta in cadence):
        raise ValueError("Legal-run actual physics cadence differs from 12 ticks")
    animations.append(animation(legal_paths, output / "legal-run-loop.png", 5))
    animations[-1]["actual_physics_frame_delta_min"] = min(cadence)
    animations[-1]["actual_physics_frame_delta_max"] = max(cadence)
    for path in integrated.glob("*.png"):
        image(path).save(output / path.name)
    (output / "capture-results.json").write_text(json.dumps(capture, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    outcomes = json.loads((raw / "outcomes/trace.json").read_text(encoding="utf-8"))
    if len(outcomes) != 5 or outcomes[3]["flash_count"] != 0:
        raise ValueError("Incomplete victory/death/R evidence")
    for index, name in enumerate(("victory-winning-shot", "victory-frozen", "victory-retry", "death", "death-retry")):
        for state in ("on", "off"):
            image(raw / "outcomes/frames" / (f"{index:03}-"+state+".png")).save(output / (name+"-"+state+".png"))
    result = dict(phase=run["phase"], source_commit=run["source_start"]["head"],
        executable_sha256=run["executable_sha256"], animations=animations,
        independent_gun_seam_pairs=pairs, independent_flights=flights,
        corpse_pixel_checks=layers, outcomes=outcomes,
        disclosure=capture["disclosure"],
        paired_motion_disclosure="Paired hurt directions now follow the first real nonfatal health_changed event with ordinary Input right two steps/left two steps then restore planned direction. Existing life, invulnerability and assertions remain. Tick125 public receive_hit can be rejected and does not guarantee damage. Original #35 unpaused motion and legal Input full-run are unchanged.",
        prior_probe_status="Three old #35 low-confidence atlas probes remain inconclusive; #36 paired visible gun/seam checks measure a different explicitly observed symptom.")
    (output / "presentation-results.json").write_text(json.dumps(result, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
