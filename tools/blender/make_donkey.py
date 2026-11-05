"""Session 70: the donkeys for the donkey pen: shorter than a horse, long ears, grey-brown,
a pale muzzle and belly, a dark stripe down the back and a short upright mane.

    python3 tools/blender/make_donkey.py
    blender --background --python tools/blender/make_donkey.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import equine  # noqa: E402
import kit  # noqa: E402

COATS = [("grey", "#8b7f74", "#d6cdbf"), ("brown", "#6f5747", "#cbbca8")]

DONKEY = {
    "scale": 0.72,
    "tack": False,
    "hip_y": 1.1,
    "girth": 1.08,
    "neck_w": 1.12,
    "head_w": 1.25,
    "neck": [(1.45, -0.62, 0.2, 0.3), (1.7, -0.88, 0.17, 0.25), (1.95, -1.05, 0.14, 0.2), (2.14, -1.15, 0.12, 0.17)],
    "head": [(2.12, -1.32, 0.13, 0.16), (1.95, -1.52, 0.11, 0.12), (1.82, -1.66, 0.095, 0.1), (1.77, -1.72, 0.06, 0.06)],
    "ear": 0.42, "ear_w": 1.7, "ear_splay": 0.12,
    "mane_w": 0.025, "mane_h": 0.08, "mane_side": 0.0,
    "forelock": False,
    "tail": [(1.62, 0.96, 0.035, 0.035), (1.45, 1.06, 0.03, 0.03), (1.0, 1.12, 0.025, 0.025), (0.75, 1.1, 0.02, 0.02)],
    "tail_hair": False,
    "tail_tuft": True,
    "front_leg": [(1.25, 0.0, 0.11, 0.15), (0.95, 0.0, 0.085, 0.11), (0.6, -0.02, 0.065, 0.075), (0.36, -0.02, 0.05, 0.055),
                  (0.18, 0.0, 0.055, 0.06), (0.09, -0.03, 0.05, 0.055)],
    "hind_leg": [(1.3, 0.0, 0.12, 0.2), (0.95, 0.07, 0.085, 0.12), (0.62, 0.13, 0.065, 0.08), (0.38, 0.08, 0.05, 0.055),
                 (0.18, 0.05, 0.055, 0.06), (0.09, 0.03, 0.05, 0.055)],
}


def main():
    for i, (name, coat, pale) in enumerate(COATS):
        kit.reset()
        spec = dict(DONKEY, name="donkey_" + name, coat=coat, belly=pale, points=coat, hair="#2f2722",
                    stripe="#3d332c", muzzle=(pale, 0.86), seed=31 + i)
        equine.build(spec)
        kit.export("donkey_%s.glb" % name)


main()
