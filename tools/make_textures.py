"""Session 55: makes the clean, cartoony ground textures (the "Schedule I look").

Each texture is a flat colour with soft painted variation, made from random noise that is
blurred so it tiles with no seams (the blur wraps round the edges). Nothing is downloaded,
so they're ours to use (CC0, made for this game). Run from the project folder:

    python3 tools/make_textures.py

Writes assets/textures/stylized/*.png (1024 x 1024). One texture covers 2 m of ground
(terrain_materials.gd sets the scale), except grass and sand which cover 5 m.
"""
from pathlib import Path

import numpy as np
from PIL import Image

SIZE = 1024
OUT = Path(__file__).resolve().parent.parent / "assets" / "textures" / "stylized"


def blurred_noise(rng, size, softness):
    """Random noise blurred by `softness` pixels; wraps round, so it tiles."""
    noise = rng.standard_normal((size, size))
    fx = np.fft.fftfreq(size)[:, None]
    fy = np.fft.fftfreq(size)[None, :]
    blur = np.exp(-(fx * fx + fy * fy) * (2.0 * np.pi * softness) ** 2 / 2.0)
    soft = np.real(np.fft.ifft2(np.fft.fft2(noise) * blur))
    soft -= soft.mean()
    return soft / (soft.std() + 1e-9)


def mix(colour_a, colour_b, t):
    t = np.clip(t, 0.0, 1.0)[..., None]
    return np.array(colour_a, float) * (1.0 - t) + np.array(colour_b, float) * t


def save(name, rgb):
    OUT.mkdir(parents=True, exist_ok=True)
    image = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB")
    image.save(OUT / f"{name}.png", optimize=True)
    print("made", OUT / f"{name}.png")


def painted(rng, dark, light, big=60.0, small=12.0, grain=0.0, mid=0.5, spread=0.22):
    """Two colours mixed by big soft patches plus smaller dabs (and an optional fine grain)."""
    t = mid + spread * (0.7 * blurred_noise(rng, SIZE, big) + 0.3 * blurred_noise(rng, SIZE, small))
    rgb = mix(dark, light, t)
    if grain:
        rgb += rng.standard_normal((SIZE, SIZE, 1)) * grain
    return rgb


def grass(rng):
    # Lawn under the grass blades: two clean greens, soft patches, a hint of yellow.
    rgb = painted(rng, (70, 120, 48), (112, 158, 66), big=90.0, small=18.0, spread=0.25)
    yellow = np.clip(blurred_noise(rng, SIZE, 40.0) - 1.2, 0.0, 1.0)[..., None]
    return rgb * (1 - 0.35 * yellow) + np.array([186, 186, 92]) * 0.35 * yellow


def sand(rng):
    rgb = painted(rng, (214, 188, 140), (238, 216, 172), big=110.0, small=24.0, spread=0.2)
    # Gentle wind ripples running across.
    y = np.arange(SIZE)[:, None] / SIZE
    x = np.arange(SIZE)[None, :] / SIZE
    ripple = np.sin((y * 9 + 0.15 * np.sin(x * 2 * np.pi * 2)) * 2 * np.pi)
    return rgb + ripple[..., None] * 2.5


def asphalt(rng):
    # Dark grey with a fine grain and a few lighter stones, no cracks or stains.
    rgb = painted(rng, (84, 86, 90), (100, 102, 106), big=80.0, small=10.0, grain=5.0, spread=0.2)
    stones = rng.random((SIZE, SIZE)) > 0.996
    rgb[stones] += 30
    return rgb


def paving(rng):
    # Light rectangular pavers, 0.5 x 0.25 m, in a running bond with thin soft joints.
    rgb = painted(rng, (222, 206, 178), (236, 224, 200), big=70.0, small=14.0, grain=2.0, spread=0.25)
    per_metre = SIZE / 2.0
    w, h = int(per_metre * 0.5), int(per_metre * 0.25)
    y, x = np.mgrid[0:SIZE, 0:SIZE]
    row = y // h
    shifted = (x + (row % 2) * (w // 2)) % SIZE
    col = shifted // w
    # Each paver a tiny bit lighter or darker.
    tint = rng.uniform(-8, 8, size=(row.max() + 1, col.max() + 1))
    rgb += tint[row, col][..., None]
    joint = (np.minimum(y % h, h - 1 - y % h) < 2) | (np.minimum(shifted % w, w - 1 - shifted % w) < 2)
    rgb[joint] = rgb[joint] * 0.78
    return rgb


def track(rng):
    # The red rubber walking track: red with fine rubber specks.
    rgb = painted(rng, (176, 66, 52), (196, 82, 64), big=60.0, small=8.0, grain=7.0, spread=0.2)
    specks = rng.random((SIZE, SIZE)) > 0.985
    rgb[specks] = rgb[specks] * 0.7 + np.array([60, 40, 36]) * 0.3
    return rgb


def main():
    rng = np.random.default_rng(55)
    for name, make in [("grass", grass), ("sand", sand), ("asphalt", asphalt),
                       ("paving", paving), ("track", track)]:
        save(name, make(rng))


if __name__ == "__main__":
    main()
