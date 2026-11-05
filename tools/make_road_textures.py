"""Make the road and track textures (World polish pass, Sessions 61 to 63).

Run from any directory: python3 tools/make_road_textures.py
- asphalt_road_1k.jpg: the Poly Haven asphalt_02 photo (CC0) without its long cracks. The
  crack-free middle strip is mirrored side to side, so it still tiles with no seam. The
  repeating cracks were what looked like tyre marks on the roads.
- red_track_1k.jpg: the matte red-brown walking track (made here from noise, CC0).
- bike_track_1k.jpg: the fine rubbery blue track surface with white lane lines (made here, CC0).
The same random seed is used every time, so the files come out the same.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
TEX = ROOT / 'assets/textures'
rng = np.random.default_rng(6163)


def asphalt() -> None:
    photo = np.asarray(Image.open(TEX / 'asphalt_02_diff_1k.jpg').convert('RGB')).astype(np.float32)
    strip = photo[:, 195:485]                     # between the cracks
    tile = np.concatenate([strip, strip[:, ::-1]], axis=1)
    img = Image.fromarray(np.clip(tile * 1.04, 0, 255).astype(np.uint8)).resize((1024, 1024), Image.LANCZOS)
    img.save(TEX / 'asphalt_road_1k.jpg', quality=90)


def grain(size: int, blur: float) -> np.ndarray:
    """Seamless random grain: wrap-around blur of white noise, 0..1."""
    noise = rng.random((size, size)).astype(np.float32)
    big = np.tile(noise, (3, 3))
    img = Image.fromarray((big * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(blur))
    out = np.asarray(img).astype(np.float32)[size:2 * size, size:2 * size] / 255.0
    return (out - out.min()) / max(out.max() - out.min(), 1e-6)


def surface(base, spread, name, lanes=False) -> None:
    size = 512
    fine = grain(size, 0.8)
    soft = grain(size, 6.0)
    value = 0.75 * fine + 0.25 * soft - 0.5
    rgb = np.stack([np.clip(base[i] + value * spread[i], 0, 255) for i in range(3)], axis=-1)
    if lanes:
        # A white lane line down the middle and faint edge lines (u runs across the track).
        for x0, alpha in [(size // 2 - 4, 0.9), (6, 0.55), (size - 14, 0.55)]:
            rgb[:, x0:x0 + 8] = rgb[:, x0:x0 + 8] * (1 - alpha) + 235 * alpha
    Image.fromarray(rgb.astype(np.uint8)).resize((1024, 1024), Image.LANCZOS).save(TEX / name, quality=90)


asphalt()
surface((150, 74, 58), (60, 34, 28), 'red_track_1k.jpg')
surface((46, 112, 170), (42, 40, 44), 'bike_track_1k.jpg', lanes=True)
print('Made asphalt_road_1k.jpg, red_track_1k.jpg and bike_track_1k.jpg')
