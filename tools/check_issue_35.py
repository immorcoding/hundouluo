"""Strict subprocess records for #35's original/minimal loops and frame matrix."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
DIAGNOSTIC = re.compile(r"^\s*(?:ERROR:|SCRIPT ERROR:|WARNING:)", re.MULTILINE)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--baseline", type=Path)
    args = parser.parse_args()
    output = ROOT / "docs/bugs/issue-35"
    records = []

    def run(name, project, extra, expect=0, graphical=True):
        command = [args.godot, "--path", str(project)]
        if graphical:
            command += ["--rendering-method", "gl_compatibility"]
        else:
            command += ["--headless"]
        command += extra
        start = time.monotonic()
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                                encoding="utf-8", errors="replace", timeout=120)
        log = result.stdout + result.stderr
        (output / (name + ".log")).write_text(log, encoding="utf-8")
        diagnostics = [line for line in log.splitlines() if DIAGNOSTIC.match(line)]
        passed = result.returncode == expect and not diagnostics and "ISSUE35 shots=" in log
        records.append({"name": name, "command": command, "exit": result.returncode,
                        "expected_exit": expect, "diagnostics": diagnostics,
                        "seconds": round(time.monotonic() - start, 3), "pass": passed})
        print(f"{name}: exit={result.returncode}, expected={expect}, diagnostics={len(diagnostics)}", flush=True)

    script = ["--script", "tools/capture_issue_35.gd"]
    if args.baseline:
        for scenario in ("spawn", "follow", "fixed"):
            run("before-" + scenario, args.baseline, ["--fixed-fps", "60"] + script +
                ["--", "--scenario=" + scenario,
                 "--out=" + str(output / ("before-" + scenario))], expect=1)
        for mode, ticks, expect in (("minimal", 2, 1), ("minimal", 2, 1),
                                    ("stationary", 2, 0), ("no-shot", 2, 0),
                                    ("minimal", 1, 0)):
            name = f"minimize-{len(records)}-{mode}-{ticks}"
            run(name, args.baseline, ["--fixed-fps", "60"] + script +
                ["--", "--mode=" + mode, "--ticks=" + str(ticks),
                 "--out=" + str(output / "diagnosis" / name)], expect=expect)
        for probe, expect in (("freeze-projectile", 1), ("follow-body", 0)):
            run("probe-" + probe, args.baseline, ["--fixed-fps", "60"] + script +
                ["--", "--mode=minimal", "--ticks=2", "--probe=" + probe,
                 "--out=" + str(output / "diagnosis" / probe)], expect=expect)
    for scenario in ("spawn", "follow", "fixed"):
        run("after-" + scenario, ROOT, ["--fixed-fps", "60"] + script +
            ["--", "--scenario=" + scenario, "--out=" + str(output / ("after-" + scenario))])
    for hz in (30, 60, 120):
        for fps in (30, 60, 120):
            name = f"timing-{hz}hz-{fps}fps"
            # Headless loop retains physics and process callbacks; separate
            # graphical matrix samples below validate actual presentation.
            run(name, ROOT, ["--fixed-fps", str(fps)] + script + ["--",
                "--physics-hz=" + str(hz), "--ticks=240", "--out=" + str(output / name)], graphical=False)
    for hz, fps in ((30, 60), (60, 30), (60, 120), (120, 60), (120, 120)):
        name = f"render-{hz}hz-{fps}fps"
        run(name, ROOT, ["--fixed-fps", str(fps)] + script + ["--", "--physics-hz=" + str(hz),
            "--ticks=240", "--out=" + str(output / name)])
    passed = all(record["pass"] for record in records)
    (output / "loop-results.json").write_text(json.dumps({"strict_pass": passed, "checks": records},
        ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
