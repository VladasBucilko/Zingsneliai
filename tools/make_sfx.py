"""Synthesize the soft sound effects in assets/sfx/ (pop.wav, chime.wav).

Run: python3 tools/make_sfx.py
Kept deliberately gentle: low volume, rounded attacks, no harsh frequencies.
"""
import math, struct, wave, pathlib

RATE = 44100
OUT = pathlib.Path(__file__).resolve().parent.parent / "assets" / "sfx"


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))


def pop():
    # Short downward "bloop": sine sweep 700 -> 260 Hz with soft attack and fast decay.
    n = int(RATE * 0.16)
    out, phase = [], 0.0
    for i in range(n):
        t = i / RATE
        f = 260 + 440 * math.exp(-t * 30)
        phase += 2 * math.pi * f / RATE
        env = min(1.0, t / 0.004) * math.exp(-t * 26)
        out.append(0.45 * env * math.sin(phase))
    return out


def chime():
    # Two soft bell-like notes (G5 then C6), sine + quiet octave partial.
    out = [0.0] * int(RATE * 0.9)
    for start, f in ((0.0, 783.99), (0.14, 1046.5)):
        s0 = int(start * RATE)
        for i in range(len(out) - s0):
            t = i / RATE
            env = min(1.0, t / 0.01) * math.exp(-t * 5.5)
            v = math.sin(2 * math.pi * f * t) + 0.25 * math.sin(2 * math.pi * 2 * f * t)
            out[s0 + i] += 0.22 * env * v
    return out


if __name__ == "__main__":
    write("pop.wav", pop())
    write("chime.wav", chime())
    print("wrote", sorted(p.name for p in OUT.glob("*.wav")))
