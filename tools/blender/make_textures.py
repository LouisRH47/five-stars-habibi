"""Session 70: ground textures that tile (repeat with no seams), 512 x 512 pixels, saved in
assets/textures/. How big one picture is in the world is noted next to each one.

    python3 tools/blender/make_textures.py
    blender --background --python tools/blender/make_textures.py
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit  # noqa: E402

SIZE = 512


def speckle(base, flecks, seed, fine=0.55, amount=0.14, fleck_share=0.06):
    """Rubber crumb: a base colour with fine grain, soft patches and coloured flecks."""
    rng = np.random.default_rng(seed)
    grain = rng.random((SIZE, SIZE))
    patches = kit.tile_noise(SIZE, 40.0, seed + 1)
    rgb = np.ones((SIZE, SIZE, 3)) * kit.colour(base)
    rgb *= (1.0 - amount + grain * amount * fine * 2.0 + (patches - 0.5) * 0.08)[..., None]
    pick = rng.random((SIZE, SIZE))
    for i, fleck in enumerate(flecks):
        mask = (pick > 1.0 - fleck_share * (i + 1)) & (pick <= 1.0 - fleck_share * i)
        rgb[mask] = kit.colour(fleck) * (0.9 + 0.2 * grain[mask])[..., None]
    # Crumbs are a couple of pixels big: a tiny wrap-around blur joins single pixels.
    rgb = (rgb * 2 + np.roll(rgb, 1, 0) + np.roll(rgb, 1, 1)) / 4.0
    return rgb


def blue_track():
    """The blue cycle track (about 2 m per picture): blue rubber with paler crumbs."""
    return speckle("#2f69ad", ["#5d92cf", "#1f4e86"], 70)


def red_track():
    """The red walking/running track (about 2 m per picture): terracotta rubber."""
    return speckle("#b5533c", ["#d27a5f", "#8c3a29"], 71)


def horse_sand():
    """Arena and horse-track sand (about 4 m per picture): grain, soft dips and hoof marks."""
    rng = np.random.default_rng(72)
    base = kit.colour("#d6bd8e")
    grain = rng.random((SIZE, SIZE))
    dunes = kit.tile_noise(SIZE, 25.0, 73)
    ripples = kit.tile_noise(SIZE, 6.0, 74)
    shade = 0.9 + (dunes - 0.5) * 0.16 + (ripples - 0.5) * 0.08 + (grain - 0.5) * 0.08
    yy, xx = np.mgrid[0:SIZE, 0:SIZE]
    for _ in range(70):  # hoof prints: small dark half-moons, wrapping round the edges
        cx, cy = rng.integers(0, SIZE, 2)
        dx = (xx - cx + SIZE // 2) % SIZE - SIZE // 2
        dy = (yy - cy + SIZE // 2) % SIZE - SIZE // 2
        r = np.sqrt(dx * dx + dy * dy * 1.4)
        shade -= np.where((r < 9) & (r > 4) & (dy < 3), 0.07, 0.0)
    return np.ones((SIZE, SIZE, 3)) * base * shade[..., None]


def pavers():
    """Interlocking pavers (1.6 m per picture): 20 x 10 cm blocks in two sandy tones."""
    rng = np.random.default_rng(75)
    tones = [kit.colour("#d9c7a6"), kit.colour("#c8b18c"), kit.colour("#bfae95")]
    rgb = np.zeros((SIZE, SIZE, 3))
    rows, cols = 16, 8
    h, w = SIZE // rows, SIZE // cols
    grain = rng.random((SIZE, SIZE))
    for r in range(rows):
        shift = (w // 2) if r % 2 else 0
        for c in range(cols):
            tone = tones[rng.integers(0, len(tones))] * rng.uniform(0.94, 1.04)
            x0 = (c * w + shift) % SIZE
            cols_idx = (np.arange(x0, x0 + w)) % SIZE
            block = np.ones((h, w, 3)) * tone
            # A darker joint round each block and a soft bevel.
            block[:2, :, :] *= 0.62
            block[:, :2, :] *= 0.62
            block[2:4, :, :] *= 0.9
            block[:, 2:4, :] *= 0.9
            block[-2:, :, :] *= 1.05
            rgb[r * h:(r + 1) * h][:, cols_idx] = block
    rgb *= (0.95 + grain * 0.1)[..., None]
    rgb *= (0.96 + kit.tile_noise(SIZE, 30.0, 76) * 0.08)[..., None]
    return rgb


def play_surface():
    """Soft rubber flooring for playgrounds (about 2 m per picture): soft coral with
    sunny yellow, mint and sky-blue flecks."""
    return speckle("#e58b73", ["#f6d06b", "#8fd3b5", "#8cc3ec"], 77, fleck_share=0.05)


def net():
    """Session 72: sports netting (0.5 m per picture, 64 x 64): a white diamond mesh, see-through
    between the strings (the fourth channel is how solid each pixel is)."""
    size = 64
    yy, xx = np.mgrid[0:size, 0:size]
    a = (xx + yy) % 32
    b = (xx - yy) % 32
    string = (np.minimum(a, 32 - a) < 1.6) | (np.minimum(b, 32 - b) < 1.6)
    rgba = np.zeros((size, size, 4))
    rgba[..., :3] = 0.92
    rgba[..., 3] = np.where(string, 1.0, 0.0)
    return rgba


def main():
    kit.reset()
    for name, make in [("blue_track", blue_track), ("red_track", red_track), ("horse_sand", horse_sand),
                       ("pavers", pavers), ("play_surface", play_surface), ("net", net)]:
        kit.save_png(name, make())
        print("wrote assets/textures/%s.png" % name)


main()
