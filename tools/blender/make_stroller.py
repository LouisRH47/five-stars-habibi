"""Session 92: a baby stroller (pushchair) that a parent pushes. One .glb per fabric colour
in assets/models/ (the colours are painted on the mesh, so the body is one draw):

  stroller_navy.glb, stroller_berry.glb, stroller_grey.glb
    "Body"      the frame, the seat with a rounded hood and the child sitting inside
    "Wheel_FL", "Wheel_FR", "Wheel_RL", "Wheel_RR"
                the four wheels; each pivots on its axle, so the game can turn them
    "Handle"    an empty in the middle of the handle bar (where the hands go)

The stroller faces -z (like everything in the game); the handle is at the back (+z).

    python3 tools/blender/make_stroller.py
    blender --background --python tools/blender/make_stroller.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit  # noqa: E402

FRAME = (0.16, 0.17, 0.19)
CHROME = (0.78, 0.8, 0.83)
TYRE = (0.08, 0.08, 0.09)
HUB = (0.85, 0.86, 0.88)
SKIN = (0.93, 0.76, 0.62)
HAIR = (0.25, 0.17, 0.1)
EYES = (0.08, 0.06, 0.05)
FABRICS = {"navy": (0.18, 0.28, 0.48), "berry": (0.6, 0.2, 0.33), "grey": (0.42, 0.44, 0.47)}
BLANKETS = {"navy": (0.98, 0.85, 0.45), "berry": (0.98, 0.93, 0.85), "grey": (0.55, 0.78, 0.9)}

HANDLE = (0.0, 1.0, 0.5)      # the middle of the handle bar
REAR = (0.235, 0.13, 0.3)     # rear wheel: x out from the middle, radius (= axle height), z
FRONT = (0.2, 0.09, -0.32)    # front wheel: the same


def painted(obj, rgb):
    return kit.paint(obj, rgb)


def body(mat, fabric, blanket):
    hx, hy, hz = HANDLE
    parts = []
    # The handle bar with a soft grip in the middle.
    parts.append(painted(kit.cylinder("Bar", 0.016, 0.5, mat, centre=(0, hy, hz), axis="x", sides=8), FRAME))
    parts.append(painted(kit.cylinder("Grip", 0.026, 0.36, mat, centre=(0, hy, hz), axis="x", sides=8), FRAME))
    for side in (-1.0, 1.0):
        # Push arms from the handle down to the rear axle, legs from the seat to the front axle.
        parts.append(painted(kit.tube("Push", [(side * 0.24, hy, hz), (side * 0.24, 0.62, 0.22),
                                               (side * REAR[0], REAR[1], REAR[2])], 0.016, mat, sides=6), CHROME))
        parts.append(painted(kit.tube("Leg", [(side * 0.21, 0.6, 0.0), (side * FRONT[0], FRONT[1], FRONT[2])],
                                      0.015, mat, sides=6), CHROME))
        parts.append(painted(kit.sphere("Joint", 0.03, mat, centre=(side * 0.235, 0.6, 0.12), sides=6, rings=3), FRAME))
    parts.append(painted(kit.cylinder("RearAxle", 0.012, REAR[0] * 2, mat, centre=(0, REAR[1], REAR[2]), axis="x", sides=6), CHROME))
    parts.append(painted(kit.cylinder("FrontAxle", 0.012, FRONT[0] * 2, mat, centre=(0, FRONT[1], FRONT[2]), axis="x", sides=6), CHROME))
    # The basket under the seat.
    parts.append(painted(kit.box("Basket", (0.36, 0.1, 0.38), mat, centre=(0, 0.25, 0.02), bevel=0.02), FRAME))
    # The seat: a soft tub, a footrest and a bumper bar in front of the child.
    parts.append(painted(kit.box("Tub", (0.42, 0.28, 0.54), mat, centre=(0, 0.6, 0.0), bevel=0.07), fabric))
    parts.append(painted(kit.box("Footrest", (0.34, 0.04, 0.12), mat, centre=(0, 0.45, -0.3), bevel=0.015), FRAME))
    parts.append(painted(kit.tube("Bumper", [(-0.2, 0.74, -0.22), (0, 0.78, -0.27), (0.2, 0.74, -0.22)],
                                  0.018, mat, sides=6, hint=(0, 1, 0)), FRAME))
    # The hood: a quarter of a ball over the back of the seat, with a lighter trim.
    rings = [((-0.215, 0.72, 0.16), 0.17, 0.19), ((-0.19, 0.72, 0.16), 0.27, 0.3),
             ((0.0, 0.72, 0.16), 0.3, 0.33), ((0.19, 0.72, 0.16), 0.27, 0.3), ((0.215, 0.72, 0.16), 0.17, 0.19)]
    parts.append(painted(kit.shell("Hood", rings, mat, arc=(-0.07, 0.25), steps=8), fabric))
    trim = [((-0.2, 0.72, 0.16), 0.285, 0.315), ((0.2, 0.72, 0.16), 0.285, 0.315)]
    parts.append(painted(kit.shell("Trim", trim, mat, arc=(-0.075, -0.06), steps=1), [min(c + 0.25, 1.0) for c in fabric]))
    # The child: sitting up facing forward, a blanket over the legs.
    parts.append(painted(kit.sphere("Tummy", 0.1, mat, centre=(0, 0.79, 0.07), squash=1.2), blanket))
    parts.append(painted(kit.sphere("Head", 0.085, mat, centre=(0, 0.96, 0.05), sides=10, rings=6), SKIN))
    parts.append(painted(kit.sphere("Hair", 0.088, mat, centre=(0, 0.985, 0.065), sides=10, rings=6, squash=0.75), HAIR))
    for side in (-1.0, 1.0):
        parts.append(painted(kit.sphere("Eye", 0.012, mat, centre=(side * 0.03, 0.97, -0.028), sides=5, rings=3), EYES))
        parts.append(painted(kit.sphere("Hand", 0.025, mat, centre=(side * 0.08, 0.8, -0.06), sides=6, rings=3), SKIN))
    parts.append(painted(kit.box("Blanket", (0.34, 0.05, 0.3), mat, centre=(0, 0.76, -0.12), bevel=0.02), blanket))
    return kit.join("Body", parts)


def wheel(name, mat, x, radius, z):
    centre = (x, radius, z)
    bits = [painted(kit.cylinder("Tyre", radius, 0.05, mat, centre=centre, axis="x", sides=14), TYRE),
            painted(kit.cylinder("Hub", radius * 0.45, 0.056, mat, centre=centre, axis="x", sides=10), HUB)]
    # Two spokes across the wheel, so you can see it turn.
    for rot in (0.0, 1.5708):
        bits.append(painted(kit.box("Spoke", (0.058, radius * 1.7, 0.018), mat, centre=centre, rot_x=rot), HUB))
    return kit.join(name, bits)


def stroller(colour):
    kit.reset()
    mat = kit.vertex_colour_material("Stroller")
    body(mat, FABRICS[colour], BLANKETS[colour])
    for side, tag in ((-1.0, "L"), (1.0, "R")):
        wheel("Wheel_R" + tag, mat, side * REAR[0], REAR[1], REAR[2])
        wheel("Wheel_F" + tag, mat, side * FRONT[0], FRONT[1], FRONT[2])
    kit.empty("Handle", HANDLE)
    kit.export("stroller_%s.glb" % colour)


def main():
    for colour in FABRICS:
        stroller(colour)


main()
