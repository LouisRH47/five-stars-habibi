"""Shared helpers for the Five Stars Habibi Blender scripts (Sessions 70-71).

Every model is built from code, so it can be rebuilt any time:
    python3 tools/blender/make_horse.py
    blender --background --python tools/blender/make_horse.py

All positions here are written in GODOT coordinates (x right, y up, the model faces -z),
and g() turns them into Blender ones (Blender is z-up). The glTF exporter turns them back,
so what you see in Godot matches the numbers in these scripts.
"""
import math
import os

import bpy
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
MODELS = os.path.join(ROOT, "assets", "models")
TEXTURES = os.path.join(ROOT, "assets", "textures")
# Pictures that only go inside a .glb (coat textures) are made here first. Godot skips this
# folder (it has a .gdignore file), so they're not imported twice.
SCRATCH = os.path.join(HERE, "out")


def g(x, y, z):
    """Godot (x, y, z) -> Blender (x, -z, y)."""
    return (x, -z, y)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.objects):
        for item in list(block):
            block.remove(item)


# ---------------------------------------------------------------- textures

def tile_noise(size, scale, seed):
    """Seamless (tiling) smooth noise in 0..1, made by blurring white noise in Fourier space."""
    rng = np.random.default_rng(seed)
    white = rng.standard_normal((size, size))
    fy = np.fft.fftfreq(size)[:, None]
    fx = np.fft.fftfreq(size)[None, :]
    blur = np.exp(-(fx * fx + fy * fy) * (scale * scale) * 20.0)
    out = np.real(np.fft.ifft2(np.fft.fft2(white) * blur))
    out -= out.min()
    out /= max(out.max(), 1e-6)
    return out


def save_png(name, rgb, folder=TEXTURES):
    """rgb: (h, w, 3 or 4) floats 0..1, row 0 = top of the picture. Saves folder/name.png."""
    os.makedirs(folder, exist_ok=True)
    if folder == SCRATCH and not os.path.exists(os.path.join(folder, ".gdignore")):
        open(os.path.join(folder, ".gdignore"), "w").close()
    h, w, channels = rgb.shape
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[:, :, :channels] = np.clip(rgb, 0.0, 1.0)  # 4 channels: the last one is see-through-ness
    image = bpy.data.images.new(name, w, h, alpha=channels == 4)
    image.pixels.foreach_set(rgba[::-1].reshape(-1))  # Blender stores the bottom row first
    path = os.path.join(folder, name + ".png")
    image.filepath_raw = path
    image.file_format = "PNG"
    image.save()
    return image


def colour(hex_or_rgb):
    if isinstance(hex_or_rgb, str):
        h = hex_or_rgb.lstrip("#")
        return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])
    return np.array(hex_or_rgb, dtype=float)


# ---------------------------------------------------------------- materials

def material(name, rgb=(0.8, 0.8, 0.8), image=None, rough=0.85):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.use_backface_culling = True  # Godot draws only the outside (faster)
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = rough
    if image is not None:
        tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = image
        tex.interpolation = "Linear"
        mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    else:
        # Colours here are written like Godot's Color() (sRGB); Blender wants linear numbers.
        lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb[:3]]
        bsdf.inputs["Base Color"].default_value = (lin[0], lin[1], lin[2], 1.0)
    return mat


def vertex_colour_material(name, rough=0.6):
    """One material for a whole model that takes its colours from the mesh (paint()), so
    a model with many colours is still one draw in Godot."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.use_backface_culling = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = rough
    attr = nodes.new("ShaderNodeVertexColor")
    attr.layer_name = "Col"
    mat.node_tree.links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def paint(obj, rgb):
    """Colours every corner of obj (sRGB like Godot's Color) into its "Col" colour layer."""
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb[:3]]
    mesh = obj.data
    layer = mesh.color_attributes.get("Col") or mesh.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    for item in layer.data:
        item.color = (lin[0], lin[1], lin[2], 1.0)
    return obj


def sphere(name, radius, mat, centre=(0, 0, 0), sides=8, rings=5, squash=1.0, parent=None):
    """A low-poly ball (Godot coords); squash < 1 flattens it."""
    c = np.array(centre, dtype=float)
    out = []
    for i in range(rings + 1):
        a = math.pi * i / rings
        out.append((c + np.array([0.0, -math.cos(a) * radius * squash, 0.0]), max(math.sin(a) * radius, 0.001),
                    max(math.sin(a) * radius, 0.001)))
    return loft(name, out, mat, sides=sides, origin=centre, side_hint=(1.0, 0.0, 0.0), parent=parent)


# ---------------------------------------------------------------- meshes

def _frame(direction, side_hint=(1.0, 0.0, 0.0)):
    d = np.array(direction, dtype=float)
    d /= max(np.linalg.norm(d), 1e-9)
    side = np.array(side_hint, dtype=float)
    side = side - d * side.dot(d)
    if np.linalg.norm(side) < 1e-6:
        side = np.array([0.0, 0.0, 1.0]) - d * d[2]
    side /= np.linalg.norm(side)
    up = np.cross(side, d)
    return side, up


def loft(name, rings, mat, sides=8, cap_start=True, cap_end=True, smooth=True, origin=(0, 0, 0),
         side_hint=(1.0, 0.0, 0.0), parent=None):
    """A tube through rings [(centre, half_width, half_height), ...] (Godot coords).
    The cross-section is an ellipse with `sides` corners. UV: u round the ring (0 = top),
    v along the tube. origin: where the object's pivot goes (Godot coords)."""
    centres = [np.array(r[0], dtype=float) for r in rings]
    verts, uvs_ring = [], []
    count = len(rings)
    for i, (c, w, h) in enumerate([(centres[i], r[1], r[2]) for i, r in enumerate(rings)]):
        before = centres[max(i - 1, 0)]
        after = centres[min(i + 1, count - 1)]
        side, up = _frame(after - before, side_hint)
        for k in range(sides):
            a = 2.0 * math.pi * k / sides
            p = c + side * math.sin(a) * w + up * math.cos(a) * h
            verts.append(p)
    faces, uv_faces = [], []
    lengths = [0.0]
    for i in range(1, count):
        lengths.append(lengths[-1] + float(np.linalg.norm(centres[i] - centres[i - 1])))
    total = max(lengths[-1], 1e-6)
    for i in range(count - 1):
        for k in range(sides):
            a, b = i * sides + k, i * sides + (k + 1) % sides
            c2, d2 = (i + 1) * sides + (k + 1) % sides, (i + 1) * sides + k
            faces.append((a, b, c2, d2))
            v0, v1 = lengths[i] / total, lengths[i + 1] / total
            u0, u1 = k / sides, (k + 1) / sides
            uv_faces.append(((u0, v0), (u1, v0), (u1, v1), (u0, v1)))
    if cap_start:
        verts.append(centres[0])
        mid = len(verts) - 1
        for k in range(sides):
            faces.append((mid, (k + 1) % sides, k))
            uv_faces.append(((0.5, 0.0), ((k + 1) / sides, 0.0), (k / sides, 0.0)))
    if cap_end:
        verts.append(centres[-1])
        mid = len(verts) - 1
        base = (count - 1) * sides
        for k in range(sides):
            faces.append((mid, base + k, base + (k + 1) % sides))
            uv_faces.append(((0.5, 1.0), (k / sides, 1.0), ((k + 1) / sides, 1.0)))
    o = np.array(origin, dtype=float)
    return _object(name, [g(*(v - o)) for v in verts], faces, uv_faces, mat, smooth, origin, parent)


def box(name, size, mat, centre=(0, 0, 0), origin=None, rot_x=0.0, smooth=False, parent=None, bevel=0.0):
    """A box (Godot size and centre). bevel > 0 cuts the corners for a softer look."""
    sx, sy, sz = (s * 0.5 for s in size)
    if bevel > 0.0:
        return _rounded_box(name, size, mat, centre, min(bevel, sx, sy, sz), origin, rot_x, parent)
    pts = [(-sx, -sy, -sz), (sx, -sy, -sz), (sx, sy, -sz), (-sx, sy, -sz),
           (-sx, -sy, sz), (sx, -sy, sz), (sx, sy, sz), (-sx, sy, sz)]
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (2, 3, 7, 6), (1, 2, 6, 5), (0, 4, 7, 3)]
    uv = [((0, 0), (0, 1), (1, 1), (1, 0))] * 6
    return _placed(name, pts, faces, uv, mat, centre, origin, rot_x, smooth, parent)


def _rounded_box(name, size, mat, centre, b, origin, rot_x, parent):
    sx, sy, sz = (s * 0.5 for s in size)
    pts, faces, uv = [], [], []
    # A box with chamfered edges: 8 corners each split in 3 (24 verts).
    for z in (-sz, sz):
        for y in (-sy, sy):
            for x in (-sx, sx):
                pts += [(x - math.copysign(b, x), y, z - math.copysign(b, z)),
                        (x, y - math.copysign(b, y), z - math.copysign(b, z)),
                        (x - math.copysign(b, x), y - math.copysign(b, y), z)]
    # Use the convex hull to make the faces (simple and always closed).
    import bmesh
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    for p in pts:
        bm.verts.new(p)
    bmesh.ops.convex_hull(bm, input=bm.verts)
    bmesh.ops.dissolve_limit(bm, angle_limit=0.01, verts=bm.verts, edges=bm.edges)
    bm.to_mesh(mesh)
    bm.free()
    verts = [tuple(v.co) for v in mesh.vertices]
    faces = [tuple(p.vertices) for p in mesh.polygons]
    bpy.data.meshes.remove(mesh)
    uv = [tuple((0.5, 0.5) for _ in f) for f in faces]
    return _placed(name, verts, faces, uv, mat, centre, origin, rot_x, False, parent)


def _placed(name, pts, faces, uv, mat, centre, origin, rot_x, smooth, parent):
    origin = centre if origin is None else origin
    c = np.array(centre, dtype=float)
    o = np.array(origin, dtype=float)
    ca, sa = math.cos(rot_x), math.sin(rot_x)
    out = []
    for x, y, z in pts:
        y2, z2 = y * ca - z * sa, y * sa + z * ca
        out.append(g(*(np.array([x, y2, z2]) + c - o)))
    return _object(name, out, faces, uv, mat, smooth, origin, parent)


def cylinder(name, radius, height, mat, centre=(0, 0, 0), sides=10, axis="y", radius_top=None, parent=None, smooth=True):
    """An upright (axis y), sideways (x) or lengthways (z) cylinder (Godot coords)."""
    r2 = radius if radius_top is None else radius_top
    half = height * 0.5
    c = np.array(centre, dtype=float)
    if axis == "y":
        a, b = c - (0, half, 0), c + (0, half, 0)
        hint = (0.0, 0.0, 1.0)
    elif axis == "x":
        a, b = c - (half, 0, 0), c + (half, 0, 0)
        hint = (0.0, 1.0, 0.0)
    else:
        a, b = c - (0, 0, half), c + (0, 0, half)
        hint = (1.0, 0.0, 0.0)
    return loft(name, [(a, radius, radius), (b, r2, r2)], mat, sides=sides, smooth=smooth,
                origin=centre, side_hint=hint, parent=parent)


def shell(name, rings, mat, arc=(-0.3, 0.3), steps=8, origin=(0, 0, 0), smooth=True, parent=None):
    """An open part-tube (like a saddle cloth or a slide chute): the ellipse rings only from
    angle arc[0] to arc[1] (fractions of a turn, 0 = top)."""
    centres = [np.array(r[0], dtype=float) for r in rings]
    count = len(rings)
    verts, faces, uv_faces = [], [], []
    for i, r in enumerate(rings):
        side, up = _frame(centres[min(i + 1, count - 1)] - centres[max(i - 1, 0)])
        for k in range(steps + 1):
            a = 2.0 * math.pi * (arc[0] + (arc[1] - arc[0]) * k / steps)
            verts.append(centres[i] + side * math.sin(a) * r[1] + up * math.cos(a) * r[2])
    row = steps + 1
    for i in range(count - 1):
        for k in range(steps):
            a, b = i * row + k, i * row + k + 1
            faces.append((a, b, b + row, a + row))
            uv_faces.append(((k / steps, i / (count - 1)), ((k + 1) / steps, i / (count - 1)),
                             ((k + 1) / steps, (i + 1) / (count - 1)), (k / steps, (i + 1) / (count - 1))))
    o = np.array(origin, dtype=float)
    obj = _object(name, [g(*(v - o)) for v in verts], faces, uv_faces, mat, smooth, origin, parent)
    solid = obj.modifiers.new("Thickness", "SOLIDIFY")
    solid.thickness = 0.02
    return obj


def tube(name, points, radius, mat, sides=8, parent=None, origin=(0, 0, 0), hint=(1.0, 0.0, 0.0)):
    """A bent bar through points (Godot coords): rails, swing frames, handles."""
    return loft(name, [(p, radius, radius) for p in points], mat, sides=sides, origin=origin,
                side_hint=hint, parent=parent)


def _object(name, verts, faces, uv_faces, mat, smooth, origin, parent):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([tuple(v) for v in verts], [], faces)
    layer = mesh.uv_layers.new(name="UVMap")
    i = 0
    for poly, uvs in zip(mesh.polygons, uv_faces):
        for loop_index, uv in zip(poly.loop_indices, uvs):
            layer.data[loop_index].uv = uv
        i += 1
    mesh.validate()
    for poly in mesh.polygons:
        poly.use_smooth = smooth
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    obj.location = g(*origin)
    bpy.context.scene.collection.objects.link(obj)
    if parent is not None:
        obj.parent = parent
        obj.location = tuple(np.array(g(*origin)) - np.array(parent.location))
    return obj


def empty(name, at=(0, 0, 0), parent=None):
    obj = bpy.data.objects.new(name, None)
    obj.location = g(*at)
    bpy.context.scene.collection.objects.link(obj)
    if parent is not None:
        obj.parent = parent
    return obj


def join(name, objects):
    """Merges objects into one mesh (fewer draw calls). Keeps the first one's pivot."""
    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    objects[0].name = name
    objects[0].data.name = name
    return objects[0]


def triangles():
    total = 0
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH":
            for poly in obj.data.polygons:
                total += len(poly.vertices) - 2
    return total


def export(file_name):
    os.makedirs(MODELS, exist_ok=True)
    path = os.path.join(MODELS, file_name)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True, export_vertex_color="ACTIVE",
                              export_yup=True, export_image_format="AUTO", export_texcoords=True,
                              export_normals=True, export_materials="EXPORT", use_selection=False)
    print("wrote %s (%d triangles)" % (path, triangles()))
    return path
