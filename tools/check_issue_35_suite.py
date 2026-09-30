"""Complete existing strict suite plus #35's inherited SceneTree regression."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

import check_issue_31

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--temp", type=Path, required=True)
    args = parser.parse_args()
    original = sys.argv
    sys.argv = [original[0], "--godot", args.godot, "--output", str(args.output), "--temp", str(args.temp)]
    try:
        existing_exit = check_issue_31.main()
    finally:
        sys.argv = original
    command = [args.godot, "--headless", "--path", str(ROOT), "--fixed-fps", "60",
               "--script", "tests/operative_running_muzzle.gd"]
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                            encoding="utf-8", errors="replace", timeout=120)
    log = result.stdout + result.stderr
    (args.output / "operative_running_muzzle.log").write_text(log, encoding="utf-8")
    diagnostics = [line for line in log.splitlines() if check_issue_31.DIAGNOSTIC.match(line)]
    path = args.output / "results.json"
    records = json.loads(path.read_text(encoding="utf-8"))
    records["checks"].append({"name": "operative_running_muzzle", "exit": result.returncode,
        "diagnostics": diagnostics, "pass_messages": [line for line in log.splitlines() if line.startswith("PASS:")],
        "log": "operative_running_muzzle.log", "command": command})
    records["strict_pass"] = existing_exit == 0 and result.returncode == 0 and not diagnostics and "PASS:" in log
    path.write_text(json.dumps(records, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"operative_running_muzzle: exit={result.returncode}, diagnostics={len(diagnostics)}", flush=True)
    return 0 if records["strict_pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
