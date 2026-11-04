# Looks pass: the big, detailed build plan (Sessions 53 to 65)

This is the long version of the Looks pass in BUILD_PLAN.md. BUILD_PLAN.md keeps the short
session prompts; this file gives the builder (Claude Code on Michael's Mac) everything needed
to build each session without guessing: which files to open, exact sizes and positions, what
to test, and what Louis should see. Where this file and PRD.md disagree, PRD.md wins (ask
Louis). Nothing here replaces or deletes the earlier sessions.

Written 4 November 2026 from Louis's two play-test lists, with research on the real community,
real shops and layouts, and free CC0 asset packs (sources in PRD.md, "Sources").

Contents:

1. Rules for every session
2. Order and what depends on what
3. Sessions 53 to 65, step by step
4. Appendix A: Plaza blocks and shop order
5. Appendix B: Room template and every interior, metre by metre
6. Appendix C: Car parks
7. Appendix D: Spine cross-section
8. Appendix E: Pools and gym
9. Appendix F: Food and order data changes
10. Appendix G: The layout check (every rule)
11. Appendix H: Real-world sizes for props
12. Appendix I: Frame-rate budget
13. Appendix J: New tests and where they run

---

## 1. Rules for every session

- Read CLAUDE.md, the PRD.md "Looks pass" section and this file's section for the session.
- One session at a time. Small steps: get one thing working, check it, then the next.
- The map is built from data/wahat_al_shams.gd plus builder scripts. Change positions and
  sizes in the data file, never by hand in scene files.
- Tuning numbers (sizes, counts, speeds, densities) go in scripts/game_config.gd in a block
  named after the session, e.g. `# --- Session 53: loading screen and fixes ---`.
- Only CC0 assets (the repo is public). Credit every pack in CREDITS.md with its licence file.
- Every new system gets a check in the smoke test or a focused test (Appendix J). New focused
  tests must also be added to the suite list in tools/build-web.sh so the browser release runs
  them.
- Before handing over: headless import, headless quit, smoke test (RESULT: PASS), the
  focused tests the session touched, and the layout check from Session 53 onwards.
- Screenshots before and after of everything the session changed, at 1920 x 1080, plus the
  frame rate on Low, Medium and High (Appendix I).
- End of session: tick the "Done when" boxes in BUILD_PLAN.md that are really done, update
  PROGRESS.md (what works, how Louis tests it, known bugs) and commit.
- Tell Louis how to test it in simple words: which scene, F5, which keys, what he should see.

## 2. Order and what depends on what

| Session | What | Needs first | Rough size |
| --- | --- | --- | --- |
| 53 | Loading screen, small fixes, layout check | (52 merged) | Medium |
| 54 | Ragdoll falls | 53 | Medium |
| 55 | Schedule I look, textures, real grass | 53 | Medium |
| 56 | Free asset packs, prop library, animation retargeting | 53 | Medium |
| 57 | The Plaza outside (lower shops, flats, pairs, logos, supermarket front) | 56 | Big |
| 58 | First 6 insides + food changes | 56, 57 | Big |
| 59 | Other 6 insides | 58 | Big |
| 60 | Gym and pools | 56 | Medium |
| 61 | C Institute, stable office, farm stall, school booth | 56 | Medium |
| 62 | Car parks and kerbs | 53 | Medium |
| 63 | Spine, farm, stream, beekeeper, horses | 55, 56 | Big |
| 64 | Buggies everywhere, building sites | 56, 62, 63 | Medium |
| 65 | Play-test and fix list | all | Medium |

Sessions 54, 55, 60, 61 and 62 don't depend on each other and can be built in any order
after their "needs first". "Big" sessions may take two sittings: stop at a step boundary,
commit, and write in PROGRESS.md which step is next.

---

## 3. Sessions step by step

### Session 53: Loading screen, small fixes and the layout check

**Louis said:** after you make your character and get accepted it looks frozen, people press
the button again and again. The sunglasses stick out on one side. All the benches face the
wrong way. Cluster signs glitch and one stands in the road. In Cluster 5 roads lie over each
other and don't finish. The farm stall stands on the farm. A hill goes over the pool. The water
runs into the road.

**Files:** scripts/start_screen.gd, scripts/wahat_builder.gd (and the builders it starts),
new ui/loading_screen.tscn and scripts/loading_screen.gd, new scripts/build_queue.gd
(autoload), scripts/rider_look.gd, scripts/wardrobe.gd, scripts/props.gd,
scripts/plaza_builder.gd, scripts/spine_builder.gd, scripts/cluster_signs.gd,
scripts/district_detail.gd, data/wahat_al_shams.gd, new tests/layout_test.gd.

**Steps**

1. *Why it freezes.* Today start_screen.gd calls `change_scene_to_file(GAME_SCENE)` after
   "Accepted" (line ~124) and on Continue (line ~80). Loading the scene is quick; the freeze is
   every builder running its whole `_ready()` in the same frame (500 homes, Plaza, spine,
   people). Measure it first: print the time each builder takes and write the list in
   PROGRESS.md.
2. *Build queue.* Add an autoload `BuildQueue` (scripts/build_queue.gd). Builders register a
   function with a name and a weight instead of building in `_ready()`:
   `BuildQueue.add("Homes C1", 8, _build_cluster.bind("C1"))`. When the game scene is ready,
   the queue runs one job per frame (or several small ones while under 12 ms) and sends
   `progress(done_weight, total_weight, label)`. Split the heavy builders: roads and ground;
   each cluster's homes separately (5 jobs); Plaza; spine; landmarks; cars and traffic;
   people and life; mini-map cache. In headless test runs (`DisplayServer.get_name() ==
   "headless"`) the queue runs everything at once so the smoke test is unchanged.
3. *Loading screen.* ui/loading_screen.tscn: full-screen sand background, Snackaroo logo,
   "Getting your first shift ready…" (Continue: "Getting your shift ready…"), a rounded
   progress bar in orange with the percentage, the current step in small text ("Building
   Cluster 3…"), and a tip that changes every 3 seconds (8 tips in game_config.gd: "Ring the
   bell with B", "Brake before lane corners", "Ice cream melts fast: go straight there",
   "Insurance is cheap, hospitals aren't", "Regulars tip more", "Hold E at the counter to
   pick up", "The red track is for walkers, mind them", "Sprinting uses stamina"). Game
   fonts (Baloo 2 and Nunito) and colours (sand, teal, orange).
4. *Flow.* On the first click of "Submit" / "Continue": disable the button (and Enter), show
   the loading screen in the same frame, then `ResourceLoader.load_threaded_request` the
   game scene (bar 0 to 20% from `load_threaded_get_status` progress), instance it hidden,
   let the BuildQueue run (bar 20 to 100%), then fade the loading screen out over 0.4 s and
   start the shift (clock paused until the fade ends). Show the screen for at least 0.8 s so
   it doesn't flash.
5. *Sunglasses.* rider_look.gd line ~64 places the glasses box at
   `head + Vector3(0, r * 0.05, -r * 0.95)` with width `r * 1.6`. Check where `head` is
   measured from: the box must be centred on the head's middle (x = 0 in the head's own
   space) and the same distance out on both sides. Do the same for every glasses item in
   wardrobe.gd and gear_catalog.gd. Screenshot from the front.
6. *Benches.* props.gd says `facing` is "the way you look when you sit (0 = south)", but the
   backrest is at local z -0.24, so check which way the seat really faces and fix the
   function, not each bench. Then check every bench: PLAZA_BENCHES face the fountain,
   MINI_PLAZAS benches face their playground, spine benches face the path. Add a helper
   `Props.bench_facing(spot, look_at)` and use it in the data where possible.
7. *Cluster signs.* cluster_signs.gd puts a sign at both ends of every side lane, offset to
   the outside of the cluster (`outside * CLUSTER_SIGN_SIDE`), which lands some in the road
   next to the car park and puts posts on top of each other where lanes meet. Change to: one
   sign per lane entrance; offset to the **house side** (towards the cluster middle), 1.0 m
   clear of the lane edge; skip a sign if another sign's post is within 3 m; never inside any
   road rectangle. Two signs per cluster side lane end that faces the spine and the ring
   road, as Louis wants, but no extras.
8. *Roads.* Build a list of every road rectangle. Rules: the ring road, gate roads, highway
   and bus road are "black roads" and win. Any other lane that touches a black road stops at
   the black road's kerb line (shorten it in the data, or clip it in the builder). No lane is
   drawn on top of a black road. Every lane end must touch another road, a plaza, a car park
   or a door spot, otherwise shorten or remove it. Fix Cluster 5 first, then check all.
   Kerbs (0.15 m high, 0.3 m wide, light grey) along both sides of the ring road.
9. *Farm stall.* It stands at (-20, 0, 18), size 9 x 6, on FARM_BEDS Rect2(-40, 13, 35, 8).
   Move it to (4, 0, 17) (check with the layout test) on a 12 x 8 m paved patch, facing
   the spine path. Update TUTORIAL and any door spot that uses it.
10. *Hill over the pool.* HILLS has a hill at (160, 0, 9); the lap pool is Rect2(140, 13, 42,
    9). Every hill keeps 4 m clear of pools, buildings, courts, paths and roads. Move that hill
    to a free spot (the layout test tells you if it's clear) and set every hill's height to at
    most 0.5 m (Session 63 adds more, small ones).
11. *Bridges.* Find every place where STREAM (z 25, x -135 to 405, 3 m wide) crosses a path or
    road. Put a small timber bridge there: deck as wide as the path, 5 m long, arched 0.4 m,
    railings 0.9 m high, the water visible underneath (cut the path mesh where the stream
    is). Bridges are ridable (gentle slope collision).
12. *Layout check.* tests/layout_test.gd (Appendix G for all rules): loads Wahat Al Shams,
    collects every sign, bench, stall, hill, pool, building, post, prop and road rectangle,
    and fails with a clear list ("Sign ClusterSign_C5_3 is inside road 'C5 Lane 2' at
    (301, 188)") if any rule breaks. Run it from the smoke test (quick mode) and on its own
    (full mode).

**Tests to add:** loading test (queue reaches 100%, button disabled after one click, scene
starts once), layout test, a smoke check that the farm stall order still works.

**Louis tests:** F5, make a new rider, press Submit several times quickly: one loading screen,
the bar fills, the game starts once. Ride to Cluster 5: no sign in the road, no road on top of
another. Look at the farm stall, the lap pool, a bridge, the benches at the Plaza fountain,
and your sunglasses in the profile page.

**Done when:** see BUILD_PLAN.md, Session 53.

### Session 54: Ragdoll falls

**Louis said:** the fall is really bad, like a stick man, straight and stiff. Make it ragdolly.

**Files:** scripts/bike.gd (`_begin_fall`, `_step_fall`), scripts/crash_impact.gd,
scripts/rider_look.gd, scripts/clinic_screen.gd, scripts/shift_manager.gd, new
scripts/rider_ragdoll.gd, tests/crash_impact_test.gd, new tests/ragdoll_test.gd.

**Steps**

1. List the bone names in assets/characters/quaternius_human/human.fbx (print the Skeleton3D
   bones). Pick 11 bones: hips, spine (middle), chest/neck, head, upper arm L/R, lower arm
   L/R, upper leg L/R, lower leg L/R (add feet only if it looks better).
2. scripts/rider_ragdoll.gd builds a PhysicalBoneSimulator3D under the rider's Skeleton3D in
   code (the rider is built in code, so don't hand-edit scenes). Capsule shapes sized to the
   limbs. Joints: ConeJoint for hips-to-spine, shoulders, neck and hips (swing 30 to 60°,
   twist 20 to 30°), HingeJoint with angular limits for elbows (0 to 140°) and knees (0 to
   140°, bending the right way). Masses: total about 70 kg.
3. Collision layers: a new "ragdoll" layer that collides with the world and the ground, but
   not with the bike, not with the rider's own capsule, and not with soft characters (keep
   44A's soft-character rule).
4. On a crash (`_begin_fall`): freeze the rider's animation, start the simulation, and give
   the hips and chest an impulse: direction = the captured impact direction (from
   crash_impact.gd), strength from relative speed (about 0.5 x speed x mass, capped), plus a
   small upward kick (1 to 2 m/s) and a little spin so it's never identical. The bike gets
   its own RigidBody3D tumble with the same direction, then is put back upright when the
   rider gets up.
5. Settle: the fall ends when every bone moves slower than 0.3 m/s for 0.5 s, or after 2.5 s
   at the latest (never stuck). Small crash: blend from the ragdoll pose back to the
   get-up animation over 0.6 s, then back on the bike. Big crash: keep the ragdoll lying,
   camera holds on it for 1 s, then the clinic fade (clinic_screen waits for the
   fall-completed signal as now).
6. Camera: during the fall the follow camera keeps the hips in frame and doesn't go through
   walls (reuse the housing camera checks).
7. Low and the browser: 6 bones (hips, chest, head, upper legs, upper arms) and fewer
   physics steps. If the ragdoll ever fails to start (no skeleton), fall back to the old
   authored fall so nothing breaks.
8. Keep 44A's rules: controls locked during the fall, one bill per accident, bounce contacts
   don't count again, insurance is decided at impact.
9. Record 3 short clips (slow bump into a bin, scraping a wall, a hard hit into a car) at
   normal speed and put the frames in the PROGRESS.md notes.

**Tests:** ragdoll_test.gd: for 20 random impacts the fall always ends within 2.6 s, the rider
ends up upright on the bike after a small crash, the clinic opens once after a big crash, no
bone ends up below the ground or more than 10 m away.

**Louis tests:** F5, ride into a bin slowly, a wall at an angle, then a parked car fast. The
rider should flop and roll the way he was hit, then get up (or go to the clinic).

### Session 55: The Schedule I look and real grass

**Louis said:** make it look like Schedule I. The grass is really bad, like triangles and
rectangles; find textures online.

**Files:** scripts/sun_cycle.gd, scripts/settings.gd, scripts/terrain_materials.gd,
scripts/district_detail.gd (`_planting`), assets/textures/, assets/shaders/, new
assets/shaders/grass.gdshader, new scripts/grass_field.gd, CREDITS.md,
assets/textures/sources.json.

**Steps**

1. *Before screenshots* from 6 fixed camera spots (Plaza fountain, a cluster lane, the spine
   by the domes, the school gate, a car park, the stables) at 10 AM and 5 PM. Save the camera
   spots in a little debug list so the after shots match exactly.
2. *Light.* WorldEnvironment: tonemap AgX (or Filmic), exposure about 1.05, saturation about
   1.15, slight contrast; ambient light from the sky at about 0.6 so shadows aren't black;
   sun colour warm white (1.0, 0.95, 0.85); shadow opacity about 0.75 and a little blur;
   gentle depth fog from about 120 m, light sandy-blue. Sky: a clean gradient (or a CC0 Poly
   Haven clear-sky HDRI at 1K or 2K). Put every number in game_config.gd.
3. *Materials.* Matte and simple: roughness 0.8 to 0.9 and low specular on buildings, roads
   and props, so things look clean and cartoony rather than shiny. Keep the warm
   sand/teal/orange palette from the mockup.
4. *Textures.* Replace the 4 photo textures (aerial_grass_rock, asphalt_02, pavement_02,
   sand_01) with clean stylized CC0 ones (OpenGameArt CC0 grass, ambientCG, or textures made
   by a script with flat colour plus soft painted noise). Add: red rubber track, light
   paving, dark asphalt with a fine grain, sand. 512 to 1024 px, tiling with no visible
   seams at 30 m. Record each in sources.json and CREDITS.md.
5. *Grass blades.* scripts/grass_field.gd fills grass areas (spine lawns, Plaza beds, cluster
   gardens, verges) with MultiMeshInstance3D chunks of 32 x 32 m. Blade: 3 triangles, 0.25 to
   0.45 m tall, colour from dark green at the root to light yellow-green at the tip,
   random rotation and height. Density per m²: High 40, Medium 20, Low 6. Visibility range:
   blades fade out from 35 to 45 m (fade mode "self"). Wind: the CC0 "Stylized Multimesh
   Grass" shader from godotshaders.com (copy the code and its CC0 notice), gentle sway, and
   blades bend away from the rider (pass the bike position as a global shader uniform).
6. *Masks.* No grass on paths, roads, pools, courts, beds, under buildings or in water: use
   the layout data rectangles as holes when scattering.
7. Replace the old little green triangles/boxes with the new grass (keep flowers and rocks;
   Session 63 adds more).
8. *After screenshots* from the same 6 spots. Frame rate on Low, Medium, High.

**Tests:** a check that grass chunks exist on Medium, none overlap a road/path/pool rectangle,
and Low has fewer blades than Medium.

**Louis tests:** F5, ride along the spine: soft sunny light, swaying grass, cleaner ground.

### Session 56: The free asset packs

**Files:** new assets/kits/<pack>/ folders, new scripts/kit_props.gd, new
scenes/kit_preview.tscn, CREDITS.md, scripts/person.gd / people_looks.gd (retargeting), new
tests/kit_props_test.gd.

**Steps**

1. Download each pack in the PRD "Free asset packs" table. On each pack's page check it still
   says CC0 (Quaternius now uses a new licence for new packs: skip any page that doesn't say
   CC0). Save the licence file next to the models.
2. Keep only the glTF/GLB files we use (aim for under 60 MB in total). Name folders
   `assets/kits/kaykit_restaurant/`, `kenney_food/`, `quaternius_crops/` and so on.
3. scripts/kit_props.gd: `KitProps.place(parent, "kaykit_restaurant/stove", pos, facing,
   scale := 1.0, snap := "floor")`. Snap modes: "floor" (bottom of the model's bounding box
   at y), "counter" (on top of a counter at 1.05 m), "wall" (back against a wall), "hang"
   (from the ceiling). Every placed model gets a `kit_prop` group and its snap mode as
   metadata so the layout check can test it.
4. Static props are merged with the existing static_batch.gd where possible, so 300 props
   in a room don't cost 300 draw calls.
5. Animations: import the Quaternius Universal Animation Library 1 and 2 (CC0). Make a
   BoneMap from their humanoid rig to our people's skeleton (Godot's SkeletonProfileHumanoid)
   and retarget these clips: swim (crawl), tread water, sit, sit and eat, lie down, jog,
   walk carrying, farming (dig/water/pick), wave, idle variants. Check every clip on our
   person: no bent-backwards knees, no feet through the floor.
6. scenes/kit_preview.tscn: a row of 10 props from each pack on a floor, and 10 people doing
   each new animation. Screenshot it.
7. Write in PROGRESS.md which props nothing covers (espresso machine, mosaic pizza oven,
   shawarma grill, manakish oven, gelato case, pool lounger, treadmill) for the next
   sessions to build from shapes.

**Tests:** kit_props_test.gd: every model file loads, every placed prop's bottom is within 2 cm
of its snap height, every animation clip plays on a person for 2 s without errors.

### Session 57: The Plaza outside

**Louis said:** the shops are way too high and too big; make them smaller and add another row of
the houses on top, joined together. A gap only after every second shop. The bike shop looks
horrible outside; put it in with the others. Grand Groceries must look like a shopping place.
Make the fronts flashier with logos on top. Walkways, grass and palm trees instead of a slab of
concrete. Look up how each place looks in real life.

**Files:** data/wahat_al_shams.gd (RESTAURANTS, SHOPS, RESTAURANT_SIZE, PLAZA, PAVED_AREAS,
PALM_TREES), scripts/place_builder.gd, scripts/venue_builder.gd, scripts/restaurant.gd,
scripts/supermarket.gd, scripts/district_detail.gd (`_plaza_floors`, `_upper`), new
tools/make_logos.py and assets/logos/, scripts/sign_text.gd, scripts/minimap.gd.

**Steps**

1. Follow Appendix A for every block's position, shop order and sizes. Shop units are 12 m
   wide (Grand Groceries 24 m), 14 m deep (10 m public room + 4 m storeroom you can't enter),
   ground floor 4.5 m, three flats floors of 3.2 m, roof parapet 0.6 m with AC boxes and
   solar panels. Flats run continuously over each pair and over the passages.
2. Passages: 4 m wide, after every second shop, a covered walk-through (the flats bridge
   over it) with paving, a ceiling light and a bin. Bikes can ride through.
3. Move Pedal Point Bikes and Dune Drip into the rows (Appendix A). Remove their separate
   buildings and the old door spots; add new door spots at their new fronts. Update the
   mini-map icons.
4. Rename Spill the Tea to **Spill the Brew** (سبيل ذا برو) everywhere: data, signs, phone,
   customer lines, save-file compatibility (old saves that say "boba" still load: map the old
   id to the new one; keep the id "boba" internally if that's simpler and only change the
   names).
5. Logos: tools/make_logos.py writes one SVG per place to assets/logos/ (our own art, simple
   shapes plus the name in Baloo 2): 1000 Pizza (pizza slice in a flame, red), Brain Freeze
   (dripping cone, pink), Spill the Brew (cup with a splash, coffee brown), Shawarma Supreme
   (spit with a crown, amber), Bread & Zaatar (flatbread with a zaatar sprig, wheat brown),
   Grand Groceries (basket, green), Tok Tok Thai (tuk-tuk, purple), Sushi You (sushi roll,
   navy), Mario Bonito (smiling taco, coral), Burgerology (burger in a lab flask, pink),
   Pedal Point (bike wheel, teal), Dune Drip (sun in sunglasses, orange). Godot imports SVG
   as textures.
6. Fronts: a sign band 1.1 m tall across the top of the shop with the logo and both names
   (English and Arabic, checked right-to-left and joined), lit from inside at night (emissive
   after sunset). An awning in the shop's colour. Full-height glass with the inside visible.
   A sliding glass door. Outside: 2 to 4 tables with umbrellas per shop in the shop's colour,
   with people eating at about half of them.
7. Grand Groceries front (Appendix A): double width, wide glass, two sliding doors, a trolley
   bay with 8 trolleys, offer posters in the windows ("Fresh fruit · فواكه طازجة", "2 for 10
   Dh"), a big green sign, a basket stand by the door.
8. Landscape round the Plaza (Appendix A): paved walkways 3 to 4 m wide joining the shops,
   the bus station and the car park; grass beds with Session 55 grass; date palms every 8 to
   10 m; low planters with shrubs and flowers; benches facing the beds; bins and bike racks.
   No bare concrete larger than 10 x 10 m except the sunken square.
9. Smoke test: pick up an order from every shop, both shops still sell.

**Tests:** plaza checks: every shop has a logo sign and a door spot that works; passages
exist after every second unit; no shop's ground floor is taller than 4.6 m; the flats are one
joined mesh per block.

**Louis tests:** F5, ride round the Plaza at noon and after sunset (lit logos).

### Session 58: The first 6 insides and the food changes

**Louis said:** the pizza oven looks nothing like a pizza oven. The ice cream must be in front so
the cashier can hand it over, with signs saying which ice cream is which. The coffee shop is
called bubble tea but it's a coffee shop, and the coffee machines float in the air. The shawarma
place: smaller, not as high, a menu behind the counter. The bread place says cakes and the
oven doesn't look like a bread oven. Make them smaller with lots of seats and people eating.

**Files:** scripts/venue_builder.gd, scripts/shop_interior.gd, scripts/venue_motion.gd,
scripts/restaurant.gd, scripts/supermarket.gd, scripts/counter_panel.gd, scripts/order_maker.gd,
data/customer_lines.gd, data/wahat_al_shams.gd (RESTAURANTS, REGULARS), scripts/game_config.gd,
scripts/meters.gd, scripts/save_game.gd, tools/make_sounds.py, new tests/interior_test.gd.

**Steps**

1. Room template (Appendix B): 12 x 10 m public room, 4.5 m ceiling, front glass at the
   Plaza side. Zones: dining from the glass to 7 m in, the counter line at 7.2 m, kitchen
   from 8 m to the back wall. About 75% of the room is seating (order-at-the-counter style).
   20 to 28 seats inside: wall benches, window bar stools, 2-seat and 4-seat tables.
2. Every room: a menu board on the back wall above the kitchen (4 to 6 real items with Dh
   prices, plus the logo), the cook in the kitchen, a cashier at the till, the pickup spot at
   one end of the counter (separate from the till), drinks fridge, bin, 2 or 3 plants,
   hanging lamps (warm, soft shadows on Medium/High), the floor in the shop's tiles, 1 or 2
   short queue people sometimes (2 to 4 s wait, never more).
3. Build the special machines from shapes (Appendix H for sizes) where no kit has them.
   Everything snaps to the floor or a counter with KitProps; nothing floats.
4. The 6 rooms, exactly as in Appendix B: 1000 Pizza, Brain Freeze Gelato, Spill the Brew,
   Shawarma Supreme, Bread & Zaatar, Grand Groceries.
5. Moving parts: pizza fire flicker and ember particles, the pizza maker sliding a pizza in
   with the peel every 10 s; the gelato server scooping; the barista pulling a shot with a
   little steam; two spits turning slowly with a cook slicing; the baker putting flatbreads
   in the oven; shoppers walking the aisles with trolleys.
6. Sounds per room in tools/make_sounds.py: oven crackle, freezer hum, espresso grind and
   steam, grill sizzle, bakery chatter, supermarket till beeps. Quiet, looped, fade in at the
   door.
7. Food data (Appendix F): Spill the Brew sells coffee, pastries and cake; Bread & Zaatar sells
   bread, manakish and fatayer; fragile cake comes from Spill the Brew; Auntie Mariam orders
   an iced latte, Ms Dana a cake from Spill the Brew; iced coffee spills like bubble tea did.
   Old saves: any "bubble tea" in a save becomes "iced latte".
8. Smoke test: walk into each room, wait in the queue if there is one, hold E, walk out.

**Tests:** interior_test.gd for each room: 20+ seats, a menu board with 4+ items, the pickup
spot reachable from the door on foot, no prop below the floor or more than 2 cm above its snap
surface (except "hang"), nothing blocks the door, ceiling at 4.5 m.

**Louis tests:** F5, take a pizza order, walk in, look at the oven, wait, hold E. Then take an
ice cream order and a coffee order.

### Session 59: The other 6 insides

**Files:** as Session 58, plus scripts/shop_controller.gd and scripts/wardrobe.gd for the two
shops.

**Steps**

1. Using the Session 58 template, build Tok Tok Thai, Sushi You, Mario Bonito and Burgerology
   (Appendix B).
2. Pedal Point Bikes and Dune Drip insides in their new row spots (Appendix B). The shop
   screens (side panel, cart, mirror, your bike on the stand) keep working.
3. Sushi You's conveyor belt really moves (plates travel round on a loop, 0.3 m/s).
4. Smoke test: an order from each restaurant; buy one item in each shop.

**Tests:** interior_test.gd covers these rooms too; shop_test.gd still passes.

### Session 60: Gym and pools

**Louis said:** the pool must be in front of the gym. Make the gym smaller and look up how a gym
looks inside; right now it's a restaurant. The swimmers are just lying there like they're dead.
The hill goes over the pool. Research a community pool; put a fence round it with a small gate.

**Files:** data/wahat_al_shams.gd (GYM, LAP_POOL, COMMUNITY_POOL, HILLS), scripts/district_detail.gd
(`_pool`, `_process` swimmer code), scripts/venue_builder.gd (gym room), new scripts/pool.gd,
new scripts/swimmer.gd, new tests/pool_test.gd.

**Steps**

1. Today `_pool()` lays swimmers on their side (`rotation.z = PI * 0.5`) and slides them with
   a sine wave: that's the "dead" look. Replace with scripts/swimmer.gd (step 5).
2. Gym: 24 x 14 m, 6 m tall, glass wall on the pool side (Appendix E). Inside: cardio by the
   glass facing out (4 treadmills, 3 bikes, 2 rowers), free weights in their own zone at the
   back on rubber floor (squat rack with loaded barbell on a wooden platform, dumbbell rack,
   2 benches, kettlebells), a stretching mat corner, mirrors on the wall opposite the weights
   (not facing the treadmills), reception with the smoothie cooler (the drop-off), water
   fountain, towel stand. People running, rowing, lifting, stretching (UAL animations).
3. Lap pool right in front of the gym's glass wall (Appendix E): 25 x 8 m, 4 lanes with lane
   ropes, 2 m deck, 1.2 m glass fence all round with a 1 m gate facing the spine path.
4. Community pool (Appendix E): fence (1.4 m, metal bars) all round with a small gate; paved
   deck; main pool 25 x 12 m; kids' pool 8 x 6 m right next to the loungers so parents can
   watch; 10 loungers in a row along the long side with 4 umbrellas between them; 2 shade
   sails over the kids' pool; the lifeguard chair in the middle of the other long side; an
   outdoor shower; a 4 x 3 m changing hut; a pool rules sign (bilingual).
5. swimmer.gd: swimmers swim lengths in a lane with the crawl animation, turn at the end, and
   rest at the wall sometimes. Kids in the kids' pool bob and splash (small splash
   particles). Loungers have people lying on them (lie-down pose) or sitting with a drink.
   2 people walk round the deck. Lap pool: 3 swimmers; community pool: 4 swimmers, 3 kids,
   5 on loungers.
6. Move every hill at least 4 m away from both pools and the gym; the layout check passes.
7. Smoke test: a gym order (reception) still works.

**Tests:** pool_test.gd: both pools have a closed fence with exactly one gate; every swimmer
moves at least 5 m in 20 s; nobody is inside the water mesh lying sideways; no hill within 4 m.

### Session 61: C Institute, stable office, farm stall and school booth

**Files:** scripts/venue_builder.gd, scripts/landmark_builder.gd, scripts/farm_stall.gd,
scripts/checkpoint.gd (booth style), data/wahat_al_shams.gd, new scripts/farmer.gd.

**Steps**

1. C Institute lobby (PRD table): two storeys, glass both long sides, balcony with a glass
   railing, stairs, stepped wooden seats with cushions and people on laptops facing the talk
   screen that changes during the shift, hanging plants, wood-slat ceiling, curved white
   reception with the C logo wall (drop-off).
2. Stable office: wood walls, saddles on stands, rosettes and photos, helmets on hooks, a hay
   bale, a window onto the paddock with a horse, the groom at the desk.
3. Farm stall (in its new spot from Session 53): striped awning, fruit and veg crates (Kenney
   food and Quaternius crops), a juice press and cooler, a chalkboard menu (Farm juice, Salad
   box, Dates), and **the farmer** (farmer.gd) behind the counter who hands you the order with
   the side panel, like a restaurant.
4. School gate booth: glass booth with the guard, the barrier, the school wall and sign, a
   teacher waiting for school orders.
5. Smoke test: institute, stables, farm stall and school orders.

### Session 62: Car parks and kerbs

**Louis said:** fill the car park with spaces and sun roofs: one row, then two in the middle
facing each side, then one at the end. Not so big. Almost no space between the car park and the
cluster, just a little road for buggies. Kerbstones between the houses and the car park.

**Files:** data/wahat_al_shams.gd (PARKING_AREAS, PARKED_CARS), scripts/district_traffic.gd
(`_build_solar_bays`, `_solar_canopy`, `_build_access`), scripts/parked_car.gd, new
tests/carpark_test.gd.

**Steps**

1. Follow Appendix C: bays 2.5 x 5.0 m, aisles 6 m, rows 1 | aisle | 2 back to back | aisle
   | 1 wherever there's room, solar roofs over every row, about half the bays with a car
   (random colours from the Kenney car kit), kerbs and a 1.5 to 3 m buggy lane on the cluster
   side.
2. The gaps between C1 and C2, and between C2 and C3, are only 25 m wide today, which is too
   narrow for the full 1-2-1 (32 m plus kerbs and lanes). Use Appendix C's narrow version
   there, and write it in PROGRESS.md so Louis can say if he'd rather move the clusters.
3. Shrink every car park to its rows, so the edge of the last row is at most 3.5 m (kerb plus
   buggy lane) from the nearest home wall. Fill freed space with grass beds, palms and
   building sites, never blank sand.
4. Kerbstones (0.15 m high, 0.3 m wide) along every edge between homes and car park.
5. Cars still drive in and out (district_traffic.gd), only through the access road, never
   through the buggy lane.

**Tests:** carpark_test.gd: every car park has at least 3 rows, every row has a solar roof, no
bay overlaps another, 40 to 60% of bays have a car, every car park is within 3.5 m of its
cluster, no car drives onto a buggy lane.

### Session 63: The spine, the farm and the stream

**Louis said:** the road closest to the domes must be red, it's a walking track. Raise the kerb a
little and make the strip between smaller. Lines so buggies go each side. Small hills, at most
0.5 m. Lots of palm trees and plants round the domes. Make the watermelons and pumpkins more
detailed, the water too. Horses: better textures. Beehives: something round them, a beekeeper.

**Files:** data/wahat_al_shams.gd (ROADS "Spine Path" and "Domes Path", HILLS, FARM_BEDS,
BEEHIVES, STREAM, SPINE_DOMES, HORSE_RIDERS), scripts/wahat_builder.gd (`_build_road`,
`_build_stream`), scripts/spine_builder.gd, scripts/district_detail.gd (`_hill`, `_planting`),
scripts/arena_horse.gd, scripts/life_builder.gd, new scripts/beekeeper.gd.

**Steps**

1. Paths (Appendix D): Domes Path becomes the **red walking track**, 3.5 m, red rubber
   texture, with small "WALK · مشي" markings every 40 m. Spine Path becomes the **buggy
   road**, 6 m, two 3 m lanes, white dashed middle line (1.5 m dash, 1.5 m gap). Between
   them a 2 m strip (was about 6.5 m) with a 0.12 m raised kerb on both sides and low plants.
   The bike can use both; walkers and joggers keep to the red track; buggies keep to their
   lane.
2. Hills: replace HILLS with 10 to 14 gentle hills, 0.25 to 0.5 m high, 10 to 20 m wide,
   smooth (no bumps that throw the bike), at least 4 m from paths, pools, beds, buildings and
   courts.
3. Planting round the domes: around each dome a ring of 3 date palms, 2 fig or pomegranate
   trees and 8 to 12 shrubs and flower clumps (Quaternius nature packs), plus grass. Fruit
   trees also along the paths (date palms, figs, pomegranates, like the real spine).
4. Farm beds: raised beds with wooden edges; rows of watermelon vines with striped melons,
   pumpkin vines with orange pumpkins, tomato plants on sticks (Quaternius crops, mixed growth
   stages so it looks real); drip pipes along each row; a wheelbarrow, a watering can, a
   scarecrow; a farmer NPC who walks the rows and waters (UAL farming animation).
5. Stream (the falaj): pebble banks and stones, papyrus and reeds along the edges, lily pads
   here and there, a gentle flow in the water shader, ducks stay. Bridges from Session 53.
6. Beehives: a low wooden fence round them, flower beds round the fence, a "Bees at work ·
   نحل يعمل" sign, a beekeeper in a white suit and veil with a smoker walking between the
   hives and lifting a lid now and then; a few bee particles.
7. Horses: the Quaternius animated horse (or our horse with a proper texture): coat colours
   brown, chestnut, grey and black, a mane and tail, a saddle and bridle on ridden horses.
8. Frame rate check on the spine (most plants are here): use MultiMesh for repeated plants
   and visibility ranges.

**Tests:** spine checks: red track and buggy road exist with the right widths, every hill is at
most 0.5 m, the farm stall and beds don't overlap, the beekeeper and farmer move.

### Session 64: Buggies everywhere and building sites

**Louis said:** people go round in buggies, good; make them use more of the roads, over the
clusters, but never on the main circle road that connects to the highway. The coming soon
places: add a building that looks almost finished, with scaffolding.

**Files:** data/wahat_al_shams.gd (BUGGIES, BUILDING_SITES, BUILDING_SITE), scripts/life_builder.gd,
scripts/route_mover.gd, scripts/navigation_grid.gd, scripts/district_detail.gd (`_site`),
new scripts/buggy_driver.gd, new tests/buggy_route_test.gd.

**Steps**

1. Build a buggy road graph from the data: every cluster lane, the mini-plaza edges, the
   spine buggy road and the car park buggy lanes. Never the ring road, gate roads, highway,
   bus road, the red track, the blue bike track or the horse track.
2. buggy_driver.gd: 12 to 16 buggies, each picks a random destination node, drives there on
   the graph keeping 1.5 m to the right of the lane middle, at 10 to 14 km/h, slows for
   corners, stops if the rider or a person is within 4 m ahead, waits, then goes. Some carry
   a resident, some a gardener with tools.
3. Building sites: each BUILDING_SITES area gets one half-built building from the CC0
   construction pack: concrete frame 2 to 3 floors, some floors with walls done, scaffolding
   round one or two sides, a crane (keep the existing one), a site fence with "Phase 2 coming
   soon · المرحلة الثانية قريباً" hoarding, piles of blocks and pipes, a site cabin, a cement
   mixer, 3 or 4 workers in hi-vis (some walking, one on the scaffolding). Not enterable.
4. Frame rate check.

**Tests:** buggy_route_test.gd: simulate 600 s; no buggy is ever on a forbidden road; every
cluster gets visited; buggies never overlap each other.

### Session 65: Play-test the looks pass

1. Run everything: smoke, layout check, every focused test, play-test bot careful and
   careless (twice each), frame rate Low/Medium/High at 1920 x 1080 and full screen.
2. Screenshot checklist: loading screen; a ragdoll fall (3 frames); every interior (12
   rooms + gym, institute, stable office, farm stall, school booth); Plaza at noon and night;
   a car park from above; the spine with the red track; both pools; a building site; a
   buggy in a cluster lane.
3. Make a list of anything that still floats, overlaps, flickers or looks plain, fix it, and
   leave the rest in PROGRESS.md for Louis.
4. Louis plays a full shift and writes what felt off.

---

## 4. Appendix A: Plaza blocks and shop order

The Plaza centre is at (-200, -145) (PLAZA in the data). Two shop rows face the square:

- **North row**, fronts facing south towards the square, front line at about z = -188.
- **South row**, fronts facing north towards the square, front line at about z = -102.

(Check these against the current RESTAURANTS z of -195 and -95: units are now 14 m deep
instead of 16, so the fronts move 1 m towards the square. Keep the square's paving clear.)

Units are 12 m wide; passages are 4 m; Grand Groceries is 24 m.

| North row, west to east | Width | x from | x to |
| --- | --- | --- | --- |
| 1000 Pizza | 12 | -240 | -228 |
| Brain Freeze Gelato | 12 | -228 | -216 |
| passage | 4 | -216 | -212 |
| Spill the Brew | 12 | -212 | -200 |
| Shawarma Supreme | 12 | -200 | -188 |
| passage | 4 | -188 | -184 |
| Bread & Zaatar | 12 | -184 | -172 |
| Pedal Point Bikes | 12 | -172 | -160 |

| South row, west to east | Width | x from | x to |
| --- | --- | --- | --- |
| Grand Groceries | 24 | -254 | -230 |
| passage | 4 | -230 | -226 |
| Tok Tok Thai | 12 | -226 | -214 |
| Sushi You | 12 | -214 | -202 |
| passage | 4 | -202 | -198 |
| Mario Bonito | 12 | -198 | -186 |
| Burgerology | 12 | -186 | -174 |
| passage | 4 | -174 | -170 |
| Dune Drip | 12 | -170 | -158 |
| Wahat Pharmacy (scenery only, can't enter) | 12 | -158 | -146 |

Heights: ground floor 4.5 m; 3 floors of flats at 3.2 m (to 14.1 m); parapet 0.6 m (to
14.7 m). Flats: windows 1.4 x 1.6 m every 3.4 m with white sills, small balconies on every
second window on the middle floor, the wall in sand colour, a lighter band between floors.
The flats are joined across each block, including over the passages.

Around the Plaza: walkways 3 to 4 m wide in light paving from every passage to the bus
station, to the car park and to Cluster 1; grass beds 4 to 8 m wide between walkways with a
date palm every 8 to 10 m; planters 1.2 m square with shrubs by the shop terraces; bike
racks by each passage; the cooling towers with seats under them stay in the sunken square.

## 5. Appendix B: Room template and every interior

**Template, 12 m wide (x) by 10 m deep (z), 4.5 m ceiling.** z = 0 is the glass front, z = 10
the back wall. Door in the middle of the front (sliding, 2 m). Counter along z = 7.2 from
x = 2 to x = 10 (1.05 m high, 0.6 m deep), till at the door end, pickup spot at the other end.
Kitchen z = 8 to 10. Menu board on the back wall above the kitchen, 4 x 1.2 m, at 2.6 to 3.8 m
high. Dining z = 0 to 7: window bar with 5 stools along the glass (except the door), a wall
bench along one side wall with 3 two-seat tables, 2 or 3 four-seat tables in the middle. Aim
for 20 to 28 seats. Walkway from the door to the till at least 1.2 m clear. Drinks fridge by
the counter end, bin by the door, 2 or 3 plants in corners, 3 or 4 hanging lamps over the
tables. Storeroom behind the back wall (4 m) has no door you can use.

| Place | Kitchen and counter (the hero) | Dining and decor | Menu board (Dh) |
| --- | --- | --- | --- |
| 1000 Pizza | Round dome oven 1.6 m across, 1.8 m tall, in the back-left corner, covered in small mosaic tiles (red and gold), arched mouth 0.6 m wide with fire glow and flames inside, a logs stack under it, a chimney pipe to the ceiling. Marble prep counter in front of it with dough balls and topping tubs. Pizza maker with a long peel. Stack of pizza boxes on the counter | Black-and-white floor, red chairs, brick-look back wall, a framed Italy photo, basil pots | Margherita 32, Pepperoni 38, Diavola 40, Four cheese 42, Garlic bread 15 |
| Brain Freeze Gelato | Curved glass gelato case 3 m long, 1.2 m tall, **at the front, 2 m in from the door, facing it**, with 12 tubs in 2 rows, each with a little flavour tag (Pistachio, Mango, Chocolate, Strawberry, Vanilla, Lemon, Cookies, Caramel, Coconut, Mint, Blueberry, Date). Server behind it scoops; till at the end of the case; cone stack and toppings jars on top | Pink-and-white stripes, pastel floor, round tables, a big cone sign on the wall | 1 scoop 12, 2 scoops 18, 3 scoops 24, Cone or cup free, Toppings 3 |
| Spill the Brew | Two-group espresso machine on the counter facing customers (0.75 m wide, 0.5 m tall, chrome with red sides), two grinders beside it, milk fridge under the counter, cups stacked on top. Glass pastry case by the till: croissants, cookies, 3 cakes on stands. Barista. Bags of beans on a shelf behind | Wood and plants, window bench with stools, small round tables, a sofa corner with a rug, a plant wall | Flat white 18, Cappuccino 18, Iced latte 20, Croissant 12, Cake slice 22 |
| Shawarma Supreme | Two vertical spits 1 m tall, turning, **in the front window by the counter** so you see them from outside, a cook slicing. Bread stack, sauce bottles, a fries station. The back wall is a lit **picture menu** across the whole width | Arabic patterned tiles on the counter front, a few tables, a drinks fridge with juices | Chicken shawarma 14, Meat shawarma 16, Shawarma plate 28, Fries 8, Fresh juice 12 |
| Bread & Zaatar | Arched stone manakish oven 2.2 m wide in the back middle with a wide low mouth and fire glow; the baker sliding flatbreads in on a long peel. Dough table in front with rolled-out rounds and bowls of zaatar and cheese. Wooden racks and baskets of khubz bread by the counter. **No cake display** | Warm wood, wheat-coloured tiles, hanging bread baskets, a long shared table | Zaatar manakish 8, Cheese manakish 12, Spinach fatayer 6, Khubz bag 5, Mixed box 30 |
| Grand Groceries (24 x 10) | Fruit and veg stand straight inside the door; fridges along the back wall; bread shelf along the side wall; 3 shelf aisles in a grid in the middle (2.2 m wide aisles) with hanging bilingual aisle signs (1 Snacks, 2 Rice and pasta, 3 Home) and yellow price strips; 2 checkouts at the front by the door with belts, sweets and drinks; pickup at checkout 1 | Bright white light, green accents, shoppers with trolleys and baskets | Offer boards instead of a menu: Fruit box 25, Water 6 pack 9 |
| Tok Tok Thai | Open kitchen with woks over flames, a cook tossing noodles | A decorated tuk-tuk inside as a photo spot, red lanterns, bunting and fairy lights, dark wood floor, outside tables | Pad thai 38, Green curry 42, Satay 30, Mango sticky rice 24 |
| Sushi You | Sushi bar with a moving conveyor of coloured plates, a glass fish case, two chefs | Stools at the belt, a booth, paper lanterns, navy curtain over the kitchen, bamboo, a pick-up counter | Salmon roll 28, California roll 26, Nigiri set 40, Miso 10 |
| Mario Bonito | Taco counter with a flat grill and salsa tubs | Colourful tile band, paper bunting, cactus pots | Tacos (3) 30, Quesadilla 32, Guacamole 18, Churros 15 |
| Burgerology | Flat grill with patties, a fryer, a cook | Pink neon "Burgerology" sign, white metro tiles, stools | Classic 35, Cheese 38, Smash double 45, Fries 12 |
| Pedal Point Bikes | Repair stand with a bike, the mechanic at the workbench, tool pegboard, tyre rack | Bikes hanging on the walls, your bike on the turntable when you shop | (price tags on the bikes) |
| Dune Drip | Cashier at a counter | Caps and sunglasses wall, clothes rails, folded hoodies on a table, a rug and a big mirror | (price tags) |

## 6. Appendix C: Car parks

- Bay 2.5 m wide, 5.0 m deep; white lines 0.1 m. Aisle 6.0 m with arrow markings.
- **Full version (1-2-1):** row (5) + aisle (6) + double row back to back (10) + aisle (6) +
  row (5) = 32 m, plus a kerb (0.3 m) and buggy lane (3 m) on the cluster side and a kerb on
  the other side: about 36 m across.
- **Narrow version** for the 25 m gaps (C1 to C2, C2 to C3): double row back to back (10) +
  aisle (6) + row (5) = 21 m, plus kerbs (0.2 m) and a 1.5 m buggy lane on each side: about
  24.4 m.
- Where to use which: the Plaza to C1 gap (about 42 m) and the C4 to C5 gap (about 100 m, two
  full sets side by side or one set plus grass and a building site) get the full version;
  the east-end car park gets the full version if it fits, else narrow.
- Solar roofs: one roof per single row (5.5 m deep), one shared roof over each double row
  (10.5 m deep, posts down the middle line between the two rows, like a real double carport),
  roof at 2.6 m (front) to 3.0 m (back), panels with a thin grid pattern.
- About half the bays have cars (random from sedan, suv, suv-luxury, hatchback, van; random
  colours). A few EV chargers on posts at the row ends.
- The real car parks are at most 85 m from any home; ours are closer: the last row is at most
  3.5 m (kerb plus buggy lane) from the nearest home wall.

## 7. Appendix D: Spine cross-section (north to south, at a dome)

| Strip | Width | Surface | Height |
| --- | --- | --- | --- |
| Domes, planting rings, grass | varies | grass, beds | 0 |
| Red walking track (was Domes Path) | 3.5 m | red rubber | 0.03 |
| Kerb | 0.3 m | grey stone | 0.12 |
| Planted strip (was about 6.5 m) | 1.4 m | low plants, grass | 0.12 |
| Kerb | 0.3 m | grey stone | 0.12 |
| Buggy road (was Spine Path), 2 lanes | 6 m | light asphalt, dashed white middle line | 0.03 |
| Grass with small hills, the falaj stream, farm, pools | varies | grass | 0 to 0.5 |

Kerbs have gentle ramps at every crossing so the bike can cross without crashing.

## 8. Appendix E: Pools and gym

**Gym:** 24 x 14 m, 6 m tall, rounded back, glass wall on the pool side. Inside: 4 treadmills
and 3 bikes in a row 1.5 m from the glass, facing out; 2 rowers next to them; weights zone at
the back on black rubber tiles (squat rack and platform, dumbbell rack, 2 benches, 6
kettlebells); stretching mats in a corner; mirrors on the wall facing the weights; reception
with the smoothie cooler by the door; water fountain and towel stand. 1 to 2 m clear round
every machine.

**Lap pool (in front of the gym's glass):** water 25 x 8 m, 4 lanes with blue and white lane
ropes, deck 2 m all round in light stone, a glass fence 1.2 m high round the deck, one 1 m
gate facing the spine path, a ladder at each end, a bench by the gate.

**Community pool:** inside its plot (COMMUNITY_POOL, 50 x 24 m): metal-bar fence 1.4 m high
all round, one gate (1 m) facing the path; main pool 25 x 12 m with steps at one end and a
ladder; kids' pool 8 x 6 m, 0.5 m deep, right beside the lounger row; 10 loungers along the
long side with 4 umbrellas between them; 2 shade sails over the kids' pool; lifeguard chair
in the middle of the other long side; an outdoor shower; a 4 x 3 m changing hut; a bilingual
rules sign; 2 planters with palms in the corners.

**People:** lap pool 3 swimmers (lengths, crawl); community pool 4 swimmers, 3 kids splashing in
the kids' pool, 5 people on loungers (lying or sitting with a drink), 1 lifeguard on the
chair, 2 walking on the deck.

## 9. Appendix F: Food and order data changes

| Thing | Before | After |
| --- | --- | --- |
| Shop name | Spill the Tea · سبيل ذا تي | Spill the Brew · سبيل ذا برو |
| Spill the Brew foods | bubble tea, coffee | iced latte, flat white, croissant, cake |
| Bread & Zaatar foods | cake, manakish | manakish, khubz bread, fatayer |
| "Fragile cake" special | from Bread & Zaatar | from Spill the Brew |
| Auntie Mariam (C2 Villa 7) | bubble tea | iced latte from Spill the Brew |
| Ms Dana (school gate) | cake from Bread & Zaatar | cake from Spill the Brew |
| Meter rules | bubble tea: medium freshness, spills most | iced latte: same numbers as bubble tea; flat white: goes cold, spills a little; croissant: easy; cake: fragile; bread items: goes cold slowly, easy |
| Customer lines | lines that mention bubble tea, pearls, boba | rewritten for coffee and cake |
| Old saves | "bubble tea" in history and regular counts | read as "iced latte"; regular visit counts kept |

Update data/customer_lines.gd, order_maker.gd, REGULARS, the food tables in game_config.gd,
the phone food icons, the Delivered card icons, and the replay catalog if it lists foods.

## 10. Appendix G: The layout check (tests/layout_test.gd)

The test collects rectangles and points from the map data and the built scene, then checks:

1. No sign, bench, stall, bin, lamp, tree trunk or post stands inside a road, lane, path or
   track rectangle (signs and bollards that belong to the road edge are allowed within 0.5 m
   of the edge, never inside it).
2. No two posts (sign posts, lamp posts, sail posts, fence posts) are closer than 0.4 m.
3. No stall, building, pool or bench overlaps a farm bed, a pool, a court or another building.
4. No hill comes within 4 m of a pool, building, court, path, road or bed, and no hill is
   taller than 0.5 m.
5. Black roads win: no other road rectangle overlaps a black road except where it ends at its
   kerb line (allowed overlap 0.1 m).
6. Every lane end touches another road, a plaza, a car park, a bridge or a door spot.
7. Where the stream crosses a path or road there is a bridge.
8. Every prop with a snap mode sits within 2 cm of its snap surface (floor, counter or
   ground height), except "hang".
9. Every door spot and pickup spot can be reached on foot from the nearest road (navigation
   grid).
10. Benches face something: their facing points within 60° of the target they were placed
    for (fountain, playground, path).
11. Cluster signs: one per lane entrance, on the house side, not in a road.
12. Car parks: within 3.5 m of their cluster; no bay overlaps another (from Session 62).

Quick mode (inside the smoke test) runs rules 1 to 6; full mode runs all.

## 11. Appendix H: Real-world sizes for props

| Prop | Size (m) |
| --- | --- |
| Counter | 1.05 high, 0.6 deep |
| Table | 0.75 high; 2-seat 0.7 x 0.7; 4-seat 1.2 x 0.8 |
| Chair seat / bar stool seat | 0.45 / 0.75 |
| Window bar | 1.05 high, 0.4 deep |
| Espresso machine (2 group) | 0.75 wide, 0.55 deep, 0.5 tall |
| Coffee grinder | 0.2 wide, 0.6 tall |
| Pastry case | 1.2 wide, 0.6 deep, 0.5 tall on the counter |
| Gelato case | 3.0 long, 1.0 deep, 1.2 tall |
| Pizza dome oven | 1.6 across, 1.8 tall, mouth 0.6 x 0.35 |
| Manakish oven | 2.2 wide, 1.4 deep, 1.6 tall, mouth 1.2 x 0.3 |
| Shawarma spit | 0.4 across the meat, 1.0 tall on a 0.9 m stand |
| Drinks fridge | 0.7 wide, 0.7 deep, 2.0 tall |
| Supermarket shelf | 1.0 wide sections, 0.5 deep, 1.8 tall |
| Checkout | 2.5 long, 0.9 high |
| Treadmill | 2.0 long, 0.85 wide, 1.4 tall |
| Rowing machine | 2.4 long, 0.6 wide |
| Squat rack | 1.2 wide, 1.4 deep, 2.3 tall |
| Sun lounger | 1.95 long, 0.7 wide, 0.35 high |
| Pool umbrella | 2.5 across, 2.4 tall |
| Lifeguard chair | 1.8 tall |
| Bench | 1.8 long, 0.45 seat |
| Parking bay | 2.5 x 5.0 |
| Golf buggy | 2.4 long, 1.2 wide, 1.8 tall |
| Kerb | 0.3 wide, 0.12 to 0.15 high |

## 12. Appendix I: Frame-rate budget

Measured at 1920 x 1080 on Louis's Mac, at the Plaza and on the spine, riding:

| Setting | Target | If it's slower |
| --- | --- | --- |
| High | 60 fps | lower grass density, shadow distance |
| Medium | 60 fps (must) | merge static props, MultiMesh, visibility ranges |
| Low (iPad and browser) | 30 fps or more | fewer blades, 6-bone ragdoll, no interior lamp shadows |

Interiors: only the room you're in (and rooms seen through glass within 30 m) has its props
and lights active; others are hidden or use a simple low version.

## 13. Appendix J: New tests and where they run

| Test | Added in | Runs in |
| --- | --- | --- |
| tests/layout_test.gd | 53 | smoke (quick), release suites (full) |
| tests/loading_test.gd | 53 | release suites |
| tests/ragdoll_test.gd | 54 | release suites |
| grass checks | 55 | detail_world_test.gd |
| tests/kit_props_test.gd | 56 | release suites |
| plaza checks | 57 | smoke |
| tests/interior_test.gd | 58, 59 | release suites |
| tests/pool_test.gd | 60 | release suites |
| tests/carpark_test.gd | 62 | release suites |
| spine checks | 63 | detail_world_test.gd |
| tests/buggy_route_test.gd | 64 | release suites |

Add each new suite to the list in tools/build-web.sh (the `for suite in (...)` list) so the
browser version only updates when they pass. Keep the whole release run under 15 minutes.
