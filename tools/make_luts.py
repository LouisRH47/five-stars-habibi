"""Session 67: makes the colour grade LUTs (look-up tables) for the "Golden" and "Fresh" looks.

A LUT is a little cube of colours: for every colour on screen it says which colour to show
instead. Godot reads it as a 3D texture (Environment "adjustment_color_correction"). Ours is
33 x 33 x 33, saved as one strip picture 1089 x 33 px: 33 squares side by side, one per amount
of blue; in each square red goes left to right and green top to bottom.

Nothing is downloaded, so they're ours to use (CC0, made for this game). Run from the
project folder:

    python3 tools/make_luts.py

Writes assets/luts/neutral.png (no change), golden.png and fresh.png.
The grades work on the finished picture (after the tone mapping, in screen colours 0 to 1).
"""
from pathlib import Path

import numpy as np
from PIL import Image

SIZE = 33
OUT = Path(__file__).resolve().parent.parent / "assets" / "luts"

# Godot looks up the cube with the colour as it is (0 = the first square's edge, 1 = the last
# square's edge), so square i is read for colours around (i + 0.5) / 33. We store the graded
# colour for exactly that input, so "neutral" really changes nothing (checked in Godot:
# tests/look_polish_test.gd compares a picture with and without it).
# The two end squares hold pure black and pure white, so black stays black and white stays white.
CENTRES = (np.arange(SIZE) + 0.5) / SIZE
CENTRES[0], CENTRES[-1] = 0.0, 1.0

# Each look: how much to lift the shadows (red, green, blue added in the dark parts), how to
# tint the highlights (red, green, blue multiplied in the bright parts), how much S-curve
# (contrast in the middle), and a little extra colour for dull colours only (vibrance).
LOOKS = {
    "neutral": {"lift": (0.0, 0.0, 0.0), "gain": (1.0, 1.0, 1.0), "curve": 0.0, "vibrance": 0.0},
    # Warm and golden: sunny parts warmer, shade a little teal, a tiny S-curve.
    "golden": {"lift": (-0.006, 0.012, 0.022), "gain": (1.04, 1.0, 0.95), "curve": 0.16, "vibrance": 0.06},
    # Fresh: cleaner and brighter, only a hint of warmth, a little more pop in dull colours.
    "fresh": {"lift": (-0.004, 0.008, 0.016), "gain": (1.012, 1.004, 0.99), "curve": 0.12, "vibrance": 0.12},
}


def grade(rgb, look):
    """Grades an array of colours (..., 3) in 0 to 1 screen colours."""
    luma = rgb @ np.array([0.2126, 0.7152, 0.0722])
    shadows = (1.0 - np.clip(luma / 0.5, 0.0, 1.0)) ** 1.5           # 1 in the dark, 0 from mid-grey up
    highs = np.clip((luma - 0.4) / 0.6, 0.0, 1.0)
    highs = highs * highs * (3.0 - 2.0 * highs)                       # smooth 0 to 1 over the bright half
    out = rgb + shadows[..., None] * np.array(look["lift"])
    out = out * (1.0 + highs[..., None] * (np.array(look["gain"]) - 1.0))
    # Vibrance: more colour for colours that aren't very colourful yet (skin, sand), less for strong ones.
    grey = (out @ np.array([0.2126, 0.7152, 0.0722]))[..., None]
    chroma = out.max(axis=-1, keepdims=True) - out.min(axis=-1, keepdims=True)
    out = grey + (out - grey) * (1.0 + look["vibrance"] * (1.0 - np.clip(chroma * 2.0, 0.0, 1.0)))
    # A gentle S-curve: a touch darker darks and brighter brights, the ends stay put.
    out = np.clip(out, 0.0, 1.0)
    s = out * out * (3.0 - 2.0 * out)
    out = out + (s - out) * look["curve"]
    return np.clip(out, 0.0, 1.0)


def strip(look):
    """The 1089 x 33 picture: x = blue square * 33 + red, y = green."""
    r = CENTRES[None, None, :]                 # across inside a square
    g = CENTRES[None, :, None]                 # down
    b = CENTRES[:, None, None]                 # which square
    cube = np.stack(np.broadcast_arrays(r, g, b), axis=-1)  # [blue, green, red, 3]
    graded = grade(cube, look)
    # Lay the squares side by side: rows = green, columns = blue square then red.
    picture = graded.transpose(1, 0, 2, 3).reshape(SIZE, SIZE * SIZE, 3)
    return np.round(picture * 255.0).astype(np.uint8)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, look in LOOKS.items():
        Image.fromarray(strip(look), "RGB").save(OUT / f"{name}.png", optimize=True)
        print(f"wrote assets/luts/{name}.png")


if __name__ == "__main__":
    main()
