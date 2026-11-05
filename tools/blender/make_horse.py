"""Session 70: the horses. Makes assets/models/horse_<coat>.glb for each coat colour.

    python3 tools/blender/make_horse.py
    blender --background --python tools/blender/make_horse.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import equine  # noqa: E402
import kit  # noqa: E402

# (name, coat, belly, lower legs, mane and tail, dappled?)
COATS = [
    ("bay", "#7b4a2a", "#5e3820", "#1d1714", "#1a1411", False),
    ("chestnut", "#a35f31", "#874b25", "#8a5129", "#6f3a1a", False),
    ("grey", "#b9b4ad", "#a9a49c", "#7d7873", "#e6e2dc", True),
    ("black", "#2c2624", "#231e1c", "#1a1716", "#141110", False),
    ("palomino", "#d8ad6a", "#c69a58", "#c69a58", "#f1e6c8", False),
]

HORSE = {
    "scale": 1.0,
    "tack": True,
    "hip_y": 1.1,
    "girth": 1.0,
    # neck then head rings: (y, z, half width, half height)
    "neck": [(1.45, -0.62, 0.2, 0.3), (1.76, -0.93, 0.165, 0.24), (2.06, -1.12, 0.13, 0.18), (2.3, -1.24, 0.11, 0.15)],
    "head": [(2.27, -1.4, 0.12, 0.15), (2.08, -1.6, 0.095, 0.11), (1.95, -1.73, 0.08, 0.085), (1.9, -1.79, 0.05, 0.05)],
    "ear": 0.17,
    "mane_w": 0.04, "mane_h": 0.09, "mane_side": 0.035,
    "tail": [(1.62, 0.96, 0.05, 0.05), (1.5, 1.1, 0.09, 0.08), (1.15, 1.2, 0.11, 0.1), (0.78, 1.16, 0.08, 0.07), (0.62, 1.13, 0.03, 0.03)],
    # leg rings: (y, z offset from the hip, half width, half depth)
    "front_leg": [(1.25, 0.0, 0.11, 0.15), (0.95, 0.0, 0.085, 0.11), (0.6, -0.02, 0.06, 0.07), (0.36, -0.02, 0.045, 0.05),
                  (0.18, 0.0, 0.055, 0.06), (0.09, -0.03, 0.05, 0.055)],
    "hind_leg": [(1.3, 0.0, 0.12, 0.2), (0.95, 0.08, 0.08, 0.12), (0.62, 0.16, 0.06, 0.08), (0.38, 0.1, 0.045, 0.05),
                 (0.18, 0.06, 0.055, 0.06), (0.09, 0.03, 0.05, 0.055)],
}


def main():
    for i, (name, coat, belly, points, hair, dapple) in enumerate(COATS):
        kit.reset()
        spec = dict(HORSE, name="horse_" + name, coat=coat, belly=belly, points=points, hair=hair,
                    dapple=dapple, seed=11 + i)
        equine.build(spec)
        kit.export("horse_%s.glb" % name)


main()
