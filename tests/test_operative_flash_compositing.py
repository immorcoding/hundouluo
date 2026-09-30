"""Actual graphical level/Input regression for the approved muzzle and gun."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class OperativeFlashCompositing(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.executable = shutil.which("Godot_v4.7.2-stable_win64_console.exe") or shutil.which("godot")
        if cls.executable is None:
            raise AssertionError("Graphical Godot is required")
        # The unified suite intentionally runs Python before importing its
        # clean source (the Windows package test requires that clean source).
        # Import an exact copy of the actual level's runtime files separately.
        # Retain the imported project for failure inspection. Windows can
        # still refresh .godot/editor files after the engine process exits;
        # deleting that directory in test teardown races those cache writes.
        cls.project = Path(tempfile.mkdtemp(prefix="issue36-source-", dir=os.environ.get("TEMP")))
        for directory in ("assets", "scenes", "scripts"):
            shutil.copytree(ROOT / directory, cls.project / directory)
        shutil.copyfile(ROOT / "project.godot", cls.project / "project.godot")
        (cls.project / "tools").mkdir()
        for script in ROOT.glob("tools/capture_issue_36*.gd*"):
            shutil.copyfile(script, cls.project / "tools" / script.name)
        # Preserve the project's ordinary startup dependency as well. Its
        # verification branch stays dormant without the explicit user flag.
        for name in ("rc3_render_verification.gd", "rc3_render_verification.gd.uid"):
            shutil.copyfile(ROOT / "tools" / name, cls.project / "tools" / name)
        command = [cls.executable, "--headless", "--editor", "--path", str(cls.project), "--import", "--quit"]
        result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8",
                                errors="replace", timeout=120)
        log = result.stdout + result.stderr
        if result.returncode or re.search(r"^\s*(ERROR:|SCRIPT ERROR:|WARNING:)", log, re.MULTILINE):
            raise AssertionError("Runtime fixture import failed:\n" + log)

    def test_visible_muzzle_rear_meets_barrel_and_gun_stays_stable(self):
        self.run_capture(["--ticks=12"])

    def test_running_turning_jump_landing_hurt_and_both_cameras(self):
        for scenario in ("spawn", "follow", "fixed"):
            with self.subTest(scenario=scenario):
                self.run_capture(["--full", "--ticks=180", "--scenario=" + scenario])

    def test_victory_freeze_death_and_physical_retry(self):
        self.run_capture([], script="tools/capture_issue_36_outcomes.gd", fps="30")

    def run_capture(self, arguments, script="tools/capture_issue_36.gd", fps="60"):
        with tempfile.TemporaryDirectory(prefix="issue36-render-", dir=os.environ.get("TEMP")) as output:
            command = [self.executable, "--path", str(self.project), "--rendering-method", "gl_compatibility",
                       "--fixed-fps", fps, "--script", script, "--",
                       "--out=" + output, *arguments]
            result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                                    encoding="utf-8", errors="replace", timeout=60)
            log = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, log)
            self.assertIsNone(re.search(r"^\s*(ERROR:|SCRIPT ERROR:|WARNING:)", log, re.MULTILINE), log)
            self.assertIn("PASS: visible muzzle attachment and stable gun pixels", log)


if __name__ == "__main__":
    unittest.main()
