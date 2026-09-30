"""Strict complete suite with a deterministic test clock and real audio time.

Original test scripts/assertions stay unchanged. Inherited wrappers only pace
process_frame: fixed-fps controls simulation while OS.delay_msec gives the
audio thread wall time (fixed-fps disables CLI real-time synchronization).
"""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

from check_issue_31 import DIAGNOSTIC

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--temp", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    args.temp.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(TEMP=str(args.temp.resolve()), TMP=str(args.temp.resolve()))
    env["PATH"] = str(Path(args.godot).parent) + os.pathsep + env["PATH"]
    records = []

    def run(name, command, require_pass=False):
        result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True,
                                text=True, encoding="utf-8", errors="replace", timeout=600)
        log = result.stdout + result.stderr
        (args.output / (name + ".log")).write_text(log, encoding="utf-8")
        diagnostics = [line for line in log.splitlines() if DIAGNOSTIC.match(line)]
        messages = [line for line in log.splitlines() if line.startswith("PASS:")]
        records.append({"name": name, "exit": result.returncode, "diagnostics": diagnostics,
                        "pass_messages": messages, "log": name + ".log", "command": command,
                        "pass": result.returncode == 0 and not diagnostics and
                        (bool(messages) or not require_pass)})
        print(f"{name}: exit={result.returncode}, diagnostics={len(diagnostics)}", flush=True)

    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    run("python", [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"])
    run("import", [args.godot, "--headless", "--editor", "--path", str(ROOT), "--import", "--quit"])
    wrapper_dir = ROOT / ".godot/issue-35-paced-tests"
    wrapper_dir.mkdir(parents=True, exist_ok=True)
    for script in sorted((ROOT / "tests").glob("*.gd")):
        source = script.read_text(encoding="utf-8")
        if not re.search(r'^extends (?:SceneTree|"res://tools/capture_issue_35\.gd")\s*$', source, re.MULTILINE):
            continue
        relative = "tests/" + script.name
        wrapper = wrapper_dir / script.name
        wrapper.write_text('extends "res://' + relative + '"\n\n'
                           'func _initialize() -> void:\n'
                           '\tprocess_frame.connect(func() -> void: OS.delay_msec(17))\n'
                           '\tsuper._initialize()\n', encoding="utf-8")
        fps = "30" if script.stem == "operative_muzzle_victory" else "60"
        run(script.stem, [args.godot, "--headless", "--path", str(ROOT), "--fixed-fps", fps,
                         "--script", "res://.godot/issue-35-paced-tests/" + script.name], require_pass=True)
    run("main-headless", [args.godot, "--headless", "--path", str(ROOT), "--quit-after", "90"])
    run("main-graphical", [args.godot, "--path", str(ROOT), "--rendering-method",
                           "gl_compatibility", "--quit-after", "90"])
    passed = all(record["pass"] for record in records)
    (args.output / "results.json").write_text(json.dumps({
        "tested_commit": commit, "strict_pass": passed, "checks": records,
        "note": "All original assertions run unchanged. Inherited wrappers pace 17ms wall time per process frame; deterministic fixed-fps60 (victory30/physics120) drives simulation. Diagnostics and exits are both gates. Original unpaced failures are preserved separately."
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
