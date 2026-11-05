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


# ---------------- Room sounds (looks pass, Sessions 54 and 55) ----------------
# Each walk-in place has its own quiet background loop, heard only inside and at the door.
# They are 5 seconds long (small files) and made from the same noise and tone recipes.
ROOM_SECONDS = 5.0
room_random = random.Random(54)  # its own dice, so the older sounds above stay the same


def r_noise(seconds, decay, smooth=0.0, volume=1.0):
    out = array("f")
    last = 0.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        last = last * smooth + room_random.uniform(-1, 1) * (1 - smooth)
        out.append(last * math.exp(-t * decay) * volume)
    return out


def chatter(seconds=ROOM_SECONDS, volume=0.35):
    """Quiet people talking: soft murmur plus little voice-like hums that rise and fall."""
    track = r_noise(seconds, 0, 0.97, volume * 0.8)
    for _ in range(int(seconds * 3)):
        start = room_random.uniform(0, seconds)
        base = room_random.uniform(130, 260)
        length = room_random.uniform(0.2, 0.6)
        voice = array("f")
        for i in range(int(length * RATE)):
            t = i / RATE
            env = math.sin(math.pi * t / length) ** 2
            f = base * (1 + 0.08 * math.sin(2 * math.pi * 5 * t))
            voice.append((math.sin(2 * math.pi * f * t) + 0.4 * math.sin(4 * math.pi * f * t)) * env * volume * 0.12)
        mix_in(track, voice, start)
    return track


def hum(freq, seconds=ROOM_SECONDS, volume=0.3):
    """A fridge or motor humming."""
    out = array("f")
    for i in range(int(seconds * RATE)):
        t = i / RATE
        out.append((math.sin(2 * math.pi * freq * t) + 0.5 * math.sin(4 * math.pi * freq * t)) * volume)
    return out


def sizzle(seconds=ROOM_SECONDS, volume=0.5):
    """Hot food on a grill: bright hiss that swells, with tiny pops."""
    out = r_noise(seconds, 0, 0.1, 1.0)
    for i in range(len(out)):
        t = i / RATE
        out[i] *= volume * (0.55 + 0.45 * math.sin(2 * math.pi * 0.7 * t) ** 2)
    for _ in range(int(seconds * 25)):
        mix_in(out, r_noise(0.01, 300, 0.0, volume * 1.5), room_random.uniform(0, seconds))
    return out


def crackle(seconds=ROOM_SECONDS, volume=0.6):
    """A wood fire: a low rumble and sharp little crackles."""
    out = r_noise(seconds, 0, 0.99, volume)
    for _ in range(int(seconds * 14)):
        mix_in(out, r_noise(0.03, 120, 0.3, volume * room_random.uniform(0.6, 2.0)), room_random.uniform(0, seconds))
    return out


def clinks(track, count, low=2200, high=3600, volume=0.25):
    """Plates, cups and trays touching now and then."""
    for _ in range(count):
        at = room_random.uniform(0, ROOM_SECONDS)
        f = room_random.uniform(low, high)
        mix_in(track, tone(f, 0.3, 22, volume), at)
        mix_in(track, tone(f * 1.5, 0.2, 30, volume * 0.5), at)
    return track


def room(*parts):
    return loop_fade(add(*parts), 0.5)


def room_pizza():
    return room(chatter(), crackle(), clinks(silence(ROOM_SECONDS), 3))


def room_gelato():
    scoops = silence(ROOM_SECONDS)
    for k in range(3):  # the scoop scraping the tub
        mix_in(scoops, r_noise(0.35, 6, 0.6, 0.35), 0.6 + k * 1.6)
    return room(chatter(), hum(55, volume=0.12), scoops)


def room_boba():
    shaker = silence(ROOM_SECONDS)
    for k in range(10):  # shaking a cup of tea with ice
        mix_in(shaker, r_noise(0.06, 40, 0.2, 0.4), 0.3 + k * 0.12)
    for at in (2.6, 4.0):  # the cup sealer: a clunk and a hiss
        mix_in(shaker, tone(140, 0.2, 18, 0.6), at)
        mix_in(shaker, r_noise(0.3, 8, 0.1, 0.25), at + 0.05)
    return room(chatter(), shaker)


def room_shawarma():
    chops = silence(ROOM_SECONDS)
    for k in range(6):  # slicing the meat off the grill
        mix_in(chops, r_noise(0.05, 60, 0.4, 0.5), 1.0 + k * 0.28)
    return room(chatter(), sizzle(volume=0.3), chops)


def room_bakery():
    return room(chatter(volume=0.4), hum(98, volume=0.08), r_noise(ROOM_SECONDS, 0, 0.9, 0.15),
                clinks(silence(ROOM_SECONDS), 4, 1800, 2600, 0.3))


def room_thai():
    wok = silence(ROOM_SECONDS)
    for at in (0.2, 2.4):  # food hits the hot wok: whoosh
        mix_in(wok, sizzle(1.6, 0.7), at)
    for at in (1.2, 1.5, 3.8, 4.1):  # the ladle on the wok
        mix_in(wok, tone(620, 0.4, 14, 0.4), at)
        mix_in(wok, tone(1530, 0.3, 20, 0.2), at)
    return room(chatter(), wok)


def room_sushi():
    belt = hum(75, volume=0.1)
    for i in range(len(belt)):  # the belt motor wobbles a little
        belt[i] *= 0.8 + 0.2 * math.sin(2 * math.pi * 2 * i / RATE)
    clacks = silence(ROOM_SECONDS)
    for k in range(10):  # plates clicking over the belt joints
        mix_in(clacks, tone(1900, 0.08, 60, 0.18), k * 0.5)
    return room(chatter(volume=0.28), belt, clacks)


def room_tacos():
    guitar = silence(ROOM_SECONDS)
    notes = [196.0, 246.9, 293.7, 246.9, 220.0, 261.6, 329.6, 261.6]
    for k, f in enumerate(notes):  # a soft strummed guitar in the back
        mix_in(guitar, pluck(f, 0.9, 0.5, 0.35), k * 0.6)
    return room(chatter(), guitar)


def room_burger():
    fryer = silence(ROOM_SECONDS)
    for _ in range(60):  # oil bubbling in the fryer
        mix_in(fryer, tone(room_random.uniform(200, 500), 0.05, 50, 0.12), room_random.uniform(0, ROOM_SECONDS))
    return room(chatter(), sizzle(volume=0.35), fryer)


def room_market():
    beeps = silence(ROOM_SECONDS)
    for at in (0.4, 1.6, 2.1, 3.7):  # the till beeping at the checkout
        mix_in(beeps, tone(1850, 0.09, 8, 0.35), at)
    rattle = silence(ROOM_SECONDS)
    for k in range(18):  # a trolley rolling past
        mix_in(rattle, r_noise(0.04, 50, 0.3, 0.12), 2.6 + k * 0.07)
    return room(chatter(volume=0.25), hum(60, volume=0.12), beeps, rattle)


ROOM_SOUNDS = {"pizza": room_pizza, "gelato": room_gelato, "boba": room_boba, "shawarma": room_shawarma,
               "bakery": room_bakery, "thai": room_thai, "sushi": room_sushi, "tacos": room_tacos,
               "burger": room_burger, "market": room_market}


if __name__ == "__main__":
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
    for kind, make in ROOM_SOUNDS.items():  # looks pass: each place's background sound
        save("room_%s.wav" % kind, make(), 0.6)
