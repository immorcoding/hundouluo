"""Generate original, deterministic game sound effects using the Python standard library."""

from __future__ import annotations

import argparse
import math
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 44100
DEFAULT_OUTPUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "audio"


def _write_wave(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = bytearray()
    for sample in samples:
        bounded = max(-0.999, min(0.999, sample))
        pcm.extend(struct.pack("<h", round(bounded * 32767)))

    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(pcm)


def _player_shot() -> list[float]:
    duration = 0.105
    frame_count = round(duration * SAMPLE_RATE)
    samples: list[float] = []
    for frame in range(frame_count):
        time = (frame + 0.5) / SAMPLE_RATE
        progress = time / duration
        phase = 2.0 * math.pi * (980.0 * time - 190.0 * time * progress)
        envelope = math.sin(math.pi * progress) ** 1.15
        tone = math.sin(phase) + 0.12 * math.sin(2.0 * phase)
        samples.append(0.16 * envelope * tone)
    return samples


def _swept_tone(
    duration: float,
    start_frequency: float,
    end_frequency: float,
    gain: float,
    harmonics: tuple[tuple[int, float], ...] = (),
    envelope_power: float = 1.0,
) -> list[float]:
    frame_count = round(duration * SAMPLE_RATE)
    samples: list[float] = []
    for frame in range(frame_count):
        time = (frame + 0.5) / SAMPLE_RATE
        progress = time / duration
        phase = 2.0 * math.pi * (
            start_frequency * time
            + 0.5 * (end_frequency - start_frequency) * time * progress
        )
        envelope = math.sin(math.pi * progress) ** envelope_power
        tone = math.sin(phase)
        for multiplier, level in harmonics:
            tone += level * math.sin(multiplier * phase)
        samples.append(gain * envelope * tone)
    return samples


def _enemy_shot() -> list[float]:
    return _swept_tone(
        0.125,
        560.0,
        310.0,
        0.24,
        harmonics=((2, 0.30), (3, 0.08)),
        envelope_power=0.85,
    )


def _hit_confirm() -> list[float]:
    duration = 0.132
    frame_count = round(duration * SAMPLE_RATE)
    samples: list[float] = []
    for frame in range(frame_count):
        time = (frame + 0.5) / SAMPLE_RATE
        progress = time / duration
        envelope = math.exp(-4.2 * progress)
        phase = 2.0 * math.pi * time
        metallic_ping = (
            0.58 * math.sin(1880.0 * phase)
            + 0.30 * math.sin(1270.0 * phase)
            + 0.12 * math.sin(420.0 * phase)
        )
        samples.append(0.31 * envelope * metallic_ping)
    return samples


def _operative_hurt() -> list[float]:
    return _swept_tone(
        0.285,
        690.0,
        295.0,
        0.56,
        harmonics=((2, 0.25), (3, 0.07)),
        envelope_power=0.78,
    )


def _enemy_warning() -> list[float]:
    duration = 0.32
    frame_count = round(duration * SAMPLE_RATE)
    samples: list[float] = []
    for frame in range(frame_count):
        time = (frame + 0.5) / SAMPLE_RATE
        progress = time / duration
        phase = 2.0 * math.pi * (690.0 * time + 210.0 * time * progress)
        if progress < 0.31:
            pulse_progress = progress / 0.31
            envelope = math.sin(math.pi * pulse_progress) ** 0.72
        elif 0.42 < progress < 0.79:
            pulse_progress = (progress - 0.42) / 0.37
            envelope = math.sin(math.pi * pulse_progress) ** 0.72
        else:
            envelope = 0.0
        tone = math.sin(phase) + 0.16 * math.sin(2.0 * phase)
        samples.append(0.50 * envelope * tone)
    return samples


def _mech_charge_warning() -> list[float]:
    duration = 0.52
    frame_count = round(duration * SAMPLE_RATE)
    samples: list[float] = []
    for frame in range(frame_count):
        time = (frame + 0.5) / SAMPLE_RATE
        progress = time / duration
        phase = 2.0 * math.pi * (118.0 * time + 71.0 * time * progress)
        swell = math.sin(0.5 * math.pi * progress)
        tail = min(1.0, (1.0 - progress) / 0.20)
        pulse = 0.74 + 0.26 * math.sin(2.0 * math.pi * 3.0 * progress) ** 2
        motor = math.sin(phase) + 0.38 * math.sin(2.0 * phase) + 0.12 * math.sin(3.0 * phase)
        samples.append(0.48 * swell * tail * pulse * motor)
    return samples


def _death_health() -> list[float]:
    return _swept_tone(
        0.36,
        510.0,
        185.0,
        0.39,
        harmonics=((2, 0.17), (3, 0.04)),
        envelope_power=0.72,
    )


def _death_fall() -> list[float]:
    duration = 0.39
    frame_count = round(duration * SAMPLE_RATE)
    samples: list[float] = []
    for frame in range(frame_count):
        time = (frame + 0.5) / SAMPLE_RATE
        progress = time / duration
        phase = 2.0 * math.pi * (840.0 * time - 330.0 * time * progress)
        airy_fall = 0.23 * math.sin(phase) * math.sin(math.pi * progress) ** 0.9
        impact_envelope = math.exp(-0.5 * ((progress - 0.84) / 0.055) ** 2)
        impact = 0.25 * impact_envelope * math.sin(2.0 * math.pi * 96.0 * time)
        samples.append(airy_fall + impact)
    return samples


def generate(output_dir: Path) -> list[Path]:
    """Write the current sound set and return the generated file paths."""
    cues = (
        ("player_shot.wav", _player_shot),
        ("enemy_shot.wav", _enemy_shot),
        ("hit_confirm.wav", _hit_confirm),
        ("operative_hurt.wav", _operative_hurt),
        ("enemy_warning.wav", _enemy_warning),
        ("mech_charge_warning.wav", _mech_charge_warning),
        ("death_health.wav", _death_health),
        ("death_fall.wav", _death_fall),
    )
    outputs = [output_dir / filename for filename, _ in cues]
    for output, (_, synthesize) in zip(outputs, cues):
        _write_wave(output, synthesize())
    return outputs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="directory for generated WAV files (default: assets/audio)",
    )
    args = parser.parse_args()

    for output in generate(args.output_dir):
        print(f"generated {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
