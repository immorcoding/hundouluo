"""Record the final committed snapshot's complete checks, including diagnostics."""
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
    parser.add_argument("--temp", type=Path, required=True,
                        help="E-drive scratch outside this snapshot, for the package test")
    args = parser.parse_args()
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
        diagnostics = DIAGNOSTIC.findall(log)
        record = {"name": name, "exit": result.returncode,
                  "diagnostics": [line for line in log.splitlines() if DIAGNOSTIC.match(line)],
                  "pass_messages": [line for line in log.splitlines() if line.startswith("PASS:")],
                  "log": name + ".log", "command": command}
        records.append(record)
        print(f"{name}: exit={result.returncode}, diagnostics={len(diagnostics)}", flush=True)

    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    run("import", [args.godot, "--headless", "--editor", "--path", str(ROOT), "--import"])
    for script in sorted((ROOT / "tests").glob("*.gd")):
        if re.search(r"^extends SceneTree\s*$", script.read_text(encoding="utf-8"), re.MULTILINE):
            run(script.stem, [args.godot, "--headless", "--path", str(ROOT), "--script",
                              "tests/" + script.name])
    run("main-headless", [args.godot, "--headless", "--path", str(ROOT), "--quit-after", "90"])
    run("main-graphical", [args.godot, "--path", str(ROOT), "--rendering-method",
                           "gl_compatibility", "--quit-after", "90"])
    run("python", [sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v"])
    passed = all(r["exit"] == 0 and not r["diagnostics"] for r in records)
    (args.output / "results.json").write_text(json.dumps({
        "tested_commit": commit, "strict_pass": passed, "checks": records,
        "note": "Logs and exit codes are both gates; not human visual/audio/play acceptance."
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
