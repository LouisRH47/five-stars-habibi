"""Makes every sound and the music for Five Stars Habibi (Session 16).

Nothing here is copied from anywhere: each sound is worked out from simple maths
(sine waves, noise and a plucked-string trick called Karplus-Strong), so all of it is
ours and free to use (CC0, see CREDITS.md). Run it again to remake the files:

    python3 tools/make_sounds.py

It writes .wav files into assets/audio/. Only plain Python is needed (no extra installs).
Session 71: "python3 tools/make_sounds.py ui" makes only the 9 UI sounds (ui_hover, ui_click...).
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


def ring():
    """The bike's thumb bell (Session 29, the B key): a quick metal trill, brrring-ring."""
    track = silence(1.3)
    strikes = [i * 0.045 for i in range(8)] + [0.55 + i * 0.045 for i in range(5)]
    for n, at in enumerate(strikes):
        loud = 1.0 if n in (0, 8) else 0.55
        for f, d, v in ((2093, 6, 1.0), (2150, 6, 0.8), (4410, 11, 0.35), (6300, 16, 0.2)):
            mix_in(track, tone(f, 0.7, d, v * loud, 0.002), at)
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


def buzz():
    """The phone buzzing on the table (Session 31): two short low hums, bzz-bzz."""
    track = silence(0.5)
    for start in (0.0, 0.2):
        hum = array("f")
        for i in range(int(0.14 * RATE)):
            t = i / RATE
            env = min(1.0, t / 0.01) * min(1.0, (0.14 - t) / 0.02)
            wobble = 1.0 + 0.35 * math.sin(2 * math.pi * 31 * t)  # the rattly motor
            hum.append((math.sin(2 * math.pi * 150 * t) + 0.4 * math.sin(2 * math.pi * 300 * t)) * env * wobble)
        mix_in(track, hum, start)
    return track


def pop():
    """A star popping in on the Delivered card (Session 31): a tiny bright blip."""
    track = silence(0.25)
    blip = array("f")
    for i in range(int(0.12 * RATE)):
        t = i / RATE
        freq = 900 + 900 * min(1.0, t / 0.04)  # slides up quickly
        blip.append(math.sin(2 * math.pi * freq * t) * min(1.0, t / 0.003) * math.exp(-t * 30))
    mix_in(track, blip, 0.0)
    mix_in(track, tone(2700, 0.2, 25, 0.3, 0.002), 0.03)
    return track


def coins():
    """Coins flying out of the total (Session 31): a quick sprinkle of little chimes."""
    track = silence(0.8)
    notes = (3136, 3520, 3951, 4186, 3729, 4699, 4186)
    for k, f in enumerate(notes):
        mix_in(track, tone(f, 0.35, 14, 0.7 if k % 2 == 0 else 0.5, 0.002), k * 0.055)
        mix_in(track, tone(f * 1.5, 0.2, 22, 0.2, 0.002), k * 0.055)
    return track


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


def perfect():
    track = silence(0.85)
    for i, note in enumerate([523.25, 659.25, 783.99, 1046.5]):
        mix_in(track, tone(note, 0.32, 9, 0.45), i * 0.13)
    return track


def tip():
    track = silence(0.45)
    for i, note in enumerate([1318.5, 1760.0, 2093.0]):
        mix_in(track, tone(note, 0.18, 20, 0.35), i * 0.09)
    return track


# ---------------- Room sounds (Session 58 and 59) ----------------
# Each walk-in place has its own quiet loop (4 seconds). The game plays it from inside the
# room, so it fades in as you walk through the door. They use their own random numbers, so
# the older sounds above come out exactly the same as before.
ROOM = random.Random(58)


def _hiss(seconds, smooth, volume):
    out = array("f")
    last = 0.0
    for _ in range(int(seconds * RATE)):
        last = last * smooth + ROOM.uniform(-1, 1) * (1 - smooth)
        out.append(last * volume)
    return out


def _pop(volume, bright=0.3):
    """One crackle or sizzle pop: a tiny burst of noise."""
    out = array("f")
    last = 0.0
    for i in range(int(0.03 * RATE)):
        last = last * bright + ROOM.uniform(-1, 1) * (1 - bright)
        out.append(last * math.exp(-i / RATE * 180) * volume)
    return out


def _chatter(track, seconds, voices, volume):
    """Quiet people talking: soft rising and falling hums, like voices through a wall."""
    for _ in range(voices):
        start = ROOM.uniform(0, seconds)
        length = ROOM.uniform(0.5, 1.4)
        base = ROOM.uniform(140, 260)
        voice = array("f")
        for i in range(int(length * RATE)):
            t = i / RATE
            f = base * (1 + 0.12 * math.sin(2 * math.pi * 3.1 * t))
            env = math.sin(math.pi * t / length) * (0.6 + 0.4 * math.sin(2 * math.pi * 7 * t))
            voice.append((math.sin(2 * math.pi * f * t) + 0.4 * math.sin(4 * math.pi * f * t)) * env * volume)
        mix_in(track, voice, start)


def oven_crackle():
    """1000 Pizza: a wood fire's low roar and crackles, with chatter."""
    track = _hiss(4.0, 0.97, 0.5)
    for _ in range(60):
        mix_in(track, _pop(ROOM.uniform(0.3, 0.9)), ROOM.uniform(0, 4))
    _chatter(track, 4.0, 5, 0.05)
    return loop_fade(track, 0.4)


def freezer_hum():
    """Brain Freeze: the gelato case's low hum and a soft click of scoops."""
    track = array("f", (0.25 * math.sin(2 * math.pi * 100 * i / RATE) + 0.1 * math.sin(2 * math.pi * 200 * i / RATE) for i in range(4 * RATE)))
    for k in range(3):
        mix_in(track, tone(1800, 0.05, 60, 0.2), 0.7 + k * 1.3)
    _chatter(track, 4.0, 4, 0.05)
    return loop_fade(track, 0.4)


def espresso():
    """Spill the Brew: the grinder, then the machine's steam wand hissing."""
    track = silence(4.0)
    grind = array("f", (v * (0.6 + 0.4 * math.sin(2 * math.pi * 55 * i / RATE)) for i, v in enumerate(_hiss(0.9, 0.6, 0.6))))
    mix_in(track, grind, 0.2)
    mix_in(track, _hiss(1.4, 0.1, 0.35), 2.0)   # steam
    _chatter(track, 4.0, 6, 0.06)
    return loop_fade(track, 0.4)


def grill_sizzle():
    """Shawarma Supreme, Mario Bonito, Burgerology: meat sizzling on a hot grill."""
    track = _hiss(4.0, 0.2, 0.25)
    for _ in range(140):
        mix_in(track, _pop(ROOM.uniform(0.1, 0.4), 0.1), ROOM.uniform(0, 4))
    _chatter(track, 4.0, 4, 0.05)
    return loop_fade(track, 0.4)


def bakery_chatter():
    """Bread & Zaatar: chatter, the oven's soft roar and a tray now and then."""
    track = _hiss(4.0, 0.98, 0.3)
    _chatter(track, 4.0, 9, 0.08)
    mix_in(track, tone(620, 0.3, 14, 0.15), 1.6)
    return loop_fade(track, 0.4)


def till_beeps():
    """Grand Groceries: checkout beeps, trolley rattles and the fridges' hum."""
    track = array("f", (0.08 * math.sin(2 * math.pi * 120 * i / RATE) for i in range(4 * RATE)))
    for start in [0.3, 0.9, 1.3, 2.6, 3.1]:
        mix_in(track, tone(2400, 0.09, 8, 0.3), start)
    mix_in(track, array("f", (v * 0.5 for v in _hiss(0.6, 0.5, 0.4))), 1.9)
    _chatter(track, 4.0, 3, 0.04)
    return loop_fade(track, 0.4)


def wok_fire():
    """Tok Tok Thai: a roaring wok burner and the clang of the wok."""
    track = _hiss(4.0, 0.9, 0.5)
    for start in [0.4, 1.1, 2.3, 3.0]:
        mix_in(track, tone(950, 0.25, 12, 0.18), start)
    for _ in range(50):
        mix_in(track, _pop(ROOM.uniform(0.1, 0.4), 0.1), ROOM.uniform(0, 4))
    return loop_fade(track, 0.4)


def sushi_belt():
    """Sushi You: the belt's soft whirr and plates clinking."""
    track = array("f", (0.12 * math.sin(2 * math.pi * 80 * i / RATE) * (0.8 + 0.2 * math.sin(2 * math.pi * 2 * i / RATE)) for i in range(4 * RATE)))
    for start in [0.5, 1.7, 2.2, 3.4]:
        mix_in(track, tone(3100, 0.08, 40, 0.2), start)
    _chatter(track, 4.0, 4, 0.05)
    return loop_fade(track, 0.4)


def workshop():
    """Pedal Point Bikes: a freewheel ticking, a spanner clink and a pump."""
    track = silence(4.0)
    for k in range(20):
        mix_in(track, tone(3200, 0.02, 200, 0.25), 0.3 + k * 0.08)
    mix_in(track, tone(1500, 0.2, 25, 0.3), 2.5)
    mix_in(track, _hiss(0.3, 0.3, 0.2), 3.2)
    return loop_fade(track, 0.4)


def shop_music():
    """Dune Drip: a soft, slow pluck tune for the clothes shop."""
    track = silence(4.0)
    for k, note in enumerate([293.66, 369.99, 440.0, 369.99, 329.63, 392.0, 440.0, 293.66]):
        mix_in(track, pluck(note, 0.9, 0.4, 0.3), k * 0.5)
    return loop_fade(track, 0.4)


ROOM_SOUNDS = {"room_oven.wav": oven_crackle, "room_freezer.wav": freezer_hum, "room_espresso.wav": espresso,
               "room_grill.wav": grill_sizzle, "room_bakery.wav": bakery_chatter, "room_tills.wav": till_beeps,
               "room_wok.wav": wok_fire, "room_sushi.wav": sushi_belt, "room_workshop.wav": workshop,
               "room_music.wav": shop_music}


# ---------------- UI sounds (Session 71) ----------------
# Short, soft sounds for menus and the HUD (scripts/ui_sounds.gd plays them by name).
# They use their own random numbers, so every sound above comes out exactly the same.
UI = random.Random(71)


def _ui_noise(seconds, smooth_from, smooth_to, volume):
    """Noise whose 'smoothness' slides from one value to another (a whoosh)."""
    out = array("f")
    last = 0.0
    n = int(seconds * RATE)
    for i in range(n):
        k = i / max(1, n - 1)
        smooth = smooth_from + (smooth_to - smooth_from) * k
        last = last * smooth + UI.uniform(-1, 1) * (1 - smooth)
        env = math.sin(math.pi * k) ** 2   # fades in and out
        out.append(last * env * volume)
    return out


def glide(f_from, f_to, seconds, decay, volume=1.0):
    """A sine that slides in pitch."""
    out = array("f")
    phase = 0.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        f = f_from + (f_to - f_from) * min(1.0, t / seconds)
        phase += 2 * math.pi * f / RATE
        env = min(1.0, t / 0.004) * math.exp(-t * decay)
        out.append(math.sin(phase) * env * volume)
    return out


def ui_hover():
    """A tiny soft tick when the mouse goes over a button."""
    return add(tone(1900, 0.05, 90, 0.6, 0.002), tone(3800, 0.03, 140, 0.15, 0.001))


def ui_click():
    """A click: a short tap with a little body."""
    track = silence(0.09)
    mix_in(track, _ui_noise(0.012, 0.2, 0.2, 0.5), 0.0)
    mix_in(track, tone(1250, 0.08, 55, 0.8, 0.001), 0.0)
    mix_in(track, tone(620, 0.08, 45, 0.5, 0.001), 0.004)
    return track


def ui_open():
    """A panel opens: a short rising swish with a soft note."""
    track = silence(0.26)
    mix_in(track, _ui_noise(0.22, 0.92, 0.55, 0.5), 0.0)
    mix_in(track, glide(520, 880, 0.22, 9, 0.35), 0.02)
    return track


def ui_close():
    """A panel closes: softer and falling."""
    track = silence(0.22)
    mix_in(track, _ui_noise(0.18, 0.6, 0.93, 0.35), 0.0)
    mix_in(track, glide(760, 460, 0.18, 12, 0.25), 0.0)
    return track


def tick():
    """One money tick while a number counts up."""
    return add(tone(2350, 0.04, 120, 0.7, 0.001), tone(4700, 0.025, 200, 0.2, 0.001))


def meter_warn():
    """A meter drops into a worse colour: two short falling blips."""
    track = silence(0.3)
    for i, f in enumerate((700, 520)):
        blip = add(tone(f, 0.12, 22, 0.7, 0.003), tone(f * 2, 0.1, 30, 0.15, 0.003))
        mix_in(track, blip, i * 0.12)
    return track


def level_up():
    """Level up: a quick happy run up, then a bright chord."""
    track = silence(0.85)
    for i, note in enumerate([523.25, 659.25, 783.99]):
        mix_in(track, pluck(note * 2, 0.25, 0.8, 0.5), i * 0.08)
        mix_in(track, tone(note, 0.2, 14, 0.3), i * 0.08)
    for note in (1046.5, 1318.5, 1567.98):
        mix_in(track, tone(note, 0.6, 5.5, 0.3, 0.01), 0.26)
    return track


def stamp():
    """The PERFECT stamp lands: a deep thunk with a papery slap."""
    track = silence(0.32)
    mix_in(track, glide(150, 60, 0.28, 13, 1.0), 0.0)
    mix_in(track, _ui_noise(0.05, 0.35, 0.6, 0.7), 0.0)
    return track


def whoosh():
    """A card slides in: an airy swoosh."""
    return _ui_noise(0.34, 0.97, 0.75, 1.0)


UI_SOUNDS = {"ui_hover": (ui_hover, 0.35), "ui_click": (ui_click, 0.6), "ui_open": (ui_open, 0.5),
             "ui_close": (ui_close, 0.4), "tick": (tick, 0.35), "meter_warn": (meter_warn, 0.6),
             "level_up": (level_up, 0.75), "stamp": (stamp, 0.85), "whoosh": (whoosh, 0.45)}


def make_ui_sounds():
    for key, (make, peak) in UI_SOUNDS.items():
        save(key + ".wav", make(), peak)


if __name__ == "__main__":
    import sys
    if sys.argv[1:] == ["ui"]:   # Session 71: "python3 tools/make_sounds.py ui" makes only the UI sounds
        make_ui_sounds()
        sys.exit(0)
    save("perfect.wav", perfect())
    save("tip.wav", tip())
    save("bell.wav", bell())
    save("cash.wav", cash())
    save("crash.wav", crash())
    save("ping.wav", ping())
    save("bump.wav", bump())
    save("roll_loop.wav", roll_loop(), 0.5)
    save("ambience_loop.wav", ambience_loop(), 0.5)
    save("music_loop.wav", music_loop(), 0.8)
    save("ring.wav", ring())
    save("buzz.wav", buzz())    # Session 31: the phone buzz
    save("pop.wav", pop())      # Session 31: a star pops in
    save("coins.wav", coins())  # Session 31: the coins fly out
    for room_name, make in ROOM_SOUNDS.items():   # Session 58/59: one quiet loop per walk-in place
        save(room_name, make(), 0.5)
    make_ui_sounds()   # Session 71: the menu and HUD sounds
