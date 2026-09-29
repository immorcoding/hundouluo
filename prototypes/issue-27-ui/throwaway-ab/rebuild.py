"""THROWAWAY: rebuild captures from the pinned main snapshot, then native UI images."""
from pathlib import Path
import io
import shutil
import subprocess
import zipfile

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
BASE = "3f970aafdd4628d0da931997197e630a7736735b"
GODOT = shutil.which("Godot_v4.7.2-stable_win64_console.exe")
if not GODOT:
    raise SystemExit("Godot 4.7.2 console executable must be on PATH")
SNAPSHOT = HERE / ".capture-project"
SNAPSHOT.mkdir(exist_ok=True)
archive = subprocess.check_output(["git", "archive", "--format=zip", BASE], cwd=REPO)
with zipfile.ZipFile(io.BytesIO(archive)) as source:
    source.extractall(SNAPSHOT)
shutil.copyfile(HERE / "capture_main.gd", SNAPSHOT / "capture_ab.gd")
subprocess.run([GODOT, "--headless", "--editor", "--path", str(SNAPSHOT), "--import"], check=True)
subprocess.run([GODOT, "--path", str(SNAPSHOT), "--rendering-method", "gl_compatibility",
                "--script", "capture_ab.gd", "--", str(HERE / "captures")], check=True)
subprocess.run([GODOT, "--path", str(REPO), "--rendering-method", "gl_compatibility",
                "--script", str(HERE / "render_ab.gd")], check=True)
