"""The horse and donkey builder (Session 70). make_horse.py and make_donkey.py call build().

The model faces -z (Godot), the hooves stand on y = 0. Node names the game looks for:
  Body   the body, neck and head (one mesh)
  Hair   the mane and tail
  Leg_FL, Leg_FR, Leg_HL, Leg_HR   the legs; each pivots at its hip, so the game can swing it
  Tack   saddle, saddle cloth, stirrups and reins (horses only; the game hides it when no rider)
"""
import math

import numpy as np

import kit


def coat_texture(name, body, belly, points, size=64, dapple=False, stripe=None, pale_end=None, seed=1):
    """A small coat picture. u (across) goes round the body (0 = the top), v (down) along it.
    points: the colour low on the legs (bay horses have black legs) - used by the leg texture.
    stripe: a dark line down the back (donkeys). pale_end: (colour, from_v) a pale muzzle."""
    u = np.linspace(0.0, 1.0, size)[None, :].repeat(size, 0)
    v = np.linspace(0.0, 1.0, size)[:, None].repeat(size, 1)
    under = np.clip(((1.0 - np.cos(u * 2.0 * math.pi)) * 0.5 - 0.6) / 0.3, 0.0, 1.0)  # 0 on top and sides, 1 underneath
    rgb = kit.colour(body)[None, None, :] * (1.0 - under[..., None]) + kit.colour(belly)[None, None, :] * under[..., None]
    noise = kit.tile_noise(size, 3.0, seed)
    rgb *= (0.93 + noise * 0.12)[..., None]
    if dapple:
        spots = kit.tile_noise(size, 1.2, seed + 7)
        rgb += (np.clip(spots - 0.55, 0.0, 1.0) * 0.5)[..., None]
    if stripe is not None:
        top = np.minimum(u, 1.0 - u) < 0.035
        rgb[top] = kit.colour(stripe)
    if pale_end is not None:
        pale, start = pale_end
        mix = np.clip((v - start) / 0.06, 0.0, 1.0)[..., None]
        rgb = rgb * (1.0 - mix) + kit.colour(pale)[None, None, :] * mix
    legs = rgb.copy()
    sock = np.clip((v - 0.55) / 0.12, 0.0, 1.0)[..., None]
    legs = legs * (1.0 - sock) + kit.colour(points)[None, None, :] * sock
    # v = 0 is the bottom of a Blender image, so flip the rows before saving.
    return kit.save_png(name, rgb[::-1], kit.SCRATCH), kit.save_png(name + "_legs", legs[::-1], kit.SCRATCH)


def build(spec):
    """spec: the sizes and colours (see make_horse.py / make_donkey.py)."""
    s = spec["scale"]
    body_img, legs_img = coat_texture(spec["name"], spec["coat"], spec["belly"], spec["points"],
                                      dapple=spec.get("dapple", False), stripe=spec.get("stripe"),
                                      pale_end=spec.get("muzzle"), seed=spec.get("seed", 1))
    coat = kit.material("Coat", image=body_img, rough=0.8)
    leg_mat = kit.material("CoatLegs", image=legs_img, rough=0.8)
    hair = kit.material("Hair", kit.colour(spec["hair"]), rough=0.9)
    hoof = kit.material("Hoof", kit.colour(spec.get("hoof", "#2b2420")), rough=0.6)
    eye = kit.material("Eye", (0.03, 0.03, 0.03), rough=0.2)

    def p(x, y, z):
        return np.array([x, y, z]) * s

    # Body: rump to chest. (z, y, half width, half height)
    body_rings = [(p(0, y, z), w * s * spec.get("girth", 1.0), h * s * spec.get("girth", 1.0)) for z, y, w, h in [
        (0.97, 1.4, 0.1, 0.13), (0.88, 1.37, 0.25, 0.29), (0.62, 1.37, 0.31, 0.35), (0.2, 1.33, 0.3, 0.355),
        (-0.2, 1.33, 0.31, 0.37), (-0.55, 1.37, 0.29, 0.37), (-0.8, 1.38, 0.24, 0.31), (-0.92, 1.36, 0.13, 0.18)]]
    parts = [kit.loft("Body", body_rings, coat, sides=10)]
    # Neck and head in one tube: up and forward, then the head angles down to the muzzle.
    neck = [(p(0, y, z), w * s * spec.get("neck_w", 1.0), h * s * spec.get("neck_w", 1.0)) for y, z, w, h in spec["neck"]]
    head = [(p(0, y, z), w * s * spec.get("head_w", 1.0), h * s * spec.get("head_w", 1.0)) for y, z, w, h in spec["head"]]
    parts.append(kit.loft("Head", neck + head, coat, sides=8))
    poll = head[0][0]
    for x in (-1.0, 1.0):
        ear = spec["ear"]
        base = poll + p(x * 0.06, 0.06, 0.06)
        tip = base + p(x * spec.get("ear_splay", 0.03), ear, 0.04)
        parts.append(kit.loft("Ear", [(base, 0.035 * s * spec.get("ear_w", 1.0), 0.03 * s * spec.get("ear_w", 1.0)),
                                      (base + (tip - base) * 0.5, 0.032 * s * spec.get("ear_w", 1.0), 0.026 * s),
                                      (tip, 0.004, 0.004)], coat, sides=5, smooth=False))
        eye_at = head[1][0] + p(x * head[1][1] / s * 0.92, 0.05, 0.03)
        parts.append(kit.box("Eye", (0.03 * s, 0.04 * s, 0.05 * s), eye, centre=tuple(eye_at)))
    kit.join("Body", parts)

    # Mane along the crest of the neck, and the tail.
    hairs = []
    mane_rings = []
    for i, (c, w, h) in enumerate(neck):
        before = neck[max(i - 1, 0)][0]
        after = neck[min(i + 1, len(neck) - 1)][0]
        side, up = kit._frame(after - before)
        top = c + up * h * 0.9
        mane_rings.append((top + np.array([spec.get("mane_side", 0.03) * s, 0.0, 0.0]),
                           spec["mane_w"] * s, spec["mane_h"] * s))
    hairs.append(kit.loft("Mane", mane_rings, hair, sides=6))
    if spec.get("forelock", True):
        hairs.append(kit.loft("Forelock", [(poll + p(0, 0.04, -0.02), 0.05 * s, 0.03 * s),
                                           (poll + p(0, -0.06, -0.14), 0.04 * s, 0.02 * s)], hair, sides=5))
    tail_rings = [(p(0, y, z), w * s, h * s) for y, z, w, h in spec["tail"]]
    hairs.append(kit.loft("Tail", tail_rings, hair if spec.get("tail_hair", True) else coat, sides=6))
    if spec.get("tail_tuft"):
        end = tail_rings[-1][0]
        hairs.append(kit.loft("Tuft", [(end + p(0, 0.05, 0), 0.03 * s, 0.03 * s), (end + p(0, -0.1, 0.01), 0.06 * s, 0.06 * s),
                                       (end + p(0, -0.24, 0.02), 0.01 * s, 0.01 * s)], hair, sides=6))
    kit.join("Hair", hairs)

    # Legs: each pivots at its hip so the game can swing it.
    hip_y = spec["hip_y"]
    for name, x, z, rings in [("Leg_FL", -0.19, -0.6, spec["front_leg"]), ("Leg_FR", 0.19, -0.6, spec["front_leg"]),
                              ("Leg_HL", -0.19, 0.62, spec["hind_leg"]), ("Leg_HR", 0.19, 0.62, spec["hind_leg"])]:
        hip = p(x, hip_y, z)
        leg_rings = [(p(x, y, z + dz), w * s, h * s) for y, dz, w, h in rings]
        leg = kit.loft(name, leg_rings, leg_mat, sides=7, origin=tuple(hip), side_hint=(1.0, 0.0, 0.0))
        bottom = leg_rings[-1][0]
        kit.cylinder(name + "_Hoof", 0.062 * s, 0.1 * s, hoof, centre=tuple(bottom * np.array([1, 0, 1]) + np.array([0, 0.05 * s, -0.01 * s])),
                     sides=7, radius_top=0.052 * s, parent=leg, smooth=False)
        _merge_child(leg)

    if spec.get("tack"):
        _tack(s)


def _merge_child(leg):
    """Joins the hoof into its leg (one mesh per leg, pivot at the hip)."""
    import bpy
    bpy.context.view_layer.update()
    children = [c for c in leg.children]
    for c in children:
        world = c.matrix_world.copy()
        c.parent = None
        c.matrix_world = world
    kit.join(leg.name, [leg] + children)


def _tack(s):
    cloth = kit.material("SaddleCloth", (0.93, 0.93, 0.88), rough=0.9)
    leather = kit.material("Leather", (0.3, 0.17, 0.08), rough=0.55)
    metal = kit.material("Steel", (0.75, 0.76, 0.78), rough=0.3)
    parts = []
    rings = [((0, 1.33, z), w, h) for z, w, h in [(0.28, 0.335, 0.395), (0.0, 0.335, 0.39), (-0.3, 0.335, 0.395)]]
    parts.append(kit.shell("Cloth", rings, cloth, arc=(-0.2, 0.2), steps=8))
    parts.append(kit.box("Saddle", (0.38, 0.09, 0.52), leather, centre=(0, 1.73, 0.0), bevel=0.03))
    parts.append(kit.box("Cantle", (0.3, 0.1, 0.07), leather, centre=(0, 1.79, 0.24), bevel=0.02))
    parts.append(kit.box("Pommel", (0.24, 0.09, 0.07), leather, centre=(0, 1.78, -0.24), bevel=0.02))
    for x in (-1.0, 1.0):
        parts.append(kit.tube("Leather", [(x * 0.34, 1.62, -0.05), (x * 0.36, 1.12, -0.1)], 0.012, leather, sides=4))
        parts.append(kit.box("Stirrup", (0.1, 0.07, 0.12), metal, centre=(x * 0.36, 1.07, -0.1)))
        parts.append(kit.tube("Rein", [(x * 0.075, 1.97, -1.64), (x * 0.1, 2.02, -1.2), (x * 0.12, 1.95, -0.52)], 0.012, leather, sides=4))
        parts.append(kit.tube("Cheek", [(x * 0.118, 2.27, -1.36), (x * 0.1, 2.1, -1.56), (x * 0.087, 1.97, -1.66)], 0.012, leather, sides=4))
    parts.append(kit.tube("Girth", [(-0.31, 1.3, -0.25), (-0.2, 1.0, -0.27), (0.2, 1.0, -0.27), (0.31, 1.3, -0.25)], 0.03, leather, sides=4))
    kit.join("Tack", parts)
