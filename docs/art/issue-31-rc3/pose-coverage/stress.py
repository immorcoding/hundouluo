import concurrent.futures
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent
fixture = root.parent / "full-temp/issue36-source-m_tw5e3p"
godot = "C:/Users/22137/tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"

def run(number):
    output = root / ("stress-" + str(number))
    command = [godot, "--path", str(fixture), "--rendering-method", "gl_compatibility",
               "--fixed-fps", "60", "--script", str(root / "observe.gd"), "--",
               "--full", "--ticks=180", "--scenario=fixed", "--out=" + str(output)]
    result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", timeout=90)
    log = result.stdout + result.stderr
    (root / ("stress-" + str(number) + ".log")).write_text(log, encoding="utf-8")
    record = dict(number=number, exit=result.returncode, argv=command,
                  signal=[line for line in log.splitlines() if line.startswith(("PASS", "FAIL", "[DEBUG"))])
    print(json.dumps(record), flush=True)
    return record

with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
    records = list(executor.map(run, range(1, 7)))
(root / "stress-results.json").write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
