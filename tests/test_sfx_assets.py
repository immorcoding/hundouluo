"""Behavior checks at the generate_sfx.py command-line seam."""

from __future__ import annotations

import math
import struct
import subprocess
import sys
import tempfile
import wave
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
GENERATOR = ROOT / "tools" / "generate_sfx.py"
MANIFEST = ROOT / "docs" / "assets-manifest.md"
EXPECTED_CUES = {
    "player_shot.wav",
    "enemy_shot.wav",
    "hit_confirm.wav",
    "operative_hurt.wav",
    "enemy_warning.wav",
    "mech_charge_warning.wav",
    "death_health.wav",
    "death_fall.wav",
}


def run_generator(output_dir: str | Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(GENERATOR), "--output-dir", str(output_dir)],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )


class SoundAssetTests(unittest.TestCase):
    def test_manifest_traces_generated_audio_and_existing_original_art(self) -> None:
        self.assertTrue(MANIFEST.is_file())
        manifest = MANIFEST.read_text(encoding="utf-8")
        for cue in EXPECTED_CUES:
            self.assertIn(cue, manifest)
        for source in (
            "tools/generate_sfx.py",
            "assets/art_source/README.md",
            "assets/art_source/PROMPTS.md",
            "docs/art/README.md",
            "tools/build_pixel_art.py",
            "tools/assemble_hangar_art.py",
            "assets/pixel/operative.png",
            "assets/pixel/mechanical_soldier.png",
            "assets/pixel/defense_mech.png",
            "assets/pixel/hangar_far.png",
            "assets/pixel/hangar_mid.png",
            "assets/pixel/hangar_deck.png",
        ):
            self.assertIn(source, manifest)

    def test_sound_set_has_distinct_short_feedback_and_prioritizes_danger(self) -> None:
        with tempfile.TemporaryDirectory() as output_dir:
            result = run_generator(output_dir)
            self.assertEqual(result.returncode, 0, result.stderr)

            files = {path.name: path for path in Path(output_dir).glob("*.wav")}
            self.assertEqual(set(files), EXPECTED_CUES)
            self.assertEqual(len({path.read_bytes() for path in files.values()}), len(EXPECTED_CUES))

            rms_by_name: dict[str, float] = {}
            for name, path in files.items():
                with wave.open(str(path), "rb") as sound:
                    self.assertEqual(sound.getparams()[:3], (1, 2, 44100))
                    frame_count = sound.getnframes()
                    duration = frame_count / sound.getframerate()
                    self.assertGreaterEqual(duration, 0.06)
                    self.assertLessEqual(duration, 0.70)
                    samples = struct.unpack(f"<{frame_count}h", sound.readframes(frame_count))
                peak = max(abs(sample) for sample in samples)
                self.assertGreater(peak, 0, name)
                self.assertLess(peak, 32767, name)
                rms_by_name[name] = math.sqrt(sum(sample * sample for sample in samples) / frame_count)

            shot_level = rms_by_name["player_shot.wav"]
            for prominent_cue in ("operative_hurt.wav", "enemy_warning.wav", "mech_charge_warning.wav"):
                self.assertGreater(rms_by_name[prominent_cue], shot_level, prominent_cue)

    def test_player_shot_is_a_repeatable_short_mono_pcm_wave(self) -> None:
        with tempfile.TemporaryDirectory() as first_dir, tempfile.TemporaryDirectory() as second_dir:
            first = run_generator(first_dir)
            second = run_generator(second_dir)

            self.assertEqual(first.returncode, 0, first.stderr)
            self.assertEqual(second.returncode, 0, second.stderr)
            first_wave = Path(first_dir) / "player_shot.wav"
            second_wave = Path(second_dir) / "player_shot.wav"
            self.assertTrue(first_wave.is_file())
            self.assertEqual(first_wave.read_bytes(), second_wave.read_bytes())

            with wave.open(str(first_wave), "rb") as sound:
                self.assertEqual(sound.getnchannels(), 1)
                self.assertEqual(sound.getsampwidth(), 2)
                self.assertEqual(sound.getframerate(), 44100)
                duration = sound.getnframes() / sound.getframerate()
                self.assertGreaterEqual(duration, 0.03)
                self.assertLessEqual(duration, 0.20)
                samples = struct.unpack(f"<{sound.getnframes()}h", sound.readframes(sound.getnframes()))

            peak = max(abs(sample) for sample in samples)
            self.assertGreater(peak, 0)
            self.assertLess(peak, 32767)


if __name__ == "__main__":
    unittest.main()
