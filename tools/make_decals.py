#!/usr/bin/env python3
"""Session 68: makes the road wear pictures (decals, ours, CC0) in assets/textures/decals/.

Each is a PNG with see-through parts. scripts/road_decals.gd lays them on the roads and car parks:
  tyre_arc.png    dark curved tyre marks (junctions)
  oil_spot.png    a dark oily stain (empty car park bays)
  manhole.png     a round iron cover (ring road)
  drain.png       a drain grate (ring road edge)
  crack.png       thin cracks in the asphalt
  patch.png       a repaired patch of asphalt
  sand_drift.png  pale sand blown onto the road edge (the top edge of the picture is the kerb)
  slow_ar_en.png  faded road paint "SLOW" with the Arabic "ببطء" above (near the school)
  zebra.png       a faded zebra crossing (at the school gate)
The Arabic is shaped with Pillow's text layout (raqm) and the game's Noto Sans Arabic font, so
the letters join and read right to left. Run: python3 tools/make_decals.py
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont, features

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "textures", "decals")
FONTS = os.path.join(HERE, "..", "assets", "fonts")


def noise_layer(w, h, scale, seed):
    """Soft value noise 0..1 (a small random grid blown up and blurred)."""
    rng = random.Random(seed)
    small = Image.new("L", (max(2, w // scale), max(2, h // scale)))
    small.putdata([rng.randint(0, 255) for _ in range(small.size[0] * small.size[1])])
    return small.resize((w, h), Image.BICUBIC).filter(ImageFilter.GaussianBlur(scale * 0.3))


def with_alpha(colour, alpha):
    img = Image.new("RGBA", alpha.size, colour)
    img.putalpha(alpha)
    return img


def tyre_arc():
    w, h = 256, 256
    a = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(a)
    rng = random.Random(3)
    for track in range(4):
        r = 150 + track * 16 + rng.randint(-4, 4)
        width = rng.randint(7, 11)
        start, end = 185 + rng.randint(-8, 8), 265 + rng.randint(-10, 10)
        d.arc((w - r, h - r, w + r, h + r), start, end, fill=150 + rng.randint(-25, 25), width=width)
    a = a.filter(ImageFilter.GaussianBlur(1.6))
    grain = noise_layer(w, h, 6, 4)
    a = Image.composite(a, Image.new("L", (w, h), 0), grain.point(lambda v: 255 if v > 70 else int(v * 2.5)))
    return with_alpha((20, 20, 22), a)


def oil_spot():
    w = h = 128
    a = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(a)
    rng = random.Random(9)
    for _ in range(7):
        r = rng.randint(14, 34)
        x, y = 64 + rng.randint(-22, 22), 64 + rng.randint(-26, 26)
        d.ellipse((x - r, y - r * 0.8, x + r, y + r * 0.8), fill=rng.randint(90, 150))
    a = a.filter(ImageFilter.GaussianBlur(5))
    return with_alpha((24, 20, 18), a)


def manhole():
    w = h = 128
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((4, 4, 124, 124), fill=(70, 70, 72, 255))
    d.ellipse((10, 10, 118, 118), fill=(92, 92, 94, 255))
    for i in range(-5, 6):   # a grid of raised squares
        for j in range(-5, 6):
            x, y = 64 + i * 9, 64 + j * 9
            if math.hypot(i * 9, j * 9) < 48:
                d.rectangle((x - 3, y - 3, x + 3, y + 3), fill=(110, 110, 112, 255))
    d.ellipse((50, 50, 78, 78), outline=(60, 60, 62, 255), width=3)
    grime = noise_layer(w, h, 8, 12)
    shade = Image.merge("RGBA", (grime, grime, grime, Image.new("L", (w, h), 255)))
    img = Image.blend(img, Image.composite(shade, img, img.getchannel("A")), 0.18)
    return img


def drain():
    w, h = 128, 64
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((2, 2, w - 3, h - 3), fill=(80, 82, 84, 255))
    for x in range(10, w - 10, 10):
        d.rectangle((x, 9, x + 4, h - 10), fill=(18, 18, 20, 255))
    return img


def crack():
    w = h = 256
    a = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(a)
    rng = random.Random(21)

    def branch(x, y, angle, length, width):
        for _ in range(int(length / 8)):
            angle += rng.uniform(-0.5, 0.5)
            nx, ny = x + math.cos(angle) * 8, y + math.sin(angle) * 8
            d.line((x, y, nx, ny), fill=200, width=max(1, int(width)))
            x, y = nx, ny
            width *= 0.97
            if rng.random() < 0.12 and length > 40:
                branch(x, y, angle + rng.choice([-1, 1]) * rng.uniform(0.6, 1.1), length * 0.4, width * 0.7)

    branch(20, 128, 0.0, 230, 3.2)
    a = a.filter(ImageFilter.GaussianBlur(0.7))
    return with_alpha((15, 15, 16), a)


def patch():
    w = h = 256
    a = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(a)
    rng = random.Random(30)
    pts = []
    for i in range(14):
        ang = i / 14 * math.tau
        r = 95 + rng.randint(-14, 10)
        pts.append((128 + math.cos(ang) * r * 1.1, 128 + math.sin(ang) * r * 0.75))
    d.polygon(pts, fill=150)
    a = a.filter(ImageFilter.GaussianBlur(2))
    grain = noise_layer(w, h, 10, 31)
    a = Image.composite(a, a.point(lambda v: int(v * 0.75)), grain.point(lambda v: 255 if v > 128 else 0))
    return with_alpha((38, 38, 41), a)


def sand_drift():
    """Thick at the top edge (the kerb), thinning into the road in soft wavy tongues."""
    w, h = 512, 128
    rng = random.Random(44)
    a = Image.new("L", (w, h), 0)
    px = a.load()
    n = noise_layer(w, h, 16, 45).load()
    fine = noise_layer(w, h, 4, 46).load()
    phase = [rng.uniform(0, math.tau) for _ in range(3)]
    for x in range(w):
        u = x / (w - 1)
        ends = math.sin(u * math.pi) ** 0.6   # thin at both ends
        reach = ends * (0.62 + 0.2 * math.sin(u * 7 + phase[0]) + 0.1 * math.sin(u * 19 + phase[1]))
        for y in range(h):
            v = y / (h - 1)
            depth = reach - v + (n[x, y] / 255 - 0.5) * 0.18
            if depth <= 0:
                continue
            ripple = 0.93 + 0.07 * math.sin(v * 30 + u * 5 + phase[2])
            px[x, y] = int(min(1.0, depth * 2.2) * 200 * ripple * (0.85 + 0.15 * fine[x, y] / 255))
    a = a.filter(ImageFilter.GaussianBlur(1.2))
    return with_alpha((226, 204, 160), a)


def worn(alpha, seed, keep=0.88):
    """Road paint that's been driven over: holes in it."""
    grain = noise_layer(alpha.size[0], alpha.size[1], 3, seed)
    holes = grain.point(lambda v: 255 if v > 255 * (1 - keep) else 0)
    out = Image.composite(alpha, Image.new("L", alpha.size, 0), holes)
    return out.point(lambda v: int(v * 0.8))


def slow_ar_en():
    """'SLOW' in English with the Arabic above it, stretched long like real road writing."""
    w, h = 512, 512
    a = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(a)
    latin = ImageFont.truetype(os.path.join(FONTS, "Nunito.ttf"), 150)
    try:
        latin.set_variation_by_axes([900])
    except Exception:
        pass
    arabic = ImageFont.truetype(os.path.join(FONTS, "NotoSansArabic.ttf"), 150,
                                layout_engine=ImageFont.Layout.RAQM)
    try:
        arabic.set_variation_by_axes([800, 100])
    except Exception:
        pass
    d.text((w / 2, 140), "ببطء", font=arabic, fill=255, anchor="mm", direction="rtl", language="ar")
    d.text((w / 2, 380), "SLOW", font=latin, fill=255, anchor="mm")
    return with_alpha((244, 244, 238), worn(a, 51))


def zebra():
    w, h = 512, 256
    a = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(a)
    stripes = 8
    for i in range(stripes):
        x = int((i + 0.25) * w / stripes)
        d.rectangle((x, 6, x + int(w / stripes * 0.5), h - 6), fill=255)
    return with_alpha((244, 244, 238), worn(a, 61, 0.8))


def main():
    if not features.check("raqm"):
        raise SystemExit("Pillow needs raqm (complex text layout) to shape the Arabic")
    os.makedirs(OUT, exist_ok=True)
    pictures = {
        "tyre_arc.png": tyre_arc(), "oil_spot.png": oil_spot(), "manhole.png": manhole(),
        "drain.png": drain(), "crack.png": crack(), "patch.png": patch(),
        "sand_drift.png": sand_drift(), "slow_ar_en.png": slow_ar_en(), "zebra.png": zebra(),
    }
    for name, img in pictures.items():
        img.save(os.path.join(OUT, name), optimize=True)
    print("made %d decals in %s" % (len(pictures), os.path.normpath(OUT)))


if __name__ == "__main__":
    main()
