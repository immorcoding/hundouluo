"""Strict graphical red/green captures, original loop, and default-effect comparison."""
import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/bugs/issue-36"
DIAGNOSTIC = re.compile(r"^\s*(?:ERROR:|SCRIPT ERROR:|WARNING:)", re.MULTILINE)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--baseline", type=Path, required=True)
    args = parser.parse_args()
    baseline = args.baseline.resolve()
    # Only test fixtures are added to the untouched eec9adf runtime archive.
    for name in ("capture_issue_36.gd", "capture_issue_36_compatibility.gd"):
        shutil.copyfile(ROOT / "tools" / name, baseline / "tools" / name)
    records = []

    def run(name, project, script, extra=(), expected=0, fps=60):
        command = [args.godot, "--path", str(project), "--rendering-method", "gl_compatibility",
                   "--fixed-fps", str(fps), "--script", "res://tools/" + script,
                   "--", "--out=" + str(OUT / name), *extra]
        start = time.monotonic()
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                                encoding="utf-8", errors="replace", timeout=90)
        log = result.stdout + result.stderr
        (OUT / (name + ".log")).write_text(log, encoding="utf-8")
        diagnostics = [line for line in log.splitlines() if DIAGNOSTIC.match(line)]
        signal = "FAIL:" in log if expected else bool(re.search(r"^PASS(?:\s|:)", log, re.MULTILINE))
        passed = result.returncode == expected and not diagnostics and signal
        records.append(dict(name=name, command=command, exit=result.returncode,
                            expected_exit=expected, diagnostics=diagnostics, pass_signal=signal,
                            seconds=round(time.monotonic()-start, 3), passed=passed))
        print(f"{name}: exit={result.returncode}, expected={expected}, diagnostics={len(diagnostics)}, pass={passed}", flush=True)

    for phase, project, expected in (("before", baseline, 1), ("after", ROOT, 0)):
        run(phase + "-minimal", project, "capture_issue_36.gd", ["--ticks=12"], expected)
        for scenario in ("spawn", "follow", "fixed"):
            run(phase + "-paired-" + scenario, project, "capture_issue_36.gd",
                ["--full", "--ticks=180", "--scenario=" + scenario], expected)
            run(phase + "-original-" + scenario, project, "capture_issue_35.gd",
                ["--scenario=" + scenario])
        run(phase + "-standalone", project, "capture_issue_36_compatibility.gd")
    run("after-outcomes", ROOT, "capture_issue_36_outcomes.gd", fps=30)
    equal = all((OUT / "before-standalone/frames" / f"{i:03}.png").read_bytes() ==
                (OUT / "after-standalone/frames" / f"{i:03}.png").read_bytes() for i in range(16))
    records.append(dict(name="standalone-friendly-enemy-pixel-identity", passed=equal, frames=16))
    passed = all(record["passed"] for record in records)
    (OUT / "loop-results.json").write_text(json.dumps(dict(strict_pass=passed, checks=records),
        ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
