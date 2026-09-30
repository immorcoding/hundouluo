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
    def test_visible_muzzle_rear_meets_barrel_and_gun_stays_stable(self):
        self.run_capture(["--ticks=12"])

    def test_running_turning_jump_landing_hurt_and_both_cameras(self):
        for scenario in ("spawn", "follow", "fixed"):
            with self.subTest(scenario=scenario):
                self.run_capture(["--full", "--ticks=180", "--scenario=" + scenario])

    def test_victory_freeze_death_and_physical_retry(self):
        self.run_capture([], script="tools/capture_issue_36_outcomes.gd", fps="30")

    def run_capture(self, arguments, script="tools/capture_issue_36.gd", fps="60"):
        executable = shutil.which("Godot_v4.7.2-stable_win64_console.exe") or shutil.which("godot")
        self.assertIsNotNone(executable, "Graphical Godot is required")
        with tempfile.TemporaryDirectory(prefix="issue36-render-", dir=os.environ.get("TEMP")) as output:
            command = [executable, "--path", str(ROOT), "--rendering-method", "gl_compatibility",
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
