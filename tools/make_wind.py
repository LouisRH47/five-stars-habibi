"""Generate the riding wind loop from deterministic filtered noise (original CC0 audio).

Run python3 tools/make_wind.py. No source recordings or external libraries are used.
"""
from array import array
from pathlib import Path
import math
import random
import wave

RATE = 22050
SECONDS = 4.0


def build_wind():
    rng = random.Random(44)
    count = int(RATE * SECONDS)
    samples = []
    soft = 0.0
    low = 0.0
    # Pre-roll the filters so the loop starts with a settled noise bed.
    for i in range(-RATE, count):
        raw = rng.uniform(-1.0, 1.0)
        soft = soft * 0.82 + raw * 0.18
        low = low * 0.985 + raw * 0.015
        if i >= 0:
            phase = i / count * math.tau
            gust = 0.85 + 0.08 * math.sin(phase * 2) + 0.04 * math.sin(phase * 5)
            samples.append((soft * 0.8 + low * 1.8) * gust)
    # Equal-power overlap removes the discontinuity at the loop boundary.
    overlap = int(RATE * 0.3)
    loop = samples[:-overlap]
    for i in range(overlap):
        t = i / overlap
        loop[i] = samples[-overlap + i] * math.cos(t * math.pi / 2) + loop[i] * math.sin(t * math.pi / 2)
    peak = max(abs(value) for value in loop)
    pcm = array('h', (round(value / peak * 18000) for value in loop))
    output = Path(__file__).resolve().parent.parent / 'assets/audio/wind_loop.wav'
    output.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(output), 'wb') as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(RATE)
        sound.writeframes(pcm.tobytes())
    print(f'Generated {output.name}: {len(loop) / RATE:.1f}s, original CC0 filtered noise')


if __name__ == '__main__':
    build_wind()
