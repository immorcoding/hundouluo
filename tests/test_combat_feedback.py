"""Repeatable source-level checks for the runtime feedback wiring."""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]


class CombatFeedbackWiringTest(unittest.TestCase):
    def test_all_original_cues_are_wired_and_have_quiet_shots(self):
        source = (ROOT / "scripts/combat_feedback.gd").read_text(encoding="utf-8")
        audio = sorted(path.stem for path in (ROOT / "assets/audio").glob("*.wav"))
        cues = sorted(re.findall(r'"(\w+)": "res://assets/audio/\1.wav"', source))
        self.assertEqual(cues, audio)
        self.assertIn('"player_shot": -22.0', source)
        self.assertIn('"operative_hurt": -4.0', source)
        self.assertIn('"mech_charge_warning": -3.0', source)

    def test_level_connects_feedback_without_transferring_damage_to_hud(self):
        level = (ROOT / "scripts/level.gd").read_text(encoding="utf-8")
        for connection in (
            'soldier.warning_started.connect($CombatFeedback.play_cue.bind("enemy_warning"))',
            'charge_started.connect($CombatFeedback.play_cue.bind("mech_charge_warning"))',
            'projectile.impacted.connect($CombatFeedback.impact)',
            '"death_fall" if _fell else "death_health"',
        ):
            self.assertIn(connection, level)
        hud = (ROOT / "scripts/level_hud.gd").read_text(encoding="utf-8")
        self.assertNotIn("receive_hit", hud)


if __name__ == "__main__":
    unittest.main()
