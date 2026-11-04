#!/usr/bin/env python3
"""Session 68: makes the little particle pictures (our own, CC0) in assets/textures/vfx/.

All are white with see-through edges, so the game can tint them any colour:
  soft_dot.png  a soft round blob (dust, steam, spray, mist)
  wisp.png      a long soft streak (sand blowing, steam wisps)
  leaf.png      a small leaf shape
  droplet.png   a water drop with a bright spot
  sparkle.png   a four-pointed star (the delivery beam, bursts)
Run: python3 tools/make_vfx_textures.py
"""
import math
import os

from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures", "vfx")


def save(name, size, alpha_at):
    img = Image.new("RGBA", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            u = (x + 0.5) / size * 2.0 - 1.0
            v = (y + 0.5) / size * 2.0 - 1.0
            a = max(0.0, min(1.0, alpha_at(u, v)))
            px[x, y] = (255, 255, 255, int(round(a * 255)))
    img.save(os.path.join(OUT, name))


def smooth(edge0, edge1, x):
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3 - 2 * t)


def soft_dot(u, v):
    r = math.hypot(u, v)
    return (1.0 - smooth(0.0, 1.0, r)) ** 1.6


def wisp(u, v):
    r = math.hypot(u * 0.35, v * 1.6)
    return (1.0 - smooth(0.0, 1.0, r)) ** 1.4


def leaf(u, v):
    # A pointed oval along a slanted line, with a thin darker middle vein (lower alpha).
    a = math.radians(35)
    x = u * math.cos(a) - v * math.sin(a)
    y = u * math.sin(a) + v * math.cos(a)
    width = 0.42 * (1.0 - x * x) if abs(x) < 1.0 else 0.0
    inside = 1.0 - smooth(width - 0.08, width, abs(y)) if width > 0 else 0.0
    vein = 0.25 * (1.0 - smooth(0.0, 0.05, abs(y)))
    return inside * (1.0 - vein) * (1.0 - smooth(0.85, 0.95, abs(x)))


def droplet(u, v):
    # Round at the bottom, pointed at the top.
    y = v + 0.25
    r = math.hypot(u * (1.0 + max(0.0, -y) * 1.8), y)
    body = 1.0 - smooth(0.45, 0.6, r)
    return body * (0.75 + 0.25 * (1.0 - smooth(0.0, 0.2, math.hypot(u + 0.12, y + 0.12))))


def sparkle(u, v):
    r = math.hypot(u, v)
    rays = max(1.0 - smooth(0.0, 0.12, abs(u)) , 1.0 - smooth(0.0, 0.12, abs(v)))
    rays *= 1.0 - smooth(0.2, 1.0, r)
    core = (1.0 - smooth(0.0, 0.35, r)) ** 1.5
    return max(rays, core)


def main():
    os.makedirs(OUT, exist_ok=True)
    save("soft_dot.png", 64, soft_dot)
    save("wisp.png", 64, wisp)
    save("leaf.png", 32, leaf)
    save("droplet.png", 32, droplet)
    save("sparkle.png", 64, sparkle)
    print("made 5 pictures in", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
