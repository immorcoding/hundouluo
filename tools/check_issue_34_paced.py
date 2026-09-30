"""Run the complete project suite with #35's wall-clock pacing wrapper."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
DIAGNOSTIC = re.compile(r"^\s*(?:ERROR:|SCRIPT ERROR:|WARNING:)", re.MULTILINE)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--temp", type=Path, required=True)
    args = parser.parse_args()
    status = subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT,
                                    text=True).strip()
    if status:
        print("Refusing to record a commit as tested while the worktree has uncommitted changes.",
              file=sys.stderr)
        return 2
    args.output.mkdir(parents=True, exist_ok=True)
    args.temp.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(TEMP=str(args.temp.resolve()), TMP=str(args.temp.resolve()))
    env["PATH"] = str(Path(args.godot).parent) + os.pathsep + env["PATH"]
    records = []

    def run(name, command):
        result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True,
                                 text=True, encoding="utf-8", errors="replace", timeout=600)
        log = result.stdout + result.stderr
        (args.output / (name + ".log")).write_text(log, encoding="utf-8")
        diagnostics = [line for line in log.splitlines() if DIAGNOSTIC.match(line)]
        passed = result.returncode == 0 and not diagnostics
        records.append({"name": name, "exit": result.returncode, "diagnostics": diagnostics,
                        "log": name + ".log", "command": command, "pass": passed})
        print(f"{name}: exit={result.returncode}, diagnostics={len(diagnostics)}, pass={passed}",
              flush=True)

    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT,
                                     text=True).strip()
    run("python", [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"])
    run("import", [args.godot, "--headless", "--editor", "--path", str(ROOT),
                    "--import", "--quit"])
    wrapper_dir = ROOT / ".godot/issue-34-paced-tests"
    wrapper_dir.mkdir(parents=True, exist_ok=True)
    for script in sorted((ROOT / "tests").glob("*.gd")):
        if not re.search(r"^extends SceneTree\s*$",
                         script.read_text(encoding="utf-8"), re.MULTILINE):
            continue
        relative = "tests/" + script.name
        wrapper = wrapper_dir / script.name
        wrapper.write_text(
            'extends "res://' + relative + '"\n\n'
            "func _initialize() -> void:\n"
            "\tprocess_frame.connect(func() -> void: OS.delay_msec(17))\n"
            "\tsuper._initialize()\n",
            encoding="utf-8",
        )
        run(script.stem, [args.godot, "--headless", "--path", str(ROOT), "--fixed-fps", "60",
                          "--script", "res://.godot/issue-34-paced-tests/" + script.name])
    run("main-headless", [args.godot, "--headless", "--path", str(ROOT), "--quit-after", "90"])
    run("main-graphical", [args.godot, "--path", str(ROOT), "--rendering-method",
                            "gl_compatibility", "--quit-after", "90"])
    passed = all(record["pass"] for record in records)
    (args.output / "results.json").write_text(json.dumps({
        "tested_commit": commit,
        "strict_pass": passed,
        "checks": records,
        "note": "Original test scripts and assertions run unchanged. Each inherited wrapper waits 17ms on process_frame; --fixed-fps 60 advances the simulation at 60Hz while giving each frame real wall-clock time. Exit codes and ERROR/SCRIPT ERROR/WARNING diagnostics are both gates.",
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
