"""Run the same committed rendering fixtures in Godot and embedded Windows EXE.

No extraction or cleanup. Each output directory must be new; actual process
return codes/stdout/stderr and fixed source provenance are preserved.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
DIAGNOSTIC = re.compile(r"^\s*(?:ERROR:|SCRIPT ERROR:|WARNING:)", re.MULTILINE)


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT, encoding="utf-8").rstrip("\r\n")


def state():
    return dict(head=git("rev-parse", "HEAD"),
        status=git("status", "--porcelain=v1", "--untracked-files=all").splitlines(),
        normalized_diff=git("diff", "--name-only").splitlines(),
        staged_diff=git("diff", "--cached", "--name-only").splitlines())


def sha(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for data in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(data)
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--executable", type=Path, required=True)
    parser.add_argument("--project", type=Path,
        help="Godot source project only; omit for embedded Windows executable")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--phase", choices=("source", "windows"), required=True)
    parser.add_argument("--expect-commit", required=True)
    args = parser.parse_args()
    start = state()
    if start["head"] != args.expect_commit or start["status"]:
        raise ValueError("Formal capture requires specified clean committed source")
    output = args.out.resolve()
    if output.drive.upper() != "E:" or output.exists():
        raise ValueError("Output must be new and on E:")
    output.mkdir(parents=True)
    records = []

    def run(name, script, extra=(), fps=60):
        target = output / name
        command = [str(args.executable.resolve())]
        if args.project:
            command += ["--path", str(args.project.resolve())]
        command += ["--rendering-method", "gl_compatibility", "--fixed-fps", str(fps),
                    "--script", "res://tools/" + script, "--", "--out=" + str(target), *extra]
        began = time.monotonic()
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
            encoding="utf-8", errors="replace", timeout=180)
        log = result.stdout + result.stderr
        (output / (name + ".log")).write_text(log, encoding="utf-8")
        diagnostics = [line for line in log.splitlines() if DIAGNOSTIC.match(line)]
        signal = bool(re.search(r"^PASS(?:\s|:)", log, re.MULTILINE))
        passed = result.returncode == 0 and not diagnostics and signal
        records.append(dict(name=name, argv=command, exit=result.returncode,
            diagnostics=diagnostics, pass_signal=signal, passed=passed,
            wall_seconds=round(time.monotonic()-began, 3), fixed_fps=fps,
            physics_hz=120 if fps == 30 else 60,
            pacing="process_frame OS.delay_msec(17)", log_sha256=sha(output / (name + ".log"))))
        print(f"{args.phase}/{name}: exit={result.returncode} diagnostics={len(diagnostics)} passed={passed}", flush=True)
        # A real export incompatibility is retained and reported before further runs.
        return passed

    succeeded = True
    for scenario in ("spawn", "follow", "fixed"):
        succeeded &= run("paired-" + scenario, "capture_issue_31_rc3_pixels.gd",
            ("--full", "--ticks=180", "--scenario=" + scenario))
        succeeded &= run("motion-" + scenario, "capture_issue_31_rc3_motion.gd",
            ("--scenario=" + scenario,))
        if not succeeded:
            break
    if succeeded:
        succeeded &= run("outcomes", "capture_issue_31_rc3_outcomes.gd", fps=30)
        succeeded &= run("integrated", "capture_issue_31_rc3.gd")
    end = state()
    source_unchanged = end["head"] == start["head"] and not end["normalized_diff"] and not end["staged_diff"]
    result = dict(phase=args.phase, source_start=start, source_end=end,
        normalized_source_unchanged=source_unchanged,
        executable=str(args.executable.resolve()), executable_sha256=sha(args.executable),
        expected_checks=8, complete_suite=len(records) == 8,
        strict_pass=succeeded and len(records) == 8 and source_unchanged,
        checks=records, native_size=[640, 360], rendering_method="gl_compatibility",
        disclosure="Paired loops pause only for same-pose on/off measurement; motion loops never hide feedback. Normal Input legal run is separate from teleported/public damage fixtures. Outcomes use 41 public mech hits for initial one-HP setup, a real final projectile collision/turn, and a deterministic public fatal-damage fixture with temporary invulnerability_duration=0; physical R reconstructs normal defaults. Prior default-clock failures and three #35 inconclusive probes remain unchanged.")
    (output / "run-record.json").write_text(json.dumps(result, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    return 0 if result["strict_pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
