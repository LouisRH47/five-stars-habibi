# Progress

## Current session
Session 4: Palm Grove part 1, roads and villas (built, waiting for Louis to test on the Mac).
Sessions 1 to 3 and the review fixes also still need testing on the Mac.

## What works
- Godot 4.7 project (Forward+). The main scene is `scenes/palm_grove.tscn` (since Session 4).
  The old flat test area is `scenes/test_area.tscn`.
- Flat sandy test area with 8 coloured boxes to ride around.
- A simple bicycle with a rider and an orange delivery box, made from basic shapes.
- Controls (set in Project > Project Settings > Input Map):
  - W / Up arrow: pedal
  - S / Down arrow: brake, then roll slowly backwards
  - A / D or Left / Right: steer (only works while moving)
  - Space: handbrake
- Top speed 25 km/h. Riding into a box stops you; glancing hits slow you a little.
- Camera follows from behind and above, smoothly (physics interpolation is on).
- All tuning numbers are in `scripts/game_config.gd`.
- Tested headless with Godot 4.7.2: no script errors, the bike speeds up, steers,
  stops, and can't go through boxes.

### Session 2
- Gentler start: you speed up fastest from a standstill and ease off near top speed.
- Hold Shift while pedalling to sprint up to 32 km/h. Sprinting drains the stamina bar
  (about 4.5 seconds from full). Pedalling normally refills it slowly, coasting refills it fast.
- If stamina runs out the bar turns orange and you can't sprint until it's back to 25%.
- The rider leans into turns (up to 14 degrees at full speed).
- Hitting a box gives a camera shake; harder hits shake more.
- Bottom-right panel shows speed in km/h and the stamina bar (`ui/hud.tscn`).
- Tested headless: sprint reaches 32 km/h, stamina drains and refills, lean and bumps work.

### Review fixes (after Session 2)
- PRD tidied: one rating window (last 50), meters have green/orange/red bands and a
  time target, star formula written down, Heat renamed Freshness, XP builds a Rider
  Level for gear, acceptance rate rule, first big crash is free, insurance starts on,
  controls table, vision sections marked NOT NOW.
- BUILD_PLAN reordered: delivery loop (Session 3) now comes before the Palm Grove map,
  the map is split into three sessions and built from a data list, obstacles come
  after the meters, menu/saving and sound/music are separate sessions. 17 sessions.
- Esc pauses and resumes (`ui/pause_menu.tscn`), with Resume and Quit buttons.
- R puts the bike back at the start. Falling off the world also puts it back.
- Invisible walls around the edge of the test area, so you can't ride off it.
- Base screen size 1920x1080 with scaling, so the panels look the same on any screen.
- The wheels now spin with the bike's speed.
- A smoke test in `tests/smoke_test.gd` rides the bike headless and checks it moves,
  sprints, drains stamina and brakes. Command is in CLAUDE.md.
- The HUD script was attached twice (scene + main); now only in the HUD scene.

### Session 3
- Three restaurants (Pizza, Brain Freeze Gelato, Boba Oasis, teal) and ten villas
  (numbers 1 to 10, cream) stand around the test area. They're built when the game
  starts from the list in `data/test_area_places.gd` by `scripts/place_builder.gd`.
  Move a building by changing its line in the list.
- Signs are English only for now. Arabic + English signs come in Session 5.
- `scripts/game_state.gd` is an autoload called GameState: the only place that keeps
  money, the delivery history, the current order and your accept/skip record.
- `scripts/order.gd` describes one order. `scripts/delivery_manager.gd` runs the loop.
- The phone (top right, `ui/phone.tscn`) shows your wallet, new orders with a 30 s
  countdown, and where to ride next. E accepts, Q skips, ignoring an order counts as a skip.
- A see-through orange beam marks the next stop. Within 3.5 m of the door, the
  "E" hint turns orange and E picks up or drops off. Delivering adds the pay (8 to 15 Dh,
  more for longer rides) and the phone shows "+12 Dh  Delivered!".
- Skipping a lot (accepting under 70% of your last 20 orders) gives short, 8 Dh orders.
- All new numbers are in the Orders block of `scripts/game_config.gd`.
- The smoke test now also does one full delivery, a skip, a boring order and a timeout.
- Built and checked by reading (a builder, three reviewers and a fixer). Godot could not
  be run in the cloud session, so nothing has been run yet.

### Session 4
- Palm Grove is now the main scene (`scenes/palm_grove.tscn`), so F5 starts there.
- Everything comes from the data list `data/palm_grove.gd`: roads, the roundabout,
  the walls and gate, the 3 restaurants and 36 villas. Change a line to move something.
- `scripts/map_builder.gd` builds the sandy ground, grey roads, the roundabout with a
  solid grass island, a sandstone wall all round and a red closed gate in the south.
- Roads: Palm Grove Avenue runs north from the gate through the roundabout. Date Palm
  Street, Oasis Street and Ghaf Street cross it, joined by West Lane and East Lane.
- Villas are `scenes/villa.tscn` (built by `scripts/villa.gd`): a house in one of four
  colours with a teal roof edge, two windows, an orange door and a teal plate with a big
  white house number above the door, facing the street. Numbered 1 to 36 street by street,
  starting nearest the gate.
- The 3 restaurants stand in a row just inside the gate, still as simple teal boxes with
  English signs (Session 5 makes the proper restaurant strip with bilingual signs).
- The bike starts just inside the gate, facing up Palm Grove Avenue.
- The bike is its own scene now (`scenes/bike.tscn`), shared by both maps.
- `scripts/place_builder.gd` takes its data list from the scene, so the same script
  builds the test area and Palm Grove. Orders now use the real villas.
- Pay per metre lowered to 0.03 Dh so the bigger map still pays 8 to 15 Dh.
- The smoke test runs on Palm Grove by default and checks the villas were built.
- Not run yet: Godot can't be run in the cloud session. Checked by reading and by a
  separate reviewer.

## Known bugs
- None found yet. Not tested on a real screen yet.
- The review fixes and the smoke test were written without Godot available, so the
  first run on the Mac is the real check. If the smoke test prints an error, paste it in.

- New scripts with class_name need Godot to refresh its class list once. Opening the
  project in the Godot editor does it. If F5 shows "Could not find type Order" or similar,
  close and reopen the project in the editor.

## Next
- Louis tests Sessions 1 to 4 and the review fixes with the checklists in BUILD_PLAN.md.
- Then Session 5: Palm Grove part 2, restaurants and bilingual signs.
- Open question for Louis: rides in Palm Grove take up to about a minute, the PRD hoped
  for 2 to 3 minutes. See "Still open" in PRD.md.
