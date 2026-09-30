import concurrent.futures
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent
fixture = root.parent / "full-temp/issue36-source-m_tw5e3p"
godot = "C:/Users/22137/tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"

def run(extra):
    output = root / ("warmup-" + str(extra))
    command = [godot, "--path", str(fixture), "--rendering-method", "gl_compatibility",
               "--fixed-fps", "60", "--script", str(root / "shift.gd"), "--",
               "--full", "--ticks=160", "--scenario=fixed", "--extra=" + str(extra), "--out=" + str(output)]
    result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", timeout=90)
    log = result.stdout + result.stderr
    (root / ("warmup-" + str(extra) + ".log")).write_text(log, encoding="utf-8")
    record = dict(extra=extra, exit=result.returncode, argv=command,
                  signal=[line for line in log.splitlines() if line.startswith(("PASS", "FAIL", "[DEBUG"))])
    print(json.dumps(record), flush=True)
    return record

with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
    records = list(executor.map(run, (0,4,12,16,20,24,28)))
(root / "sweep-results.json").write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
