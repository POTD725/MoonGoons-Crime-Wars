"""Generate original MoonGoons: Crime Wars WAV cues with Python's standard library.

Run from the project root:
    python generate_audio_pack.py

The script writes short, low-memory, Godot-friendly PCM WAV files into ./audio.
No samples, copyrighted music, or external package downloads are used.
"""

from __future__ import annotations

import math
import wave
from pathlib import Path

SAMPLE_RATE = 8000
OUT = Path(__file__).resolve().parent / "audio"


def envelope(length: int, attack: float = 0.008, release: float = 0.05) -> list[float]:
    attack_samples = max(1, int(attack * SAMPLE_RATE))
    release_samples = max(1, int(release * SAMPLE_RATE))
    values = [1.0] * length
    for index in range(min(attack_samples, length)):
        values[index] = index / attack_samples
    for index in range(min(release_samples, length)):
        end_index = length - release_samples + index
        if 0 <= end_index < length:
            values[end_index] = 1.0 - index / release_samples
    return values


def waveform(kind: str, phase: float) -> float:
    if kind == "square":
        return 1.0 if math.sin(phase) >= 0.0 else -1.0
    if kind == "saw":
        return 2.0 * ((phase / math.tau) % 1.0) - 1.0
    if kind == "triangle":
        return 2.0 / math.pi * math.asin(math.sin(phase))
    return math.sin(phase)


def make_cue(events: list[tuple[float, float, float, float]], duration: float, kind: str = "sine") -> list[float]:
    length = int(duration * SAMPLE_RATE)
    samples = [0.0] * length
    for frequency, start, event_length, volume in events:
        start_index = int(start * SAMPLE_RATE)
        event_samples = int(event_length * SAMPLE_RATE)
        shape = envelope(event_samples, 0.008, min(0.05, event_length / 3.0))
        for local_index in range(event_samples):
            index = start_index + local_index
            if index >= length:
                break
            phase = math.tau * frequency * local_index / SAMPLE_RATE
            samples[index] += waveform(kind, phase) * volume * shape[local_index]
    return samples


def write_wav(path: Path, samples: list[float]) -> None:
    data = bytearray()
    for sample in samples:
        clipped = max(-1.0, min(1.0, sample))
        data.append(int((clipped + 1.0) * 127.5))
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(1)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(bytes(data))


def make_ambience() -> list[float]:
    length = SAMPLE_RATE * 2
    result: list[float] = []
    for index in range(length):
        time = index / SAMPLE_RATE
        sample = (
            0.12 * math.sin(math.tau * 55.0 * time)
            + 0.08 * math.sin(math.tau * 82.41 * time)
            + 0.035 * math.sin(math.tau * 164.81 * time)
        )
        sample *= 0.65 + 0.35 * math.sin(math.tau * 0.2 * time)
        result.append(sample * envelope(length, 0.2, 0.25)[index])
    return result


def main() -> None:
    OUT.mkdir(exist_ok=True)
    cues = {
        "mission_deploy.wav": make_cue([(220, 0.0, 0.2, 0.2), (330, 0.12, 0.2, 0.22), (440, 0.24, 0.24, 0.22), (660, 0.38, 0.26, 0.25)], 0.8),
        "mission_alert.wav": make_cue([(660, 0.0, 0.14, 0.27), (880, 0.17, 0.14, 0.27), (660, 0.34, 0.14, 0.27), (880, 0.51, 0.14, 0.27)], 0.72, "square"),
        "mission_victory.wav": make_cue([(440, 0.0, 0.2, 0.2), (554, 0.12, 0.22, 0.22), (659, 0.24, 0.28, 0.25), (880, 0.42, 0.38, 0.25)], 0.9),
        "mission_failure.wav": make_cue([(220, 0.0, 0.4, 0.28), (185, 0.17, 0.4, 0.25), (146, 0.34, 0.4, 0.22)], 0.9, "triangle"),
        "voice_authority_bleep.wav": make_cue([(720, 0.0, 0.035, 0.35), (880, 0.045, 0.035, 0.35), (760, 0.09, 0.035, 0.3)], 0.14, "square"),
        "voice_syndicate_bleep.wav": make_cue([(310, 0.0, 0.045, 0.35), (240, 0.055, 0.045, 0.35), (340, 0.11, 0.05, 0.3)], 0.17, "saw"),
        "cutscene_ambience.wav": make_ambience(),
    }
    for filename, samples in cues.items():
        write_wav(OUT / filename, samples)
        print(f"Created {OUT / filename}")


if __name__ == "__main__":
    main()
