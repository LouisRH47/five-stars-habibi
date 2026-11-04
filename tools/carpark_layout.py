"""Session 62: car parks and kerbs. Used by tools/build_wahat_data.py.

Lays out every solar car park from the clusters' lanes, in metres:
  - Louis's rows: 1 row, an aisle, 2 rows back to back, an aisle, 1 row (the "full" version,
    32 m of bays and aisles). The 29 m gaps between C1 and C2 and between C2 and C3 are too
    narrow for that, so they get the "narrow" version: 1 row, an aisle, 2 rows back to back,
    an aisle (27 m, the 2 back-to-back rows share their middle line).
  - Every car park sits tight against its cluster: only a kerb, a little buggy lane and a kerb
    between the cluster's outside lane and the first row of bays.
  - A planted verge (grass, a kerb, the car park sign and the electric car chargers) between the
    ring road and the first bays, with an opening at every aisle (the access).
  - Freed space (old, bigger car parks) becomes grass beds with palms.
Bays are 2.5 m wide and 5 m deep, rows run north-south (along z), cars park nose first.
"""
import math
import random

BAY_W = 2.5           # bay width along the row
BAY_D = 5.0           # bay depth
AISLE = 6.0           # driving aisle
NARROW_AISLE = 5.8    # aisles in the 29 m gaps (a little tighter so a buggy lane still fits)
KERB = 0.3            # kerbstone width (0.15 m high)
BUGGY = 2.9           # buggy lane: kerb + lane + kerb = 3.5 m, the most Louis's "tight" allows
NARROW_BUGGY = 1.5    # the narrow car parks' buggy lane
VERGE = 7.0           # grass between the ring road kerb and the first bays
LANE_EDGE = 63.0      # a cluster's outside lane edge, from the cluster centre (lane at 60, 6 m wide)
RING_KERB_Z = 200.0   # the ring road's inner kerb (north and south)
NORTH_SPINE_EDGE = -43.0   # north edge of "Plaza to C1" (z = -40, 6 m wide)
SOUTH_SPINE_EDGE = 38.0    # south edge of "South Spine Link" (z = 35, 6 m wide)
FILL = 0.5            # about half the bays have a car (Louis: "not every bay")
PAINTS = [(0.92, 0.92, 0.9), (0.12, 0.12, 0.13), (0.62, 0.64, 0.67), (0.75, 0.13, 0.12),
          (0.14, 0.29, 0.6), (0.85, 0.82, 0.74), (0.35, 0.36, 0.38), (0.55, 0.08, 0.1),
          (0.2, 0.42, 0.33), (0.95, 0.6, 0.15), (0.45, 0.6, 0.78), (0.96, 0.96, 0.96)]
MODELS = 5            # sedan, suv, hatchback, suv-luxury, van (scripts/parked_car.gd MODELS)


def _strips(kind, buggy, aisle):
    """The cross-section from the cluster's side outwards: (what, width, nose).
    buggy None: no buggy lane alongside (the turned car park has it across its far end)."""
    if kind == 'full' and buggy is None:
        return [('kerb', KERB, 0), ('row', BAY_D, +1), ('aisle', aisle, 0), ('row', BAY_D, -1), ('row', BAY_D, +1),
                ('aisle', aisle, 0), ('row', BAY_D, -1), ('kerb', KERB, 0)]
    if kind == 'full':
        return [('kerb', KERB, 0), ('buggy', buggy, 0), ('kerb', KERB, 0),
                ('row', BAY_D, +1), ('aisle', aisle, 0), ('row', BAY_D, -1), ('row', BAY_D, +1),
                ('aisle', aisle, 0), ('row', BAY_D, -1), ('kerb', KERB, 0)]
    # narrow: the row side hugs cluster A, the buggy lane runs along cluster B
    return [('kerb', KERB, 0), ('row', BAY_D, +1), ('aisle', aisle, 0), ('row', BAY_D, -1),
            ('row', BAY_D, +1), ('aisle', aisle, 0), ('kerb', KERB, 0), ('buggy', buggy, 0),
            ('kerb', KERB, 0)]


def plan(name, arabic, clusters, start_x, direction, north, kind, bays, buggy=BUGGY, aisle=AISLE, ring=None):
    """One car park. start_x: the cluster lane edge it hugs; direction: +1 east, -1 west.
    north: True for the car parks on the north ring road. bays: bays in each row.
    ring: where the ring road's kerb is (default: the north or south ring road)."""
    sz = 1 if north else -1                  # rows grow away from the ring road
    z0 = ring if ring is not None else (-RING_KERB_Z if north else RING_KERB_Z)
    zr0 = z0 + sz * VERGE                     # first bay line
    zr1 = zr0 + sz * bays * BAY_W             # last bay line
    toward = 90.0 if direction < 0 else -90.0  # nose pointing back at the (first) cluster
    x = start_x
    strips = []
    for what, width, nose in _strips(kind, buggy, aisle):
        a, b = sorted([round(x, 3), round(x + direction * width, 3)])
        strips.append({'what': what, 'x0': a, 'x1': b, 'nose': nose})
        x += direction * width
    lo_z, hi_z = sorted([z0, zr1 + sz * KERB])
    asphalt = [s for s in strips if s['what'] in ('row', 'aisle')]
    ax0 = min(s['x0'] for s in asphalt) - KERB
    ax1 = max(s['x1'] for s in asphalt) + KERB
    rows, roofs, aisles, kerbs, buggies = [], [], [], [], []
    rz0, rz1 = sorted([zr0, zr1])
    i = 0
    row_strips = [s for s in strips if s['what'] == 'row']
    for s in strips:
        if s['what'] == 'row':
            facing = toward if s['nose'] > 0 else -toward
            rows.append({'x0': s['x0'], 'x1': s['x1'], 'z0': rz0, 'z1': rz1, 'facing': facing, 'bays': bays})
        elif s['what'] == 'aisle':
            aisles.append({'x0': s['x0'], 'x1': s['x1'], 'z0': min(z0, zr1), 'z1': max(z0, zr1)})
        elif s['what'] == 'buggy':
            buggies.append(s)
    # Roofs: one per single row (5.5 m), one shared over each back-to-back pair (10.5 m).
    k = 0
    while k < len(rows):
        r = rows[k]
        p = rows[k + 1] if k + 1 < len(rows) else None
        if p is not None and (abs(p['x0'] - r['x1']) < 0.01 or abs(p['x1'] - r['x0']) < 0.01):
            roofs.append({'x0': min(r['x0'], p['x0']) - 0.25, 'x1': max(r['x1'], p['x1']) + 0.25, 'z0': rz0, 'z1': rz1, 'double': True})
            k += 2
        else:
            # the back of a single row is the side away from its aisle; the roof is high there
            roofs.append({'x0': r['x0'] - 0.25, 'x1': r['x1'] + 0.25, 'z0': rz0, 'z1': rz1, 'double': False,
                          'high_x': r['x0'] if _back_is_low_x(r) else r['x1']})
            k += 1
    # Kerbs (rects x0, z0, x1, z1): both long sides of the asphalt, the far end, and the ends of
    # each row block at the verge (the aisles stay open to the ring road).
    # (the long kerb beside the buggy lane is added with the buggy lane, all the way along it)
    bis = [n for n, s in enumerate(strips) if s['what'] == 'buggy']
    near_buggy = [strips[bis[0] - 1], strips[bis[0] + 1]] if bis else []
    for x0k in (ax0, ax1 - KERB):
        if not any(abs(k['x0'] - x0k) < 0.01 for k in near_buggy):
            kerbs.append((x0k, rz0, x0k + KERB, rz1))
    kerbs.append((ax0, min(zr1, zr1 + sz * KERB), ax1, max(zr1, zr1 + sz * KERB)))
    for block in _blocks(rows):
        kerbs.append((block[0], min(zr0, zr0 - sz * KERB), block[1], max(zr0, zr0 - sz * KERB)))
    return {'name': name, 'arabic': arabic, 'clusters': clusters, 'kind': kind, 'north': north,
            'area': (ax0, lo_z, ax1 - ax0, hi_z - lo_z), 'rows': rows, 'roofs': roofs, 'aisles': aisles,
            'kerbs': kerbs, 'buggy': buggies, 'strips': strips, 'z0': z0, 'zr0': zr0, 'zr1': zr1, 'sz': sz,
            'bays': bays}


def _back_is_low_x(row):
    # nose pointing west (-90) means the back of the bay is at the low x side
    return row['facing'] < 0


def _blocks(rows):
    """Row groups standing next to each other (a single row, or a back-to-back pair)."""
    spans = sorted((r['x0'], r['x1']) for r in rows)
    blocks = []
    for a, b in spans:
        if blocks and abs(blocks[-1][1] - a) < 0.01:
            blocks[-1][1] = b
        else:
            blocks.append([a, b])
    return blocks


def bays_of(park):
    """Every bay: (centre x, centre z, facing, row index, bay index)."""
    out = []
    for ri, r in enumerate(park['rows']):
        cx = (r['x0'] + r['x1']) * 0.5
        for b in range(r['bays']):
            cz = r['z0'] + BAY_W * (b + 0.5)
            out.append((cx, cz, r['facing'], ri, b))
    return out


def visitor_bay(park):
    """The bay kept free for the visiting car: near the ring road, beside the first aisle."""
    aisle = park['aisles'][0]
    ax = (aisle['x0'] + aisle['x1']) * 0.5
    best = None
    for cx, cz, facing, ri, b in bays_of(park):
        r = park['rows'][ri]
        beside = abs(r['x1'] - aisle['x0']) < 0.01 or abs(r['x0'] - aisle['x1']) < 0.01
        # the 4th bay from the ring road end
        index = b if park['north'] else r['bays'] - 1 - b
        if beside and index == 3 and best is None:
            best = (cx, cz, facing, ax)
    return best


def parked_cars(parks, seed=62):
    """About half the bays get a car (random model and colour), never the visitor's bay."""
    rng = random.Random(seed)
    cars = []
    for pi, park in enumerate(parks):
        free = visitor_bay(park)
        bays = [bay for bay in bays_of(park) if not (free and abs(bay[0] - free[0]) < 0.01 and abs(bay[1] - free[1]) < 0.01)]
        taken = set(rng.sample(range(len(bays)), round(len(bays) * FILL)))
        for n, (cx, cz, facing, ri, b) in enumerate(bays):
            if n not in taken:
                continue
            # nose 0.35 m short of the back line, so it never touches the kerb or a roof post
            shift = (BAY_D - 4.3) * 0.5 - 0.35
            dx = math.sin(math.radians(facing)) * shift
            x, z = to_world(park, cx + dx, cz)
            cars.append({'x': round(x, 3), 'z': round(z, 3), 'facing': world_facing(park, facing), 'park': pi,
                         'model': rng.randrange(MODELS), 'paint': PAINTS[rng.randrange(len(PAINTS))]})
    return cars


def chargers(park):
    """Two electric car chargers on posts, at the ring road end of the two outer rows."""
    out = []
    for r in (park['rows'][0], park['rows'][-1]):
        x = (r['x0'] + r['x1']) * 0.5 + (1.5 if r['facing'] < 0 else -1.5)   # towards the aisle
        z = park['zr0'] - park['sz'] * 1.0
        out.append((round(x, 3), round(z, 3)))
    return out


def _rect(a):
    """(x0, z0, x1, z1) with any order -> (x, z, w, d)."""
    x0, z0, x1, z1 = a
    return (min(x0, x1), min(z0, z1), abs(x1 - x0), abs(z1 - z0))


def build_all(clusters, road, bays=32):
    """Every car park, its buggy lane (added to ROADS with road()), kerbs, grass beds and palms.
    Returns parks, kerbs, gardens (x, z, w, d), palms (x, z) and the moved C4-C5 building site."""
    centre = {n: x for n, x, z in clusters}
    edge = lambda n, side: centre[n] + side * LANE_EDGE
    parks = [
        plan('Cluster 1 Parking', 'مواقف المجموعة ١', ['C1'], edge(1, -1), -1, True, 'full', bays),
        plan('Cluster 1 and 2 Parking', 'مواقف المجموعتين ١ و ٢', ['C1', 'C2'], edge(1, 1), 1, True, 'narrow', bays, NARROW_BUGGY, NARROW_AISLE),
        plan('Cluster 2 and 3 Parking', 'مواقف المجموعتين ٢ و ٣', ['C2', 'C3'], edge(2, 1), 1, True, 'narrow', bays, NARROW_BUGGY, NARROW_AISLE),
        # 35 m between the Phase 2 building site and Cluster 4: a slightly narrower buggy lane
        plan('Cluster 4 West Parking', 'مواقف المجموعة ٤ غرب', ['C4'], edge(4, -1), -1, False, 'full', bays, 2.0),
        plan('Cluster 4 East Parking', 'مواقف المجموعة ٤ شرق', ['C4'], edge(4, 1), 1, False, 'full', bays),
        plan('Cluster 5 West Parking', 'مواقف المجموعة ٥ غرب', ['C5'], edge(5, -1), -1, False, 'full', bays),
        plan('Cluster 5 East Parking', 'مواقف المجموعة ٥ شرق', ['C5'], edge(5, 1), 1, False, 'full', bays),
    ]
    kerbs, gardens = [], []
    for p in parks:
        north = p['north']
        strips = p['strips']
        bi = [n for n, s in enumerate(strips) if s['what'] == 'buggy'][0]
        lane = strips[bi]
        width = lane['x1'] - lane['x0']
        x = round((lane['x0'] + lane['x1']) * 0.5, 3)
        ring = -RING_KERB_Z + KERB if north else RING_KERB_Z - KERB
        spine = -40.0 if north else 35.0                  # the spine road's middle line
        start = -198.0 if north else 198.0                 # just past the cluster's cross lane (z = 197)
        name = p['clusters'][-1] + ' Car Park Buggy Lane'
        road(name, (x, start), (x, spine), width)
        p['buggy_lane'] = {'name': name, 'x': x, 'width': width, 'from': start, 'to': spine}
        # at the ring road end the buggy lane turns into the cluster's cross lane (never the ring road)
        cid = int(p['clusters'][-1][1:])
        lane_x = centre[cid] + (60.0 if x > centre[cid] else -60.0)
        cross_z = -197.0 if north else 197.0
        road(p['clusters'][-1] + ' Car Park Buggy Link', (lane_x, cross_z), (x, cross_z), width)
        # kerbs both sides: the bay side all along, the cluster side with openings at both ends
        # (where the lane meets the cluster's cross lane and its inner lane)
        cluster_kerb = strips[0] if bi == 1 else strips[-1]
        bay_kerb = strips[bi + 1] if bi == 1 else strips[bi - 1]
        spine_edge = NORTH_SPINE_EDGE if north else SOUTH_SPINE_EDGE
        kerbs.append(_rect((bay_kerb['x0'], ring, bay_kerb['x1'], spine_edge)))
        kerbs.append(_rect((cluster_kerb['x0'], -194.0 if north else 194.0, cluster_kerb['x1'], -50.0 if north else 50.0)))
        for k in p['kerbs']:
            kerbs.append(_rect(k))
        # the aisle openings through the verge get a kerb on each side
        for a in p['aisles']:
            for xk in (a['x0'] - KERB, a['x1']):
                if abs(xk - bay_kerb['x0']) < 0.01:
                    continue   # the buggy lane's kerb is already there
                kerbs.append(_rect((xk, p['z0'] + (KERB if north else -KERB), xk + KERB, p['zr0'])))
        ax0, z, w, d = p['area']
        far = p['zr1'] + p['sz'] * KERB
        gardens.append(_rect((ax0, far, ax0 + w, spine_edge)))
        # the verge: grass in front of every row block (the aisles stay asphalt)
        for b in _blocks(p['rows']):
            x0 = ax0 if abs(b[0] - KERB - ax0) < 0.01 else b[0]
            x1 = ax0 + w if abs(b[1] + KERB - (ax0 + w)) < 0.01 else b[1]
            gardens.append(_rect((x0, p['z0'], x1, p['zr0'] - p['sz'] * KERB)))
    # Freed space (the old car parks were wider): grass beds with palms, and the C4-C5
    # building site moves into the middle between the two new car parks.
    plaza = parks[0]['area']
    gardens.append(_rect((-92.0, -RING_KERB_Z, plaza[0], NORTH_SPINE_EDGE)))
    a4, a5 = parks[4]['area'], parks[5]['area']
    mid0, mid1 = a4[0] + a4[2], a5[0]
    site = (round((mid0 + mid1) * 0.5 - 8.0, 3), 56.0, 16.0, 132.0)
    gardens += [_rect((mid0, SOUTH_SPINE_EDGE, site[0], RING_KERB_Z)), _rect((site[0] + site[2], SOUTH_SPINE_EDGE, mid1, RING_KERB_Z)),
                _rect((site[0], SOUTH_SPINE_EDGE, site[0] + site[2], site[1])), _rect((site[0], site[1] + site[3], site[0] + site[2], RING_KERB_Z))]
    east = parks[6]['area']
    gardens.append(_rect((east[0] + east[2], SOUTH_SPINE_EDGE, 420.0, RING_KERB_Z)))
    # Cluster 3's east homes: the 8th car park, turned sideways in the spine lawn's free corner.
    turned, more_kerbs, more_gardens = plan_turned(road)
    parks.append(turned)
    kerbs += more_kerbs
    gardens += more_gardens
    gardens = [tuple(round(v, 3) for v in g) for g in gardens if g[2] > 0.05 and g[3] > 0.05]
    kerbs = [tuple(round(v, 3) for v in k) for k in kerbs if k[2] > 0.05 and k[3] > 0.05]
    return parks, kerbs, gardens, palms_in(gardens), site


# --- The turned car park (Cluster 3 East, follow-up to Session 62) ---
# Cluster 3's homes run right up to the east ring road, so 29 of them were 86-120 m from the
# only car park (between C2 and C3). The nearest free land is the north-east corner of the spine
# lawn, which Session 63 kept free: x 376-415, z -37 (the "Plaza to C1" path) to -3 (the
# spine buggy road), with grass up to the ring road kerb at x 420. A car park there must open
# east onto the ring road, so its rows run east-west: it's the usual layout turned a quarter
# turn. It's planned with plan() in its own "turned" frame and every output goes through
# to_world(): local (x, z) is the real map's (z, -x), so local z is the map's x (the ring road
# kerb at local z 420) and local x is minus the map's z.
CORNER = (376.0, -37.0, 415.0, -3.0)   # x0, z0, x1, z1 (GameConfig.SPINE_FREE_CORNER)
EAST_RING_KERB = 420.0


def to_world(p, x, z):
    """A point of a car park on the real map (a turned car park is planned sideways)."""
    return (z, -x) if p.get('turned') else (x, z)


def world_rect(p, r):
    """A rectangle (x, z, w, d) of a car park on the real map."""
    if not p.get('turned'):
        return r
    x, z, w, d = r
    return (z, -(x + w), d, w)


def area_of(p):
    return world_rect(p, p['area'])


def world_facing(p, facing):
    """Which way a car's nose points on the real map (degrees, 0 = +z, 90 = +x)."""
    if not p.get('turned'):
        return facing
    return ((facing + 90.0 + 180.0) % 360.0) - 180.0


def plan_turned(road):
    """The 8th car park, Louis's 1-2-1 rows running east-west in the spine lawn's north-east
    corner. Returns the park (planned sideways), its kerbs and grass beds (on the real map)."""
    x0, z0, x1, z1 = CORNER
    across = KERB + 4 * BAY_D + 2 * AISLE + KERB          # 32.6 m: fits the 34 m corner
    north_edge = (z0 + z1) * 0.5 - across * 0.5            # an equal strip of lawn each side
    first_bay = EAST_RING_KERB - VERGE
    # the buggy lane (kerb + lane + kerb) runs across the far (west) end of the rows
    bays = int((first_bay - (x0 + 2 * KERB + BUGGY)) // BAY_W)
    p = plan('Cluster 3 East Parking', 'مواقف المجموعة ٣ شرق', ['C3'], -north_edge, -1, False, 'full', bays,
             None, AISLE, EAST_RING_KERB)
    p['turned'] = True
    last_bay = p['zr1']
    # the buggy lane: from the "Plaza to C1" path (into Cluster 3) to the spine buggy road. Its
    # ends stop 0.4 m inside their edges (paths are drawn half a width longer, and a light lane
    # drawn to the middle of the buggy road would cover its dashed line).
    lane_x = round(last_bay - KERB - BUGGY * 0.5, 3)
    name = 'C3 East Car Park Buggy Lane'
    road(name, (lane_x, z0 + 0.4), (lane_x, z1 - 0.4), BUGGY)
    p['buggy_lane'] = {'name': name, 'x': lane_x, 'width': BUGGY, 'from': z0 + 0.4, 'to': z1 - 0.4}
    kerbs, gardens = [], []
    for k in p['kerbs']:
        kx0, kz0, kx1, kz1 = k
        if abs(min(kz0, kz1) - (last_bay - KERB)) < 0.01 and abs(max(kz0, kz1) - last_bay) < 0.01:
            kx0, kx1 = -z1, -z0   # the far kerb runs the buggy lane's whole length
        kerbs.append(world_rect(p, _rect((kx0, kz0, kx1, kz1))))
    outer = last_bay - 2 * KERB - BUGGY
    kerbs.append((round(outer, 3), z0, KERB, z1 - z0))      # the lawn side of the buggy lane
    for a in p['aisles']:   # the aisle openings through the verge get a kerb on each side
        for xk in (a['x0'] - KERB, a['x1']):
            kerbs.append(world_rect(p, _rect((xk, p['z0'] - KERB, xk + KERB, p['zr0']))))
    ax0, _, w, _ = p['area']
    for b in _blocks(p['rows']):   # the grass verge in front of every row block
        bx0 = ax0 if abs(b[0] - KERB - ax0) < 0.01 else b[0]
        bx1 = ax0 + w if abs(b[1] + KERB - (ax0 + w)) < 0.01 else b[1]
        gardens.append(world_rect(p, _rect((bx0, p['z0'], bx1, p['zr0'] + KERB))))
    return p, kerbs, gardens


def palms_in(gardens, spacing=15.0, inset=4.0):
    """Palms in rows in every grass bed wide enough for them (not in the thin verges)."""
    spots = []
    for x, z, w, d in gardens:
        if w < 2 * inset or d < 2 * inset or (d < VERGE + 0.5):
            continue
        nx = max(1, int((w - 2 * inset) // spacing) + 1)
        nz = max(1, int((d - 2 * inset) // spacing) + 1)
        for i in range(nx):
            for j in range(nz):
                px = x + w * 0.5 if nx == 1 else x + inset + i * (w - 2 * inset) / (nx - 1)
                pz = z + d * 0.5 if nz == 1 else z + inset + j * (d - 2 * inset) / (nz - 1)
                spots.append((round(px, 2), round(pz, 2)))
    return spots


def reach(parks, homes):
    """How far each home is from the nearest car park (metres, from the middle of the home)."""
    out = []
    for h in homes:
        hx, hz = h
        best = 1e9
        for p in parks:
            x, z, w, d = area_of(p)
            dx = max(x - hx, 0, hx - (x + w))
            dz = max(z - hz, 0, hz - (z + d))
            best = min(best, math.hypot(dx, dz))
        out.append(best)
    return out


def to_data(p, rect, v3):
    """The car park as the data file stores it (CAR_PARKS)."""
    if p.get('turned'):
        return _turned_data(p, rect, v3)
    R = lambda a: rect(*_rect(a))
    rows = [{'area': R((r['x0'], r['z0'], r['x1'], r['z1'])), 'facing': r['facing'], 'bays': r['bays']} for r in p['rows']]
    roofs = []
    for r in p['roofs']:
        high = (r['x0'] + r['x1']) * 0.5 if r['double'] else r['high_x']
        roofs.append({'area': R((r['x0'], r['z0'], r['x1'], r['z1'])), 'double': r['double'], 'high_x': round(high, 3)})
    vis = visitor_bay(p)
    first = p['aisles'][0]
    sign_x = first['x0'] - 1.2 if first['x0'] - 1.2 > p['area'][0] + 0.5 else first['x1'] + 1.2
    sign_z = (p['z0'] + p['zr0']) * 0.5
    return {'name': p['name'], 'arabic': p['arabic'], 'clusters': p['clusters'], 'kind': p['kind'], 'north': p['north'],
            'area': rect(*p['area']), 'rows': rows, 'roofs': roofs,
            'aisles': [R((a['x0'], a['z0'], a['x1'], a['z1'])) for a in p['aisles']],
            'buggy_lane': p['buggy_lane']['name'], 'ring_z': p['z0'], 'first_bay_z': p['zr0'], 'last_bay_z': p['zr1'],
            'visitor': {'bay': v3(round(vis[0], 3), 0, round(vis[1], 3)), 'aisle_x': round(vis[3], 3), 'facing': vis[2]},
            'chargers': [v3(x, 0, z) for x, z in chargers(p)],
            'sign': {'position': v3(round(sign_x, 3), 0, round(sign_z, 3)), 'facing': 180.0 if p['north'] else 0.0}}


def _turned_data(p, rect, v3):
    """The turned car park on the real map. Its rows run east-west, so it has 'turned': true,
    each roof's high line is a z ('high_z'), and the ring road kerb, the first and the last bay
    line are x values ('ring_x', 'first_bay_x', 'last_bay_x'). CarParkBuilder.local_park()
    turns it back to build it with the same code as the others."""
    R = lambda a: rect(*world_rect(p, _rect(a)))
    P = lambda x, z: v3(*(lambda w: (round(w[0], 3), 0, round(w[1], 3)))(to_world(p, x, z)))
    rows = [{'area': R((r['x0'], r['z0'], r['x1'], r['z1'])), 'facing': world_facing(p, r['facing']), 'bays': r['bays']}
            for r in p['rows']]
    roofs = []
    for r in p['roofs']:
        high = (r['x0'] + r['x1']) * 0.5 if r['double'] else r['high_x']
        roofs.append({'area': R((r['x0'], r['z0'], r['x1'], r['z1'])), 'double': r['double'], 'high_z': round(-high, 3)})
    vis = visitor_bay(p)
    first = p['aisles'][0]
    sign_x = first['x0'] - 1.2 if first['x0'] - 1.2 > p['area'][0] + 0.5 else first['x1'] + 1.2
    sign_z = (p['z0'] + p['zr0']) * 0.5
    return {'name': p['name'], 'arabic': p['arabic'], 'clusters': p['clusters'], 'kind': p['kind'], 'north': False,
            'turned': True, 'area': rect(*area_of(p)), 'rows': rows, 'roofs': roofs,
            'aisles': [R((a['x0'], a['z0'], a['x1'], a['z1'])) for a in p['aisles']],
            'buggy_lane': p['buggy_lane']['name'], 'ring_x': p['z0'], 'first_bay_x': p['zr0'], 'last_bay_x': p['zr1'],
            'visitor': {'bay': P(vis[0], vis[1]), 'aisle_z': round(-vis[3], 3), 'facing': world_facing(p, vis[2])},
            'chargers': [P(x, z) for x, z in chargers(p)],
            'sign': {'position': P(sign_x, sign_z), 'facing': 90.0}}
