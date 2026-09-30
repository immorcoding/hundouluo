"""End-to-end checks for the Windows source and playable package contract."""

import os
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PACKAGE_SCRIPT = PROJECT_ROOT / "tools" / "package_windows.ps1"
GODOT = shutil.which("Godot_v4.7.2-stable_win64_console.exe")
POWERSHELL = shutil.which("pwsh.exe") or shutil.which("powershell.exe")
TEMPLATE_ROOT = Path(os.environ.get("APPDATA", "")) / "Godot" / "export_templates" / "4.7.2.stable"
WINDOWS_EXPORT_READY = (
    sys.platform == "win32"
    and GODOT is not None
    and POWERSHELL is not None
    and (TEMPLATE_ROOT / "windows_release_x86_64.exe").is_file()
)


@unittest.skipUnless(
    WINDOWS_EXPORT_READY,
    "requires Windows, Godot 4.7.2 console, PowerShell, and the x86_64 release template",
)
class WindowsPackageTests(unittest.TestCase):
    def _run_package_script(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                POWERSHELL,
                "-NoProfile",
                "-NonInteractive",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(PACKAGE_SCRIPT),
                "-GodotPath",
                GODOT,
                *arguments,
            ],
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            timeout=600,
            check=False,
        )

    def test_preflight_accepts_installed_official_toolchain(self) -> None:
        result = self._run_package_script("-CheckOnly")

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("preflight passed", result.stdout.lower())

    def test_archives_match_source_and_unpacked_executable_starts(self) -> None:
        with tempfile.TemporaryDirectory(prefix="hundouluo-package-test-") as temporary_directory:
            output_directory = Path(temporary_directory) / "packages"
            result = self._run_package_script("-OutputDirectory", str(output_directory))

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("unpacked startup passed", result.stdout.lower())

            source_archives = list(output_directory.glob("hundouluo-preparation-source-*.zip"))
            windows_archives = list(output_directory.glob("hundouluo-preparation-windows-x86_64-*.zip"))
            self.assertEqual(len(source_archives), 1)
            self.assertEqual(len(windows_archives), 1)

            with zipfile.ZipFile(source_archives[0]) as source_archive:
                self.assertIsNone(source_archive.testzip())
                source_entries = set(source_archive.namelist())
                for required_file in (
                    "project.godot",
                    "export_presets.cfg",
                    "README.md",
                    "LICENSE",
                    "docs/assets-manifest.md",
                    "docs/release-prep.md",
                ):
                    self.assertIn(required_file, source_entries)
                self.assertFalse(any(path.startswith(".git/") for path in source_entries))

            with zipfile.ZipFile(windows_archives[0]) as windows_archive:
                self.assertIsNone(windows_archive.testzip())
                windows_entries = set(windows_archive.namelist())
                self.assertIn("轨道基地.exe", windows_entries)
                self.assertIn("README.md", windows_entries)
                self.assertIn("LICENSE", windows_entries)
                self.assertIn("BUILD_INFO.txt", windows_entries)
                self.assertIn("试玩说明.txt", windows_entries)
                self.assertIn("docs/assets-manifest.md", windows_entries)
                self.assertIn("docs/acceptance-v0.1.1.md", windows_entries)
                self.assertIn("docs/known-issues-v0.1.1.md", windows_entries)
                self.assertIn("GODOT_LICENSE.txt", windows_entries)
                self.assertIn("GODOT_COPYRIGHT.json", windows_entries)
                self.assertIn("GODOT_THIRD_PARTY_LICENSES.json", windows_entries)
                self.assertIn("Godot Engine contributors", windows_archive.read("GODOT_LICENSE.txt").decode("utf-8"))
                self.assertTrue(json.loads(windows_archive.read("GODOT_COPYRIGHT.json")))
                self.assertTrue(json.loads(windows_archive.read("GODOT_THIRD_PARTY_LICENSES.json")))
                self.assertFalse(any(path.lower().endswith(".pck") for path in windows_entries))
                build_info = windows_archive.read("BUILD_INFO.txt").decode("utf-8")
                self.assertIn("source_commit=", build_info)
                self.assertIn("真人试玩：未测", build_info)
                play_info = windows_archive.read("试玩说明.txt").decode("utf-8")
                self.assertIn("双击", play_info)
                self.assertIn("按住 J", play_info)
                self.assertIn("preparation", play_info)
                self.assertIn("docs/acceptance-v0.1.1.md", play_info)
                self.assertNotIn("v0.1.0", play_info)
                self.assertNotIn(str(PROJECT_ROOT), build_info)


if __name__ == "__main__":
    unittest.main()
