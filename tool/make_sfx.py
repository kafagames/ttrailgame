"""Synthesises every sound in Thimble Trail from scratch (no samples, no
licences). Run from the project root:  python tool/make_sfx.py
Writes assets/sfx/*.wav."""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sfx')


def write(name, samples, level=0.8):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = level / peak
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s * gain)) * 32767)) for s in samples))
    print('wrote', name, round(len(samples) / RATE, 2), 's')


def bell(freq, dur, decay=6.0, partials=((1, 1.0), (2.0, 0.3), (3.01, 0.1), (4.2, 0.05)), attack=0.003):
    n = int(RATE * dur)
    return [min(1.0, (i / RATE) / attack) * math.exp(-decay * i / RATE)
            * sum(a * math.sin(2 * math.pi * freq * m * i / RATE) for m, a in partials) for i in range(n)]


def noise_burst(dur, decay, colour=0.6, seed=1):
    rnd = random.Random(seed)
    n = int(RATE * dur)
    out, b = [], 0.0
    for i in range(n):
        b = colour * b + (1 - colour) * (rnd.random() * 2 - 1)
        out.append(b * math.exp(-decay * i / RATE))
    return out


def thump(freq, dur, decay):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        f = freq * (1 + 0.6 * math.exp(-t * 40))
        out.append(math.sin(2 * math.pi * f * t) * math.exp(-decay * t))
    return out


def mix(*parts):
    n = max(int(o * RATE) + len(s) for o, s in parts)
    out = [0.0] * n
    for o, s in parts:
        k = int(o * RATE)
        for i, v in enumerate(s):
            out[k + i] += v
    return out


def scale(s, g):
    return [v * g for v in s]


# Lifting a patch from the tray: a short cloth rustle.
write('pick', noise_burst(0.12, 30, 0.82, 2), 0.5)
# Turning a patch: dry wooden tick.
write('turn', mix((0, scale(noise_burst(0.04, 90, 0.3, 3), 0.6)), (0, thump(900, 0.06, 70))), 0.5)
# Sewing a patch down: soft pressed-cloth thump plus a needle tick.
write('place', mix((0, thump(150, 0.22, 22)), (0, scale(noise_burst(0.1, 40, 0.85, 4), 0.5)),
                   (0.03, scale(bell(2400, 0.06, 60), 0.25))), 0.75)
# Unpicking: a quick thread pull (rising filtered noise).
def zip_sound():
    rnd = random.Random(5)
    n = int(RATE * 0.18)
    out, b = [], 0.0
    for i in range(n):
        t = i / n
        c = 0.9 - 0.6 * t
        b = c * b + (1 - c) * (rnd.random() * 2 - 1)
        out.append(b * math.sin(math.pi * t))
    return out
write('unpick', zip_sound(), 0.5)
# Refused placement: muted double thud.
write('nope', mix((0, thump(110, 0.14, 30)), (0.09, thump(95, 0.14, 30))), 0.55)
# Quilt bound: music-box arpeggio F A C F.
write('bound', mix(*[(i * 0.11, bell(f, 1.4, 3.5)) for i, f in enumerate((698.5, 880, 1046.5, 1396.9))]), 0.75)
# Each star.
write('star', bell(1760, 0.5, 8, ((1, 1.0), (2.76, 0.2))), 0.55)
# Ribbon earned / new chapter: two bright notes.
write('ribbon', mix((0, bell(1046.5, 0.7, 5)), (0.13, bell(1568, 1.0, 4))), 0.65)
# Hint: needle glint shimmer.
write('hint', mix(*[(i * 0.045, bell(2093 + i * 262, 0.35, 12)) for i in range(5)]), 0.45)
# Menu tap / page.
write('tap', mix((0, thump(420, 0.05, 80)), (0, scale(noise_burst(0.03, 120, 0.5, 6), 0.4))), 0.45)


# ---- Music: a slow music-box tune in F major pentatonic over a soft bed.
def music():
    bpm = 72
    beat = 60 / bpm
    notes = {'F4': 349.2, 'G4': 392.0, 'A4': 440.0, 'C5': 523.3, 'D5': 587.3,
             'F5': 698.5, 'G5': 784.0, 'A5': 880.0, 'C4': 261.6, 'D4': 293.7, 'A3': 220.0, 'F3': 174.6}
    melody = [
        ('A4', 1), ('C5', 1), ('D5', 2), ('C5', 1), ('A4', 1), ('G4', 2),
        ('F4', 1), ('G4', 1), ('A4', 1), ('C5', 1), ('A4', 4),
        ('D5', 1), ('F5', 1), ('D5', 1), ('C5', 1), ('A4', 2), ('G4', 2),
        ('A4', 1), ('G4', 1), ('F4', 2), ('C4', 2), ('F4', 2),
    ]
    bass = [('F3', 4), ('D4', 4), ('A3', 4), ('C4', 4), ('F3', 4), ('D4', 4), ('C4', 4), ('F3', 4)]
    total_beats = sum(d for _, d in melody)
    dur = total_beats * beat
    parts = []
    t = 0.0
    for name, d in melody:
        parts.append((t, scale(bell(notes[name], min(2.6, d * beat + 1.2), 2.4,
                                    ((1, 1.0), (3.0, 0.18), (5.4, 0.05))), 0.5)))
        t += d * beat
    t = 0.0
    for name, d in bass:
        parts.append((t, scale(bell(notes[name], d * beat + 0.8, 1.6, ((1, 1.0), (2, 0.25))), 0.28)))
        t += d * beat
    out = mix(*parts)
    n = int(dur * RATE)
    # Wrap the ringing tail back to the start so the loop is seamless.
    for i in range(n, len(out)):
        out[i - n] += out[i]
    out = out[:n]
    room = noise_burst(dur, 0, 0.995, 9)
    return [v + room[i] * 0.02 for i, v in enumerate(out)]


write('music', music(), 0.42)
print('ok', sorted(os.listdir(OUT)))
