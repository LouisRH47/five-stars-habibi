"""Makes every sound and the music for Five Stars Habibi (Session 16).

Nothing here is copied from anywhere: each sound is worked out from simple maths
(sine waves, noise and a plucked-string trick called Karplus-Strong), so all of it is
ours and free to use (CC0, see CREDITS.md). Run it again to remake the files:

    python3 tools/make_sounds.py

It writes .wav files into assets/audio/. Only plain Python is needed (no extra installs).
"""
import math
import os
import random
import struct
import wave
from array import array

RATE = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
random.seed(7)  # the same "random" every time, so the files come out the same


def silence(seconds):
    return array("f", [0.0]) * int(seconds * RATE)


def mix_in(track, sound, start_seconds, volume=1.0):
    start = int(start_seconds * RATE)
    for i, value in enumerate(sound):
        j = start + i
        if j >= len(track):
            j -= len(track)  # wrap round, so loops join up smoothly
        track[j] += value * volume


def save(name, samples, peak=0.85):
    top = max(1e-9, max(abs(v) for v in samples))
    scale = peak / top
    data = array("h", (int(max(-1.0, min(1.0, v * scale)) * 32767) for v in samples))
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(data.tobytes())
    print("made", name, "%.1f s" % (len(samples) / RATE))


def tone(freq, seconds, decay, volume=1.0, attack=0.005):
    out = array("f")
    for i in range(int(seconds * RATE)):
        t = i / RATE
        env = min(1.0, t / attack) * math.exp(-t * decay)
        out.append(math.sin(2 * math.pi * freq * t) * env * volume)
    return out


def noise(seconds, decay, smooth=0.0, volume=1.0):
    """Noise that dies away. smooth near 1 = deep rumble, 0 = bright hiss."""
    out = array("f")
    last = 0.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        last = last * smooth + random.uniform(-1, 1) * (1 - smooth)
        out.append(last * math.exp(-t * decay) * volume)
    return out


def add(*sounds):
    out = silence(max(len(s) for s in sounds) / RATE)
    for s in sounds:
        for i, v in enumerate(s):
            out[i] += v
    return out


def pluck(freq, seconds, brightness=0.5, volume=1.0):
    """A plucked string (like an oud) with the Karplus-Strong trick."""
    size = max(2, int(RATE / freq))
    ring = [random.uniform(-1, 1) for _ in range(size)]
    out = array("f")
    keep = 0.996 - (1 - brightness) * 0.004
    for i in range(int(seconds * RATE)):
        a = ring[i % size]
        b = ring[(i + 1) % size]
        ring[i % size] = (a + b) * 0.5 * keep
        out.append(a * volume)
    return out


def echo(track, delay_seconds, feedback, mix):
    """A soft room echo (wraps round, for loops)."""
    delay = int(delay_seconds * RATE)
    wet = array("f", track)
    for i in range(len(track)):
        wet[i] += wet[i - delay] * feedback
    return array("f", (d * (1 - mix) + w * mix for d, w in zip(track, wet)))


def loop_fade(samples, seconds):
    """Blends the end into the start so a loop has no click."""
    n = int(seconds * RATE)
    out = array("f", samples[: len(samples) - n])
    for i in range(n):
        k = i / n
        out[i] = out[i] * k + samples[len(samples) - n + i] * (1 - k)
    return out


# ---------------- Sound effects ----------------

def bell():
    def ding(start):
        return [tone(f, 0.9, d, v) for f, d, v in ((2600, 5, 1.0), (3950, 7, 0.5), (5400, 10, 0.3))], start
    track = silence(1.2)
    for start in (0.0, 0.17):
        parts, at = ding(start)
        for p in parts:
            mix_in(track, p, at)
    return track


def cash():
    track = silence(1.0)
    mix_in(track, noise(0.07, 30, 0.2, 0.6), 0.0)  # the drawer "cha"
    for f, d, v in ((1760, 4, 1.0), (2640, 5, 0.6), (3520, 6, 0.4)):  # the "ching"
        mix_in(track, tone(f, 0.9, d, v), 0.06)
    for k in range(5):  # a few coins
        mix_in(track, tone(random.uniform(4000, 6000), 0.12, 30, 0.25), 0.1 + k * 0.05)
    return track


def crash():
    track = silence(1.0)
    thud = array("f")
    for i in range(int(0.35 * RATE)):
        t = i / RATE
        thud.append(math.sin(2 * math.pi * (80 - 90 * t) * t) * math.exp(-t * 9))
    mix_in(track, thud, 0.0, 1.0)
    mix_in(track, noise(0.6, 7, 0.55, 0.9), 0.0)
    for f in (410, 730, 1190, 1630):  # bent metal
        mix_in(track, tone(f, 0.6, 8, 0.25), 0.02)
    return track


def ping():
    track = silence(0.5)
    mix_in(track, tone(880, 0.25, 12, 0.8, 0.01), 0.0)
    mix_in(track, tone(1320, 0.3, 10, 0.8, 0.01), 0.11)
    return track


def bump():
    track = array("f")
    for i in range(int(0.25 * RATE)):
        t = i / RATE
        track.append(math.sin(2 * math.pi * (110 - 160 * t) * t) * math.exp(-t * 18))
    return add(track, noise(0.15, 25, 0.7, 0.4))


def roll_loop():
    """Tyres on the road: a soft hiss. The game turns it up with your speed."""
    hiss = noise(2.4, 0, 0.75, 1.0)
    clicks = silence(2.4)  # the freewheel ticking
    for k in range(int(2.2 / 0.09)):
        mix_in(clicks, tone(3200, 0.02, 200, 0.2), k * 0.09)
    return loop_fade(add(hiss, clicks), 0.4)


def ambience_loop():
    """Distant traffic and birds, 24 seconds, loops."""
    seconds = 24.0
    rumble = noise(seconds, 0, 0.985, 1.0)
    track = array("f", (v * 0.9 for v in rumble))
    for _ in range(26):  # bird chirps: quick little whistles
        start = random.uniform(0, seconds - 1)
        base = random.uniform(2500, 4200)
        for n in range(random.randint(2, 4)):
            chirp = array("f")
            length = random.uniform(0.05, 0.11)
            up = random.uniform(-900, 1300)
            for i in range(int(length * RATE)):
                t = i / RATE
                f = base + up * t / length
                env = math.sin(math.pi * t / length)
                chirp.append(math.sin(2 * math.pi * f * t) * env * 0.12)
            mix_in(track, chirp, start + n * 0.13)
    return loop_fade(track, 1.0)


# ---------------- Music ----------------
# A chill loop in maqam Hijaz on D (the classic "Arabic" sound): D Eb F# G A Bb C D.
# An oud-like pluck plays the tune, a darbuka plays the maqsum rhythm
# (doum tek - tek doum - tek -), and a low D drone holds it together.

BPM = 90
BEAT = 60.0 / BPM
NOTES = {"D3": 146.83, "A3": 220.0, "D4": 293.66, "Eb4": 311.13, "F#4": 369.99, "G4": 392.0,
         "A4": 440.0, "Bb4": 466.16, "C5": 523.25, "D5": 587.33, "D2": 73.42, "A2": 110.0}
# The tune, in eighth notes: (note or None for a rest, how many eighths it lasts).
PHRASES = [
    [("D4", 2), ("Eb4", 1), ("F#4", 1), ("G4", 2), ("F#4", 2), ("Eb4", 2), ("D4", 4), (None, 2)],
    [("A4", 2), ("G4", 1), ("F#4", 1), ("G4", 2), ("A4", 2), ("Bb4", 2), ("A4", 4), (None, 2)],
    [("D5", 2), ("C5", 1), ("Bb4", 1), ("A4", 2), ("G4", 1), ("F#4", 1), ("G4", 2), ("F#4", 2), ("Eb4", 2), ("D4", 2)],
    [("F#4", 1), ("G4", 1), ("A4", 2), ("G4", 1), ("F#4", 1), ("Eb4", 2), ("D4", 6), (None, 2)],
]
BARS = 20  # 4 bars of drums and drone, then the 8-bar tune twice


def doum():
    out = array("f")
    for i in range(int(0.4 * RATE)):
        t = i / RATE
        out.append(math.sin(2 * math.pi * (95 - 50 * t) * t) * math.exp(-t * 9))
    return out


def tek():
    return add(noise(0.06, 70, 0.0, 0.5), tone(1900, 0.06, 60, 0.3))


def music_loop():
    bar = BEAT * 4
    total = bar * BARS
    track = silence(total)
    d, t = doum(), tek()
    pattern = ["D", "T", None, "T", "D", None, "T", None]  # maqsum, in eighths
    for b in range(BARS):
        for slot, hit in enumerate(pattern):
            at = b * bar + slot * BEAT / 2
            if hit == "D":
                mix_in(track, d, at, 0.6)
            elif hit == "T":
                mix_in(track, t, at, 0.3 if slot != 1 else 0.4)
        mix_in(track, pluck(NOTES["D2"], 2.5, 0.3, 0.55), b * bar)  # low drone pluck each bar
        if b % 2 == 1:
            mix_in(track, pluck(NOTES["A2"], 1.5, 0.3, 0.35), b * bar + 2 * BEAT)
    pad = array("f")  # a soft hum on D and A under everything
    for i in range(len(track)):
        tt = i / RATE
        wobble = 0.8 + 0.2 * math.sin(2 * math.pi * 0.25 * tt)
        pad.append((math.sin(2 * math.pi * NOTES["D3"] * tt) + 0.6 * math.sin(2 * math.pi * NOTES["A3"] * tt)) * 0.06 * wobble)
    mix_in(track, pad, 0.0)
    at = 4 * bar
    for repeat in range(2):
        for phrase in PHRASES:
            for note, eighths in phrase:
                if note is not None:
                    length = eighths * BEAT / 2
                    mix_in(track, pluck(NOTES[note], length + 0.6, 0.6, 0.9), at)
                    if repeat == 1:  # the second time round, an octave-up echo
                        mix_in(track, pluck(NOTES[note] * 2, length + 0.3, 0.7, 0.15), at + 0.02)
                at += eighths * BEAT / 2
    return echo(track, BEAT * 0.75, 0.3, 0.25)


if __name__ == "__main__":
    save("bell.wav", bell())
    save("cash.wav", cash())
    save("crash.wav", crash())
    save("ping.wav", ping())
    save("bump.wav", bump())
    save("roll_loop.wav", roll_loop(), 0.5)
    save("ambience_loop.wav", ambience_loop(), 0.5)
    save("music_loop.wav", music_loop(), 0.8)
