# Review (outdoor): an overnight check of the outside world, Sessions 53 to 64

Done by Claude on 4 November 2026 (night), branch `looks-review-outdoor` (from `looks-build`
a98d3cf), with fresh eyes: I didn't build any of this. I read PRD.md "Looks pass", the "Done
when" boxes for Sessions 53 to 64, PROGRESS.md and the session notes, then rendered the world
with the real Forward+ renderer from about 70 spots a rider would see (2 m up, and some higher
views; 10:00 and 17:00) and looked at every picture.

Scope: everything outside. Shop and restaurant insides were left alone (another agent is on them).

Before/after pictures: `/home/claude/out/review_outdoor_*.png`.
The render names below (like `bridge_c4_top`) are the camera spots I used; the list of spots is
at the end so anyone can render them again with `tests/_shots.gd`.

## What I found and fixed

| # | Problem (what you'd see) | Picture | Fix | Switch (false = old way) |
|---|---|---|---|---|
| 1 | **Flower balls floating in the air** all over the spine, 30 cm up with their shadow below them, and some lying on roads and paths (two on the C4 Link road by the bridge). They were the old Session 26 "SpineFlowers", left on when Session 55 hid the old grass tufts they sat on. | `bridge_c4_top`, `bridge_c4` (review_outdoor_flowers_on_road.png) | They sit on the ground (or the hill) now, and keep off every road and path (with 40 cm to spare), paving, car parks, building sites, the stream, the bee yard, the donkey pen, the gym, the stall, the dome flower beds and the door/gate aprons. 97 left. | `SPINE_FLOWERS_GROUNDED` |
| 2 | **Flicker where the cluster links meet the spine buggy road.** The C1 to C5 links (and the Western and School links) were drawn to the middle of the buggy road, two road slabs at the same height in different greys, so they fought (stripes on the road at the C5 link). | `pool_gate_crossing` (review_outdoor_link_flicker_kerb_gap.png) | A path that ends on a road that "wins" now stops at that road's edge. Black roads win, then the spine buggy road, then any wider road. Same-width lanes still meet as equals (so cluster corners stay filled). | `ROAD_ENDS_GIVE_WAY` |
| 3 | **Light lanes lying over dark roads** (Louis: "one road lying over another"): the 8 car park buggy lanes were drawn 4 m onto Plaza to C1 / South Spine Link, the cluster alleys and cross-row alleys 5 m into the lanes, Institute Access, School Link and Stables Link onto School Road. | `c2_buggy_lane_end`, `c3e_buggy_lane` (review_outdoor_buggy_lane_over_road.png) | Same fix as 2. The data didn't change, so buggies still find the same junctions. | `ROAD_ENDS_GIVE_WAY` |
| 4 | **Kerb gaps leading nowhere.** The kerbs and planted strip between the red track and the buggy road had a "dropped kerb" gap (with plain grass in it) at the C4 and C5 links, which come from the south and end at the buggy road: they never cross the strip. | `pool_gate_crossing` | Only paths that really cross the strip cut it (Institute Access, C1, C2 links and the dome crossings). | `SPINE_GAPS_ONLY_REAL` |
| 5 | **The farm stall stood on the lawn.** PRD: "move it to the side of the bed, **on paving**". It was beside the bed (good) but on grass. | `spine_high`, `farm_stall`, `farm_stall_top` (review_outdoor_farm_stall_paving.png) | A paved pad under the stall with a 3.5 m forecourt in front of the counter, and a 2.4 m paved path north to the buggy road (beside the palm, not through it). | generator `REVIEW_STALL_PAVING` |
| 6 | **Light blue ground round the C Institute**, 126 x 48 m. It was the old map colour of the institute's plot and looked like water or a hole in the world from the road. | `institute`, `institute_front2`, `institute_top` (review_outdoor_institute_lawn.png) | The plot is a lawn now (grass texture and real grass blades), like the spine it faces. The minimap shows it green. | generator `REVIEW_INSTITUTE_LAWN` |
| 7 | **"Coming soon" words hanging in the air** at the 4 small building sites (white letters with nothing behind them, 2.6 m up). | `site_plaza3` | A dark board behind the words on two posts. | `SITE_SIGN_BOARD` |
| 8 | **Pool decks were a plain light slab** (PRD: "a paved deck"). | `comm_pool_deck`, `comm_pool_high` | Both pool decks use the paving texture. | `POOL_DECK_PAVED` |
| 9 | **The big "Wahat Stables" sign was half hidden** behind the stable office roof (Session 61 put the office right in front of the middle of the block). | `stables` | The sign moved 13 m along the block, clear of the office. | `STABLES_SIGN_SHIFT` (0 = old spot) |
| 10 | **Play-test bot stuck for the rest of the shift** (both careful and careless): on foot at Shawarma Supreme (and in another run at Grand Groceries) it pushed against the glass beside the door for 7 minutes and the shift never ended. The pickup spot (Session 58) is inside, off to the side of the sliding door; the bot's map scan saw the door shut, so it walked in a straight line into the glass, outside the door's 3.2 m reach. A player steers to the door, so this was the bot, not the game. | bot logs | The bot now goes through the doorway (just outside the door, or 1 m inside it) whenever it has to cross a Plaza shop's glass, in and out, like a player. It also prints why a long walk might not move (paused, walker active, stage). | (test code only) |

## New checks (so these can't come back)

- `tests/layout_test.gd` (runs in the smoke test too):
  - "no path end is drawn onto a road that wins": with `ROAD_ENDS_GIVE_WAY = false` it lists 39
    path ends (the links, alleys, car park lanes...), with it on, none.
  - "spine flowers sit on the ground, none on a path".
  - "the farm stall stands on paving".
- `tests/spine_test.gd`: "no kerb gap where no path crosses (C4 and C5 links)", and the
  "kerbs stop where paths cross" check uses the real crossings.

## Tests run (all on this branch, after the fixes)

Smoke test RESULT: PASS (with the 3 new layout checks). layout (14 checks), spine (40),
coplanar (0 flicker pairs), grass (13), detail_world (27), pool, venues, minimap_cache,
static_batch, navigation, carpark (23) and buggy_route `-- sites`: all PASS.

## What I looked at and found fine

The Plaza (both rows, flats joined over the passages, a passage after every second shop,
Grand Groceries' supermarket front, sign bands with logos, Arabic joined and right-to-left on
every sign I could read, benches facing out, planters, beds with grass), the back of both rows,
every cluster entrance I rendered (C1, C2, C4, C5 from the ring road; C1, C3, C5 from the spine:
one sign beside the lane on the house side, readable, not in the road, bollards in place), the
car parks (1-2-1 rows, solar roofs, about half full, kerbs, buggy lanes, the turned C3 East one),
the red track, kerbs, strip and dashed buggy road, dome planting, the hills (gentle, clear of the
pools), the gym and lap pool (glass fence and gate, swimmers), the community pool (fence, one
gate, kids' pool with sails, loungers, lifeguard, hut), the farm beds, the bee yard (fence, sign,
beekeeper), the stream (pebbles, reeds, lily pads) and both bridges, the half-built buildings with
scaffolding and cranes, the school gate booth and barrier, the stable office and paddock, the
institute's glass front, the ring road kerbs with openings, palms (none in a road: I checked all
231 in the data).

## Play-test bot (after the fixes)

| Run | Deliveries | Stars | Earned | Crashes | Stuck/reset | Notes |
|---|---|---|---|---|---|---|
| Careful (before the bot fix) | 3 | 4.50 | 69 Dh | 1 small | 0 resets, but **stuck 7 min at Shawarma Supreme's glass**, shift never ended | fixed (row 10) |
| Careful | 5 | 5.00 | 87 Dh | 1 small (the gardener by the Cluster 4 playground) | 0 | |
| Careful (final bot) | 5 | 4.80 | 110 Dh | 0 | 0 | No-crash goal done |
| Careless (final bot) | 5 | 4.40 | 78 Dh | 6 small | 0 | careful pays clearly more |
| Careless, 5 other runs | 0 to 2 | | 0 to 26 Dh | | | 3 ended early with a **big crash in the Plaza** (20 to 27 km/h into an outside table or a bed palm: the clinic ends the shift); 2 got **stuck on foot inside Burgerology** (below) |

**Stuck inside Burgerology (seen twice, not found):** in two careless runs the rider stood at
(-177.95, -101.02), 3.5 m in front of Burgerology's counter, "going to the bike", and never moved
again (not even turning), so the shift never ended. Static things don't trap that spot (I checked
with physics queries: the rider can move 1 m every way). In the second run the bot's new doorway
step didn't kick in, which suggests there was no current order at that moment. It didn't happen
again in 3 more careless runs. The bot now prints the pause state, whether the walker is active,
the stage and the order when a walk takes long, so the next run that hits it says why. Burgerology's
inside is Session 59 (not built yet) and insides belong to the other review, so I didn't dig into
the room code.

## Not fixed, and why

- **The bot's one small crash at the Plaza** (careful rider, 11 km/h, Spill the Brew's outside
  table next to the door spot). The tables stand 2.6 m in front of the glass with 4.4 m between
  them at the door; a player fits, the bot's 1 m clearance grid clipped one. Left as it is.
- **The Plaza Link's angled end** at the Plaza's west walkway leaves two small sand triangles
  (`plaza_link_top`). Small; a paved apron would fix it.
- **Frame rate**: not measurable here (no graphics card). The changes add almost nothing (a few
  boards and slabs; fewer flowers).

## For Louis to decide

1. **The big sand field between the Plaza and the Cluster 1 car park** (about 50 x 160 m, x -142
   to -92). The walkway from the Plaza to the car park crosses bare sand
   (`plaza_east_walk`, `plaza_overview`). Grass beds and palms like the Plaza, or keep it desert?
2. **The main building site (west of Cluster 4) is a huge empty concrete pad** (110 x 135 m) with
   the half-built building only along its south edge (`site_main`). More buildings on it, or make
   the site smaller?
3. **The shade sails over the Plaza's sunken square are low** (4 to 4.9 m) and big: riding in the
   square at 2 m eye height, a sail fills the top of the screen (`plaza_north_row`,
   `plaza_sunset`). Raise them to about 6 m?
4. **The C Institute's short sides are blank 36 m walls**: the north one faces the Plaza's building
   site and the walkway behind the south shops (`site_plaza3`). Windows or a mural?
5. **PRD "More detail outside"** asks for a juice kiosk and string lights at sunset in the Plaza.
   No session in 53 to 64 planned them, and they aren't in the game. Add them to Session 65?

## Merge risks (for the lead)

- `scripts/game_config.gd`: a new section at the end ("Review (outdoor)").
- `scripts/wahat_builder.gd`: `_build_road` (4 lines) and three new static functions
  `drawn_ends`, `gives_way_to`, `on_road` (+ `_shares_end`).
- `scripts/district_detail.gd`: `_planting` (the flower part), new `flower_clear`, `_site`
  (board call), new `_sign_board`.
- `scripts/spine_paths.gd`: `build` (gaps) and new `strip_gaps`.
- `scripts/pool.gd`: `_deck_round` (2 lines). `scripts/landmark_builder.gd`: `_build_stables` (sign x).
- `tools/build_wahat_data.py`: a block just before the file is written (stall paving, institute
  plot colour); `data/wahat_al_shams.gd` regenerated (2 paved areas, 1 plot colour).
- `tests/layout_test.gd` (3 checks + `_old_ends`), `tests/spine_test.gd`, `tests/playtest_bot.gd`
  (`_walk` calls the new `_via_doorway`; `_say_walk_trouble` prints more).

## Louis's check

1. Open the project in Godot and press **F5**. Start a shift.
2. Ride onto the spine and look along the grass: no coloured balls floating any more; the little
   flowers sit in the grass and none lie on the roads.
3. Ride along the grey buggy road past where the cluster roads join it (for example below
   Cluster 5): the join is clean, no shimmering stripes, and the white dashes stop neatly.
4. Look at the kerbs between the red track and the buggy road at the Cluster 4 and 5 roads: the
   kerb runs straight on (no grassy gap).
5. Ride up a car park's light buggy lane to the road at its end: it stops at the road's edge.
6. Go to the Farm Stall: it stands on paving with a path to the buggy road.
7. Ride to the C Institute (west end of the spine): green lawn round it, not light blue.
8. Look at a building site's "Coming soon" sign: it's on a dark board with posts. Look at the
   pool decks (paving) and the stables (the big sign is to the right of the little office).

## Camera spots used (name: x,y,z : look at x,y,z : hour)

Before (in /tmp/ro_shots while this machine lives) and after (/tmp/ro_after):
plaza_north_row -200,2,-160 : -200,3,-186 : 10 · plaza_south_row -215,2,-125 : -215,3,-104 ·
plaza_gg -242,2,-120 · plaza_passage_n -214,1.8,-178 · plaza_overview -200,45,-55 · plaza_beds
-262,2,-150 · plaza_west_walk -278,2,-145 · plaza_back_north -200,2,-213 · plaza_sunset (17:00)
· plaza_south_passage -200,1.8,-112 · c1/c2/c5 ring entrances (x 48/203/303, z -213/213) · c4
ring 73,2,213 (17:00) · c1/c3/c5 spine entrances · c5_overhead · c3_east_lanes · c1_carpark_high ·
c1_buggy_lane · c23_narrow (17:00) · c4w_carpark · c3e_carpark · spine_dome70 · spine_track ·
spine_high · spine_dome250 (17:00) · spine_hills · lap_pool · lap_pool_side · gym_door ·
comm_pool_gate · comm_pool_high · comm_pool_deck · farm_stall · farm_beds · bee_yard · bridge_c4
· bridge_c5_side (17:00) · bridge_rider (17:00) · site_c4c5 · site_main · site_plaza3 · site signs
(3) · school_gate · stables · institute (3) · ring_kerb_n · ring_kerb_s (17:00) · track ends (2) ·
pool_gate_crossing · c1/c5 link junctions · alley_t · c1_miniplaza · plaza_east_walk ·
plaza_link_top · plaza_west_top · plaza_bikes · plaza_dunedrip · c5_sw_corner · c3_ne_corner.
