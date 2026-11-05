"""Session 71: rounded playground pieces in bright, soft colours. Each piece is one .glb in
assets/models/ (one material; the colours are painted on the mesh, so each is one draw):

  play_slide.glb    a round-posted tower with a cone roof, a ladder and a curved slide
                    (the slide comes down towards +x)
  play_swings.glb   an arched swing frame; the seats are Seat_0 and Seat_1, each pivots on
                    the top bar so the game can swing them
  play_climber.glb  a climbing dome of curved bars
  play_spinner.glb  a small roundabout; "Spin" is the part that turns
  play_springer.glb a spring rider (a little camel); "Rider" is the part that rocks

    python3 tools/blender/make_playground.py
    blender --background --python tools/blender/make_playground.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit  # noqa: E402

CORAL = (0.95, 0.55, 0.47)
SUNNY = (0.98, 0.82, 0.38)
MINT = (0.56, 0.84, 0.71)
SKY = (0.5, 0.75, 0.92)
LILAC = (0.73, 0.64, 0.89)
CREAM = (1.0, 0.95, 0.86)
GREY = (0.55, 0.57, 0.6)


def painted(obj, rgb):
    return kit.paint(obj, rgb)


def slide(mat):
    parts = []
    for x in (-0.6, 0.6):
        for z in (-0.6, 0.6):
            parts.append(painted(kit.cylinder("Post", 0.07, 2.25, mat, centre=(x, 1.125, z), sides=8), SKY))
            parts.append(painted(kit.sphere("Cap", 0.1, mat, centre=(x, 2.27, z), sides=8, rings=4), SUNNY))
    parts.append(painted(kit.box("Deck", (1.45, 0.12, 1.45), mat, centre=(0, 1.2, 0), bevel=0.05), SUNNY))
    # A cone roof with a soft rim.
    roof = [((0, 2.28, 0), 1.0, 1.0), ((0, 2.36, 0), 1.02, 1.02), ((0, 2.62, 0), 0.55, 0.55), ((0, 2.9, 0), 0.04, 0.04)]
    parts.append(painted(kit.loft("Roof", roof, mat, sides=12, side_hint=(0, 0, 1)), CORAL))
    parts.append(painted(kit.sphere("Top", 0.08, mat, centre=(0, 2.95, 0)), SUNNY))
    # Rounded side panels on the two long sides, a rail on the back.
    for z in (-0.66, 0.66):
        parts.append(painted(kit.box("Panel", (1.2, 0.5, 0.06), mat, centre=(0, 1.55, z), bevel=0.025), MINT))
        parts.append(painted(kit.tube("Rail", [(-0.6, 1.85, z), (0.6, 1.85, z)], 0.035, mat, sides=6), CREAM))
    # The ladder up the back (-x).
    for z in (-0.32, 0.32):
        parts.append(painted(kit.tube("LadderSide", [(-1.45, 0.0, z), (-0.7, 1.25, z), (-0.62, 1.7, z)], 0.04, mat, sides=6), CORAL))
    for i in range(4):
        t = (i + 1) / 5.0
        x, y = -1.45 + 0.75 * t, 1.25 * t
        parts.append(painted(kit.cylinder("Rung", 0.03, 0.64, mat, centre=(x, y, 0), axis="z", sides=6), CREAM))
    # The slide: a half-pipe that curves down and flattens out at the bottom.
    path = [(0.7, 1.24), (1.1, 1.2), (1.6, 0.95), (2.15, 0.62), (2.65, 0.38), (3.05, 0.28), (3.4, 0.27)]
    rings = [((x, y, 0), 0.34, 0.2) for x, y in path]
    chute = kit.shell("Chute", rings, mat, arc=(0.22, 0.78), steps=8)
    chute.modifiers["Thickness"].thickness = 0.04
    parts.append(painted(chute, SUNNY))
    for x, y in ((2.1, 0.55), (3.25, 0.2)):
        parts.append(painted(kit.cylinder("Leg", 0.05, y, mat, centre=(x, y * 0.5, 0), sides=6), SKY))
    kit.join("Slide", parts)


def swings(mat):
    parts = []
    for x in (-1.6, 1.6):
        arc = []
        for i in range(9):  # a rounded arch: down to the ground on both sides
            a = math.pi * i / 8.0
            arc.append((x, max(0.0, 2.25 * math.sin(a) ** 0.6), -0.85 * math.cos(a)))
        parts.append(painted(kit.tube("Arch", arc, 0.07, mat, sides=8, hint=(1, 0, 0)), SKY))
        parts.append(painted(kit.sphere("Knob", 0.11, mat, centre=(x * 1.04, 2.25, 0)), SUNNY))
    parts.append(painted(kit.cylinder("Bar", 0.07, 3.3, mat, centre=(0, 2.25, 0), axis="x", sides=8), CORAL))
    frame = kit.join("Frame", parts)
    for i, (x, colour) in enumerate(((-0.65, SUNNY), (0.65, MINT))):
        pivot = (x, 2.2, 0)
        bits = []
        for dx in (-0.22, 0.22):
            bits.append(painted(kit.tube("Chain", [(x + dx, 2.2, 0), (x + dx, 0.58, 0)], 0.012, mat, sides=4, origin=pivot), GREY))
        bits.append(painted(kit.box("Seat", (0.55, 0.06, 0.24), mat, centre=(x, 0.55, 0), origin=pivot, bevel=0.025), colour))
        kit.join("Seat_%d" % i, bits)
    return frame


def climber(mat):
    parts = []
    radius = 1.35
    for i in range(6):  # half-hoops over the top, every 30 degrees
        turn = math.pi * i / 6.0
        hoop = []
        for k in range(11):
            a = math.pi * k / 10.0
            r = radius * math.cos(a)
            hoop.append((r * math.cos(turn), radius * math.sin(a) * 1.05, r * math.sin(turn)))
        parts.append(painted(kit.tube("Hoop", hoop, 0.04, mat, sides=6, hint=(0, 1, 0)), LILAC if i % 2 else SKY))
    for h in (0.45, 0.95):  # two rings round the dome
        r = radius * math.cos(math.asin(h / (radius * 1.05)))
        ring = [(r * math.cos(2 * math.pi * k / 14), h, r * math.sin(2 * math.pi * k / 14)) for k in range(15)]
        parts.append(painted(kit.tube("Ring", ring, 0.04, mat, sides=6, hint=(0, 1, 0)), MINT))
    parts.append(painted(kit.sphere("Top", 0.12, mat, centre=(0, radius * 1.05, 0)), CORAL))
    kit.join("Climber", parts)


def spinner(mat):
    kit.join("Base", [painted(kit.cylinder("Base", 0.28, 0.18, mat, centre=(0, 0.09, 0), sides=10), GREY)])
    parts = [painted(kit.cylinder("Disc", 0.85, 0.09, mat, centre=(0, 0.25, 0), sides=16), CORAL),
             painted(kit.cylinder("Top", 0.8, 0.02, mat, centre=(0, 0.305, 0), sides=16), CREAM),
             painted(kit.cylinder("Pole", 0.05, 0.7, mat, centre=(0, 0.65, 0), sides=8), SKY),
             painted(kit.sphere("Knob", 0.08, mat, centre=(0, 1.0, 0)), SUNNY)]
    for i in range(4):
        a = math.pi * 0.5 * i + math.pi * 0.25
        hoop = [(0.0, 0.95, 0.0), (0.35 * math.cos(a), 0.92, 0.35 * math.sin(a)),
                (0.62 * math.cos(a), 0.72, 0.62 * math.sin(a)), (0.7 * math.cos(a), 0.31, 0.7 * math.sin(a))]
        parts.append(painted(kit.tube("Handle", hoop, 0.03, mat, sides=6), SUNNY if i % 2 else MINT))
    kit.join("Spin", parts)


def springer(mat):
    coil = []
    for k in range(33):  # the spring
        a = 2 * math.pi * k / 8.0
        coil.append((0.11 * math.cos(a), 0.05 + 0.4 * k / 32.0, 0.11 * math.sin(a)))
    kit.join("Spring", [painted(kit.tube("Coil", coil, 0.025, mat, sides=5, hint=(0, 1, 0)), GREY),
                        painted(kit.cylinder("Foot", 0.2, 0.05, mat, centre=(0, 0.025, 0), sides=10), GREY)])
    pivot = (0, 0.45, 0)
    body = [((-0.36, 0.62, 0), 0.08, 0.06), ((-0.25, 0.64, 0), 0.17, 0.14), ((0.0, 0.62, 0), 0.19, 0.15),
            ((0.25, 0.64, 0), 0.16, 0.13), ((0.36, 0.66, 0), 0.06, 0.06)]
    parts = [painted(kit.loft("Body", body, mat, sides=8, origin=pivot), SUNNY),
             painted(kit.sphere("Hump", 0.13, mat, centre=(-0.05, 0.78, 0), squash=0.8), SUNNY),
             painted(kit.tube("Neck", [(0.3, 0.66, 0), (0.42, 0.85, 0), (0.45, 1.0, 0)], 0.07, mat, sides=6, origin=pivot), SUNNY),
             painted(kit.sphere("Head", 0.11, mat, centre=(0.52, 1.04, 0), squash=0.8), SUNNY),
             painted(kit.box("Seat", (0.26, 0.05, 0.3), mat, centre=(-0.2, 0.76, 0), bevel=0.02), CORAL),
             painted(kit.tube("Handles", [(0.33, 0.95, -0.17), (0.33, 0.95, 0.17)], 0.025, mat, sides=6, origin=pivot), CORAL)]
    for z in (-0.04, 0.04):
        parts.append(painted(kit.sphere("Eye", 0.018, mat, centre=(0.61, 1.07, z * 1.6), sides=5, rings=3), (0.1, 0.1, 0.1)))
    for z in (-0.2, 0.2):
        parts.append(painted(kit.box("Footrest", (0.12, 0.03, 0.08), mat, centre=(0.08, 0.5, z), bevel=0.01), CORAL))
    rider = kit.join("Rider", parts)
    rider.location = kit.g(*pivot)


PIECES = [("play_slide", slide), ("play_swings", swings), ("play_climber", climber),
          ("play_spinner", spinner), ("play_springer", springer)]


def main():
    for file_name, make in PIECES:
        kit.reset()
        make(kit.vertex_colour_material("Play"))
        kit.export(file_name + ".glb")


main()
