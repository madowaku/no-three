"""Small original synthesized cues, with no third-party audio dependency."""
from math import exp, pi, sin
from pathlib import Path
import struct
import wave

OUT = Path(__file__).resolve().parents[1] / "assets/audio"
RATE = 44100
CUES = {"place": (0.15, [660, 990]), "reject": (0.09, [330, 1320]),
        "pickup": (0.1, [440, 880]), "clear": (0.65, [523.25, 659.25, 783.99])}

def generate() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for cue, (duration, frequencies) in CUES.items():
        samples = []
        for index in range(int(RATE * duration)):
            time = index / RATE
            value = 0.0
            for voice, frequency in enumerate(frequencies):
                offset = voice * 0.065 if cue == "clear" else 0
                elapsed = time - offset
                if elapsed >= 0:
                    envelope = min(elapsed / 0.004, 1) * exp(-elapsed * (9 if cue == "clear" else 36))
                    value += sin(2*pi*frequency*elapsed) * envelope / len(frequencies)
            fade = min((duration-time)/0.015, 1)
            samples.append(struct.pack("<h", int(value * fade * 12000)))
        with wave.open(str(OUT / f"{cue}.wav"), "wb") as output:
            output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
            output.writeframes(b"".join(samples))

if __name__ == "__main__":
    generate()
