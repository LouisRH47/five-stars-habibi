# Progress

## Browser distribution — 3 November 2026

- Added a single-threaded browser export, a Play/loading screen, and web-only Low
  graphics settings. Desktop Forward+ stays enabled for desktop builds.
- Added multi-touch driving buttons for testing on iPad in landscape.
- GitHub workflow checks pull requests, deploys successful main builds to
  `fivestarshabibi.middleleap.com`, and packages tagged releases. Publishing
  requires the Cloudflare credential described in `docs/WEB_RELEASE.md`.
- Added a separate preview deployment and a live WebAssembly decoding check.
  A small Pages Worker serves the compressed engine with manual encoding to
  prevent Cloudflare from compressing it twice. Other assets remain static.
- Made the traffic smoke probe start from a fixed route position, so a randomly
  spawned buggy's normal endpoint pause cannot fail the deployment checks.
- Browser saves stay on the current device. Real iPad performance still needs
  Louis's test; emulated touch checks are not a physical-device acceptance test.
- Safari/iPad follow-up: touch menus, name fields, settings sliders and country
  choices now have at least 44 CSS-pixel targets. Gameplay labels are larger and
  use plain actions. Layout checks cover landscape, portrait and browser bars.
- The web canvas now respects device safe areas and caps Retina rendering to one
  backing pixel per CSS pixel after Safari/WebKit graphics failures. Software
  keyboard fields keep viewport positioning and a 16-pixel font to avoid offset
  and automatic-zoom problems during name entry.

## Current session
**Detail and replay implementation is ready for playtest** on `codex/detail-pass-complete`.
The 940×500 m district has 500 joined homes, walk-in venues and shops, traffic,
severity-based falls and bills, and the full Tier 1 replay loop. The clock remains
8 AM–6 PM at one active real second per game minute. The temporary clock-check
banner was removed; ordinary gameplay shows the normal clock.

All five Wahat smoke runs and the Palm Grove/test-area runs pass (2,664 checks).
Focused integration, crash, traffic, shop, replay, route, camera and UI checks pass.
Medium/1920×1080 on Apple M3 Metal clears 60 fps at the three sampled game views.
Five careful shifts earned 645 Dh, the GPS was bought after shift one and the
first frame is affordable on shift five when following the upgrade goals.

Mac and Windows builds are packaged. The Mac menu and packaged Wahat scene
launch; Windows runtime, human acceptance and itch.io publishing remain open.
See [docs/implementation-status.md](docs/implementation-status.md) for evidence.

### Previous completed foundation

**Session 35A is built** on `codex/detail-pass-35a`, from main `ac47818`.
The corrected clock advances one game minute per active real second, so the
8:00 AM–6:00 PM shift lasts ten real minutes. It shows every minute, with AM/PM
and a small sun icon; event messages use the same clock. **Next: Session 35B**, the real-size placeholder map, 500 addresses
and route/pacing checks. The playable map is still the Session 34 layout.

**Planned addition (44A–44B):** rider/bike falls before recovery or hospital, with
reactions based on collision direction, speed and obstacle hardness, then
severity-based treatment/repair bills and capped insured payments. Keep the
boss-covered first major crash and one charge per accident. This is planned
work after Session 44; the current crash animation and prices are unchanged.

**Sessions 18 to 34 are built** (the polish pass and the graphics pass), on branch
`polish-and-graphics`. Each one passes the Godot checks and the smoke test on all three maps;
Wahat Al Shams passes 5 runs out of 5. Sessions 26 to 33 were built by helper agents in
parallel and merged together. They still need Louis's own play-test on the Mac.

**Louis played the graphics pass (3 Nov).** He likes the houses, playgrounds, stables and the
number of NPCs. **Next: Sessions 35 to 46, the Detail pass**, in BUILD_PLAN.md: Wahat Al Shams at
real size copied from the real community (joined rows of 500 homes, solar car parks between
clusters, horse and cycle tracks, checkpoints, bus station), ten-minute shifts with an AM/PM clock,
walk-in restaurants with spoof names, Fair Grade International School, the C Institute, the gym
and pools, hills and textures, building sites on the empty patches, a faster-feeling bike, the
camera fix, and two shops (Pedal Point Bikes with upgrades and a rocket booster, Dune Drip
clothes) with a cart and checkout. Sketches are in docs/. Then Sessions 47 to 51, "Reasons to
come back" (the old Sessions 36 to 40; the old gear shop Session 35 is now Session 45).

Things Louis noticed that the Detail pass fixes: the clock looks like a sped-up timer, the camera
goes inside houses, villas should be joined rows, a warpy smear in front of the bike (the heat
shimmer), some NPCs have no head, the dome doors flicker, the school is hard to find, buggies
drive on the ring road, and riding feels slow.

Sessions 7 to 17 are built (all of Tier 1), each checked with the Godot headless checks,
the smoke test and screenshots, on branch `sessions-8-17` (Session 7 on `session-7-minimap`).
Louis asked for all of them in one go; they still need Louis's own play-test on the Mac.

**Godot checks on the Mac (start of Session 7):** the headless import, the quit check and
the smoke test all ran on Godot 4.7.2 for Sessions 1 to 6 with no errors and RESULT: PASS,
on both Palm Grove and the test area. Nothing needed fixing.

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

### Session 5
- Font: Noto Sans Arabic (`assets/fonts/`, free SIL Open Font License, credited in
  `CREDITS.md`). One font does both the Arabic and the English line on every sign.
- `scripts/sign_text.gd` makes the sign text: flat, bold, Arabic line on top, English
  below. Free-standing signs get a second face on the back so they never read mirrored.
- Welcome sign (the Arabic test sign): "Welcome to Palm Grove / أهلاً بكم في بستان النخيل",
  on two posts ahead on the right as soon as you start.
- Restaurant strip: Pizza, Brain Freeze Gelato and Boba Oasis now stand side by side just
  inside the gate (`scenes/restaurant.tscn`, `scripts/restaurant.gd`). Each has a brand
  colour (red, pink, purple), an awning, shop windows, a glass door, a big bilingual sign
  board and a blade sign sticking out so you can read it while riding up the avenue.
  Orders pick up at their doors.
- Street signs: every road has a bilingual name sign near each end (12 in all), built by
  `scripts/sign_builder.gd` from the road list. Plates run along the road, so you read them
  from the crossing street, like real street signs. The avenue's gate end has one facing you.
- The Arabic names are in `data/palm_grove.gd` next to the English ones.
- The smoke test checks the font has Arabic letters and every restaurant and street sign
  has Arabic and English text. It can't check that the letters look joined: Louis checks that.
- Not run yet: Godot can't be run in the cloud session. Built and checked by reading
  (a builder, four reviewers, skeptics, a fixer and a final reviewer).

### Session 6
- `scripts/decor_builder.gd` builds everything below from new lists in `data/palm_grove.gd`.
  `scripts/low_poly.gd` is a small shared helper for boxes, cylinders and spheres.
- Mosque north of Ghaf Street, facing it: prayer hall, dome, minaret, forecourt, sign
  "Palm Grove Mosque / مسجد بستان النخيل" (`scenes/mosque.tscn`).
- Park on the west side north of Ghaf Street: grass, paths, shade trees, palms, benches,
  a fountain, sign "Palm Grove Park / حديقة بستان النخيل" (`scenes/park.tscn`).
- Al Sarab Mini Market east of the avenue by the gate, with a car park and bay lines,
  sign "Al Sarab Mini Market / ميني ماركت السراب" (`scenes/supermarket.tscn`).
- 37 palm trees (avenue, roundabout island, mosque, market, park), solid trunks.
- 16 parked cars (solid) in the car parks and on villa driveways, clear of every door spot.
- 10 speed bumps on the streets (none on the avenue near the gate). They're a trigger, not
  a solid block: the bike rolls up and over (nose up, nose down), hops more when fast,
  the camera shakes, and above 10 km/h you lose speed (down to 55% at full speed).
  Each bump adds 1 to `bumps_taken` and sends `went_over_bump`, ready for Session 8's
  damage meter. Numbers are the `SPEED_BUMP_*` block in `scripts/game_config.gd`.
- The smoke test checks every palm, car and bump was built, the mosque/market/park signs
  have Arabic, and rides the bike over a speed bump.
- Layout checked with a script: nothing overlaps roads, buildings, signs, doors or walls.
- Not run yet (no Godot in the cloud session). Built and checked by reading.

### Session 7
- Mini-map in the bottom-left corner (`ui/minimap.tscn`, `scripts/minimap.gd`). It turns
  with you: the way you're riding is always up, you're the white arrow in the middle.
- It draws the walls, roads, roundabout, park, car parks, mosque, mini market, restaurants
  (in their brand colours) and every villa with its house number, all from the same data
  list the map is built from. Moving a villa in `data/palm_grove.gd` moves it here too.
- During an order an orange pin marks the next stop. Going to the villa, the villa turns
  orange and the pin shows its number. A strip along the bottom says "Villa 12   85 m" (or
  the restaurant name). If the stop is off the map, an orange arrow on the edge points the way.
- A small "N" on the edge shows where north is.
- Zoom and size are in the Mini-map block of `scripts/game_config.gd`.
- About 1 in 3 orders comes with a customer note on the phone, like "Leave it at the door,
  please". The notes are the ORDER_NOTES list in `game_config.gd`. They're only text for now;
  Session 11 makes "leave it at the door" mean nobody comes out.
- No GPS line on the road (that's a later upgrade).
- The smoke test checks the mini-map turns with the bike, the pin shows the restaurant then
  the villa number, a far-away stop stays pinned inside the map, and some orders have notes.
- Checked with real screenshots too, not only headless.

### Session 8
- Three meters while you carry food (`scripts/meters.gd`), shown top left in
  `ui/meters_panel.tscn`: TIME (counts down to the target time), FRESHNESS and DAMAGE.
  Each bar is green above 60%, orange from 30% to 60%, red under 30%.
- Time: full at pickup, empty at the target time = straight-line distance at 20 km/h,
  times 1.5, plus 20 s (PRD). After that it stays empty; the order is never cancelled.
- Freshness drains every second: pizza slowly, bubble tea medium, ice cream fast.
- Damage drops on speed bumps (more when fast), hard braking (braking above 18 km/h, once
  per press, the bike sends `hard_braked`) and crashing into things. Bubble tea loses the
  most on speed bumps.
- The values live in GameState (meter_time, meter_freshness, meter_damage) and are saved
  with each delivery in the history, ready for the stars in Session 10.
- All numbers are in the Meters block of `scripts/game_config.gd`.
- The smoke test checks the target time, that each meter drains, the bands, and that an
  all-red order can still be delivered.

### Session 9
- 5 cats (`scripts/cat.gd`) stroll slowly around their own patch between two villas,
  sit for a few seconds, then stroll on. Bump one and it dashes away, then wanders back.
- 3 kids on kick scooters (`scripts/scooter_kid.gd`) ride back and forth along the edge
  of Date Palm Street, Ghaf Street and East Lane, waiting a moment at each end. Bump one
  and they stop and wobble. If the bike is in their way, they wait instead of pushing it.
- Both are solid (`scripts/critter.gd`, the shared part), so you can't ride through them.
  Touching one while carrying food takes 10% (pizza) to 15% (bubble tea) off the damage
  meter, on top of the normal crash damage. Each bump counts once.
- Where they go is in the CATS and SCOOTER_KIDS lists at the end of `data/palm_grove.gd`,
  built by `scripts/obstacle_builder.gd`. Speeds and damage are in `game_config.gd`.
- The smoke test checks they were all built, a kid riding into the bike counts once and
  hurts the food, and the cats stay on their patches.

### Session 10
- Every delivery now gets 1 to 5 stars from the three meters (PRD formula: start at 5,
  orange meter -0.5, red meter -1.5, never below 1). `GameState.stars_for()`.
- Tips: only on 5-star deliveries, 40% of the time, 2 to 15 Dh. Never on boring orders.
- XP: 10 per delivery plus 2 per star. Rider Level 1 to 2 needs 50 XP, then 75, 100...
- Rating: the average stars of your last 50 deliveries.
- The phone's top now shows your rating as stars and a number ("New" before your first
  delivery), your Rider Level ("Lv 2") and a thin XP bar. After a delivery it shows
  "Delivered!" with big stars, the pay, any tip and the XP for 4 seconds.
- Stars are drawn as shapes (`scripts/star_row.gd`), because the font has no star letter.
- Everything is kept in GameState (money, xp, history with stars/tip/xp per delivery).
- Numbers are in the "Stars, tips, XP and rating" block of `game_config.gd`.
- Not built yet: "better orders show up more often at a high rating" (PRD) wasn't part of
  this session's prompt.
- The smoke test checks the PRD star examples, that tips only come on 5-star jobs, the
  level rule, and that the rating uses the last 50 deliveries.

### Session 11
- When you deliver, a customer (`scripts/customer.gd`) steps out of the villa's front door,
  waves and says one line in a white speech bubble, then turns round and goes back in.
  5 outfits (white kandura, black abaya, t-shirt, hoodie, top with a cap), 4 skin tones.
- 20 funny lines in `data/customer_lines.gd`. `{name}` in a line becomes the rider's name
  (GameState.rider_name; "habibi" until the application form in Session 14).
- 15% of orders say "Leave it at the door, please": nobody comes out, an orange food bag
  is left on the doorstep for 8 seconds and the phone says "Left at the door!".
  Other notes ("Extra napkins, please!"...) now come on 25% of the other orders.
- `scripts/customer_spawner.gd` does this on every delivery. Numbers in `game_config.gd`.
- The smoke test checks a customer comes out at the right villa with a line from the list,
  the lines vary, and a leave-at-the-door order leaves a bag instead.

### Session 12
- Crashes (`scripts/bike.gd`). A crash is hitting something fairly straight on:
  - Small crash (10 km/h or more): you fall off, the bike lies on its side for 2 seconds,
    the food loses 30% on the damage meter, then you get back on.
  - Big crash (above 20 km/h into a car, wall, palm or building): the screen fades out and
    the Al Sarab Clinic screen shows the bills (`scripts/clinic_screen.gd`). Your order is
    cancelled (counts as 0 stars, no pay). Press E or click OK: back at the start.
    Cats and kids only ever cause a small crash.
- Bills: 150 Dh hospital + 80 Dh repair. The boss pays the very first big crash. With
  insurance you only pay 20 Dh. Your wallet can go below 0.
- Insurance starts on and costs 2 Dh per delivery (shown on the phone after each delivery).
  Press I to switch it on or off; the bottom of the phone says which.
- Session 13 will make a big crash end the shift (GameState sends `big_crashed`).
- Numbers are in the "Crashes, bills and insurance" block of `game_config.gd`.
- The smoke test rides into a villa wall slowly (small crash, back on after 2 s) and fast
  (big crash, clinic, boss pays), and checks the insured and uninsured bills and the I key.
  On the old test area its riding checks now start in a clear lane (the old start rides
  into a box at sprint speed, which is now a big crash).

### Session 13
- Shifts (`scripts/shift_manager.gd`): one shift is 10 real minutes. A clock at the top
  middle (`scripts/shift_screen.gd`) shows the in-game time from 08:00 to 18:00 and the
  shift number. It turns orange with "Last orders!" in the last minute.
- When the clock runs out, no new orders pop up (an order still waiting on the phone just
  goes away, it doesn't count as a skip). If you're carrying an order you finish it, and
  the shift ends right after you drop it off. If not, it ends straight away.
- A big crash ends the shift too, right after the clinic screen.
- The summary screen (game paused): deliveries, cancelled orders, average stars, pay, tips,
  insurance, crash bills, what you earned, and XP. "Start next shift" (or E) starts a new
  shift with a full clock and puts the bike back at the start. Money and XP carry over.
- Shift data lives in GameState (shift_time_left, shift_number, shift_summary()).
- Numbers are in the Shifts block of `game_config.gd`.
- The smoke test runs 1-second shifts: finishing an order after clock-out, no new orders,
  the summary adds up, and an empty shift ends at once.

### Session 14
- The game now opens on the Snackaroo Rider Application (`scenes/application.tscn`,
  `scripts/application.gd`), a big phone screen: 1. your name (you can't submit without
  one), 2. where you're from (a list in `data/application.gd`), 3. pick one of 3 looks with
  a slowly turning 3D preview of your rider. Submit, "Reviewing..." with a spinner for 2 s,
  then "Congrats, <name>, you're hired!" and "Start riding" opens Palm Grove.
- The 3 looks (`scripts/rider_look.gd`), all ride the same: Classic (red cap, grey-blue
  hoodie, backpack), Sporty (white helmet with stickers, bright sports top), Chill (bucket
  hat, sunglasses, pink shirt, shorts).
- The phone shows "<name> · <country>". Customers say your name.
- Tutorial (`scripts/tutorial.gd`): right after you're hired the boss sends an easy pizza
  to villa 4 (TUTORIAL_ORDER in `data/palm_grove.gd`). A TIP box at the bottom says what to
  do at each step (accept with E, follow the mini-map, W/A/S/D, pick up with E, watch the
  meters, slow down for bumps, Shift to sprint, drop off with E), and at the end points out
  that crash insurance is on and I switches it. While the tutorial runs no other orders come
  and the shift clock waits. It only runs once.
- Pressing F6 on Palm Grove skips the application (handy for testing): no name, no tutorial.
- The smoke test fills in the application, checks all 3 looks, and walks through the tutorial.
  It now always tests Palm Grove (not the main scene, which is the application).

### Session 15
- The game now opens on the main menu (`scenes/main_menu.tscn`, `scripts/main_menu.gd`):
  the title, a slowly turning bike in your look, and Play (Continue once you're hired),
  New game (wipes the save, back to the application), Settings and Quit.
- Play goes to the application the first time, and straight to Palm Grove after that.
- Saving (`scripts/save_game.gd`): money, delivery history (so your rating), XP, your name,
  country and look, the insurance setting, and whether you're hired / did the tutorial /
  the boss paid a crash. GameState saves by itself after every delivery, crash, shift end
  and insurance switch, and when you close the window. It loads when the game starts.
  The save is `user://save.json` (on a Mac: ~/Library/Application Support/Godot/app_userdata/Five Stars Habibi/).
- Settings (`scripts/settings.gd`, `scripts/settings_panel.gd`): Fullscreen for now, kept in
  `user://settings.cfg`, so New game doesn't reset them.
- The pause menu (Esc) now has Resume, Settings, Main menu (saves first) and Quit game (saves
  first), and lists all the keys.
- Fixed: the first shift was called "Shift 2".
- The smoke test uses its own save file (never the real one), checks save and load keep
  everything, the menus' buttons, and New game; then deletes its save.

### Session 16
- All sounds and the music are made by `tools/make_sounds.py` (plain Python, no installs):
  nothing downloaded or copied, so they're ours and free (CC0, in CREDITS.md). The files
  are in `assets/audio/`. Run `python3 tools/make_sounds.py` to remake them after a change.
- Music (`scripts/music.gd`, an autoload called Music, so it keeps playing from the menu
  into the game): a chill 53-second loop in maqam Hijaz with an oud-like plucked tune, a
  soft darbuka maqsum rhythm and a low drone.
- Sound effects (`scripts/sounds.gd`, the Sounds node in each map): phone ping for a new
  order, bike bell when you pick up, cash register when you deliver, a crash, a thump on
  speed bumps, and tyre noise that gets louder and higher the faster you ride.
- Ambience: birds and distant traffic, always on in the map.
- Settings now has 4 volume sliders: Volume (everything), Music, Effects and Ambience.
  They're saved in `user://settings.cfg`. Each goes to its own audio bus.
- Fixed: the Settings box in the pause menu sat in the top-left corner; it's centred now.
- In the headless smoke test nothing actually plays (no speakers), but it checks every file
  loads, the buses and sliders work, and the right sound is picked for each event.
- Louis: listen and say if anything is too loud, too quiet or annoying. All of it is easy
  to change in `tools/make_sounds.py` or with the sliders.

### Session 17
- A play-test bot (`tests/playtest_bot.gd`) rides a whole shift in Palm Grove with the
  real physics and keys: it plans a route along the roads, goes round the roundabout,
  slows for corners and speed bumps, accepts every order, picks up and delivers, and
  prints each delivery and the shift summary. Command in CLAUDE.md. "-- careless" makes it
  ride flat out.
- What the first run showed (before tuning): even on-time rides ended with a red time bar
  (the bar was empty AT the target time), ice cream melted to orange on a normal ride, and
  crawling over bumps still hurt bubble tea. A careful rider averaged 4.0 stars and never
  got a tip.
- Tuning (all in `game_config.gd`, PRD updated):
  - Time bar: 60% at the target time, empty at twice the target (TIME_METER_AT_TARGET,
    TIME_EMPTY_AT). On time = green.
  - Freshness drain: pizza 0.25, bubble tea 0.4, ice cream 0.55 % a second (was 0.35/0.6/1.0).
  - Speed bumps: slow (10 km/h or less) costs only a quarter of the damage.
  - Hard braking only counts from 22 km/h (was 18, so normal braking counted).
- After tuning: a careful shift gets about 12 deliveries, 5.0 stars, ~25 Dh tips and
  ~120 Dh. A careless shift gets fast 5-star jobs at first, then a big crash ends the shift
  early with about half the money. The longest rides take about a minute.
- Louis: play a few shifts. If it feels too easy, lower TIME_METER_AT_TARGET or raise the
  freshness drain; if too hard, the other way. Write down what felt off for the next
  tuning session.

### Session 18
- Picking up and dropping off now need **E held for 1.5 seconds** at the door, going under
  5 km/h. A quick tap of E does nothing there. Accepting an order is still a quick tap.
- An orange bar on the phone fills while you hold E. Letting go, moving away or speeding
  up resets it. At the door but too fast, the phone says "Slow down, then hold E".
- After any E action you have to let go of E before the next hold counts (so accepting an
  order doesn't carry on into a pick-up).
- Numbers: PICKUP_HOLD_TIME, DROPOFF_HOLD_TIME, INTERACT_MAX_SPEED_KMH in `game_config.gd`.
  The hold is timed in `scripts/delivery_manager.gd` (`_update_hold`).
- Tutorial tips now say "Stop, then hold E".
- Fixed Louis's flaky check: "the customer says a line from the list" now fills {name}
  with the real rider name.
- The smoke test checks a quick tap does nothing and a full hold picks up and delivers,
  and passed 5 runs in a row. The play-test bot holds E too: still 12 deliveries a shift.

### Session 19
- **F gets off the bike** (only under 5 km/h) and back on (within 2 m of it). The bike
  stays parked where you left it: solid, leaning on its stand, no rider on it.
- On foot (`scripts/walker.gd`): W / S walk forward and back (5 km/h), A / D turn, Shift
  jogs (9 km/h). The legs swing as you walk. The walker wears your look (cap, helmet or
  bucket hat), using the same `scripts/rider_look.gd` as the rider on the bike.
- `scripts/on_foot.gd` (the OnFoot node) switches between riding and walking: the camera,
  the mini-map and the DeliveryManager follow whoever you control.
- Picking up and dropping off (hold E) **only work on foot**. The meters and the shift clock
  keep running while you walk, so parking near the door matters.
- Phone hints: "Park near the door", "Press F to get off", "Walk to the door", "Hold E to
  drop off", "Press F to ride", and "Your bike is over there" when you're more than 40 m
  away. The mini-map shows the parked bike as a teal "B".
- R on foot puts you back on the bike at the start.
- Kids on scooters wait for you, and turn back after 2 s if you stay in their way (so a
  parked bike can't block them forever). Cats and kids can't crash into you on foot.
- Tutorial tips explain F and walking. Numbers: the "On foot" block in `game_config.gd`.
- The smoke test checks F only works when stopped, and does the full run: park 6 m from a
  door, F, walk to the door, hold E, walk back, F, ride away. The play-test bot walks too:
  still 11 deliveries in a 10-minute shift.

### Session 20
- Fonts: Baloo 2 (titles, big numbers) and Nunito (everything else), free under the SIL
  Open Font License, in `assets/fonts/` with their licence files and in CREDITS.md. Noto
  Sans Arabic is the fallback, so Arabic in any menu still joins up.
- One theme for every screen, `ui/theme.tres` (Project Settings > GUI > Theme): the fonts,
  and teal rounded buttons with an orange pressed state. Labels use the "Heading" or
  "BigNumber" variation for Baloo 2.
- The phone is now a white rounded card like the mockup: Snackaroo header with a teal
  wallet chip, rider name, rating and level, a coloured status pill (NEW ORDER, PICK UP,
  DROP OFF, DONE, WAITING), pick-up and drop-off rows (the current one in orange, a done
  one ticked), food / pay / timer chips, the customer's note in a yellow box, the hint and
  the orange hold bar, and the insurance line.
- The mini-map is round, with a white ring (drawn into its own little viewport and cut to
  a circle by `ui/round_mask.gdshader`). Pins stay inside the circle.
- The HUD, meters panel and clock use Baloo 2 for their numbers. They keep the dark
  see-through panels (#0F2026 at 86%) from the PRD.
- Note: the mockup link in PRD.md couldn't be opened from Claude Code (not shared with this
  account), so the look follows the PRD's description of it. Louis, compare with the mockup
  and say what's different.
- The first time Godot opens the project after this change it may print a font error
  once while it imports the new fonts; the second time it's clean.

### Session 21
- One start screen (`scripts/start_screen.gd`) for the main menu and the rider application,
  like the mockup's "Start: rider application":
  - Left: "AL SARAB · السراب", the big "Five Stars Habibi" title (Baloo 2, white with a teal
    outline), orange "Rider to Driver" and one line about the game.
  - Behind it: a low-poly 3D desert (sand dunes, a big pale sun, a palm, warm haze), with
    the camera drifting slowly.
  - Right: a big phone. On the menu it has Play (Continue once you're hired), New game,
    Settings and Quit.
  - The first time you press Play, the phone becomes the Snackaroo rider application: your
    name, where you're from, "Pick your look" with 3 cards (Classic, Sporty, Chill), each
    with its own little turning 3D rider, the picked one outlined in orange, and
    Submit application. Then "Reviewing..." and "Congrats, <name>, you're hired!" on the same
    phone, and Start riding.
- `scenes/main_menu.tscn` opens it on the menu, `scenes/application.tscn` straight on the
  form. The old `main_menu.gd` and `application.gd` are gone (one script does both now).
- Text boxes are styled for the white cards (sand box, orange edge while typing).
- Saving, the 43 countries, the tutorial and New game work as before.
- The smoke test checks Play opens the application on the phone and there's a 3D card per look.

### Session 22
- The Delivered card (`scripts/delivered_card.gd`) after every delivery, like the mockup's
  "Delivery complete":
  - The game pauses (and the shift clock with it). The other screen panels hide.
  - The camera cuts to a 3D shot from the side of the door: you and the customer (or the
    bag on the doorstep for leave-at-the-door orders), with the customer's line in a white
    speech bubble. The customer waits at the door until the card closes.
  - On the right a white card: "Delivered!" (or "Left at the door!"), the stars,
    "Ice Cream to Villa 12 · 0:58" (food, villa, ride time), three tiles Time / Freshness /
    Damage, each with a word and a colour (green, orange or red: "On time", "Okay",
    "Smashed"...), then Delivery pay, 5-star tip (only if you got one), Insurance, a bold
    "You earned" total and the XP.
  - "Next order · E" (the button or E) closes it, the camera goes back and the game carries on.
- If that was the last delivery of the shift, the shift summary comes after the card.
- The numbers are the real ones from GameState. The smoke test checks the card shows, its
  total matches the money you got, the camera cuts to the door, and E closes it.

### Session 23
- The clinic screen is rebuilt like the mockup's "Big crash: clinic bills"
  (`scripts/clinic_screen.gd`):
  - The screen fades to black, then a simple 3D clinic room: pale teal walls, a window, your
    rider (in your look) lying in a bed under a blanket, and a drip stand, filmed from the side.
  - Left: a red BIG CRASH label, "You woke up at Wahat Al Shams Clinic", a sentence with what
    you hit and how fast ("You hit a parked car at 27 km/h. The ice cream didn't make it, and
    your shift is over for today.") and a teal Arabic sign "عيادة واحة الشمس".
  - Right: the white "Your bills" card: ORDER CANCELLED · 0 STARS (if you had an order),
    Clinic bill, Bike repair (Snackaroo), Insurance (or "Your boss covered it" the first
    time), a red "You pay" total, a yellow tip when insurance was off, the "Big crashes this
    week" bar (the last 7 shifts, full at 3), and the buttons "Turn on insurance" (only when
    it's off) and "Shift summary · E".
- The bike now remembers what it hit and how fast (`last_crash`: a parked car, a villa wall,
  a palm tree, a restaurant, the mosque...). GameState keeps the shift of every big crash
  (saved too) for the weekly bar.
- The bills and what happens after (shift ends, summary) work as before.
- The smoke test checks the sentence, the weekly count, the tip, and Turn on insurance.

### Session 24
- Smoke test: passed 5 runs in a row (212 checks each).
- Play-test bot, 10-minute shift (still Palm Grove): a careful shift gets **10 deliveries**,
  4.95 stars, ~120 Dh, with about 30 s spent walking to doors. A careless shift also gets
  about 10 deliveries but crashes (2 small, 1 big, one order cancelled) and earns ~93 Dh.
  Walking to the door doesn't make deliveries too slow, so no tuning was needed.
- Screenshots were taken of the gameplay HUD, the start screen, the Delivered card and the
  clinic screen (one per session, 20 to 23) and fixed where something was off (title line
  gap, look cards, card camera, clinic camera).
- Couldn't compare with the mockup itself: the mockup link in PRD.md can't be opened from
  Claude Code. Louis: compare the four screens with the mockup and list what's different.
- Still to do: Louis plays a full shift himself.

### Session 25
- **Shifts are 5 minutes** now (30 s per in-game hour, 08:00 to 18:00). The clock turns
  orange in the last in-game hour.
- **New map: Wahat Al Shams** (`scenes/wahat_al_shams.tscn`, data list
  `data/wahat_al_shams.gd`, built by `scripts/wahat_builder.gd`), about 400 x 300 m, from
  Louis's sketch (`docs/wahat_al_shams_map.svg`):
  - a belt of trees round the edge (one MultiMesh, fast), an invisible wall inside it,
    a sandy horse track and a red bike track, then the ring road;
  - the main gate in the middle of the west side (closed red bar, gate house) with the
    bilingual welcome sign "Welcome to Wahat Al Shams / أهلاً بكم في واحة الشمس";
  - the Plaza just inside the gate (round paving for now) with Pizza, Brain Freeze Gelato and
    Boba Oasis on its north side and the Al Sarab Mini Market on its south side;
  - the green spine through the middle: grass, the spine path (the bike shortcut) and a
    winding stream;
  - 5 clusters (C1 to C3 north, C4 and C5 south), each with 12 homes on two 4 m lanes,
    connector lanes at each side from the ring road to the spine, bollards at every lane
    entrance (cars can't get in, the bike can) and a mini-plaza strip through the middle;
  - solar car park spots on the ring road by each cluster, with parked cars;
  - flat plots for the school, mosque, stables and building site (built in Session 27);
  - speed bumps on the ring road, palms round the Plaza and along the spine path, cats in
    the mini-plazas, kids on scooters on the ring road and the spine path.
- Homes are placeholder boxes for now (the house kit is Session 26), numbered 1 to 12 inside
  each cluster. Addresses read "C3 · Villa 7" on the phone, the mini-map, the Delivered card
  and the tutorial. Orders keep an `address`.
- The main menu starts the new map. `scenes/palm_grove.tscn` stays as an old test map.
- The mini-map draws any map now (the Plaza, spine, plots, lanes in their own width).
- The smoke test runs on Wahat Al Shams by default: it checks the 60 homes and their
  addresses, that the ride from the gate ends in the Plaza, and that every home and shop door
  can be reached by bike. For that, `tests/grid_path.gd` scans the map in 1 m squares and finds
  routes with Godot's AStarGrid2D. Palm Grove and the test area still pass too.
- The play-test bot uses the same route finder on any map, looks ahead and slows down for
  walls. It still gets stuck in the narrow cluster lanes; fixing that is next.

### Session 28
- The sun follows the shift clock (`scripts/sun_cycle.gd`, a SunCycle node in each map):
  low and warm at 08:00, high and white at noon, a golden sunset from 17:00 to 18:00. The sky
  colours and the shadow light change smoothly with it. It crosses from east to west.
- Soft corner shadows (SSAO), a light haze so the far edge of the map fades into the sky,
  a gentle glow on bright things, and heat shimmer far away above the ground around noon
  (10:30 to 15:30, `assets/shaders/heat_shimmer.gdshader`, very subtle: SHIMMER_AMOUNT).
- Settings has a Graphics option: Low / Medium (default) / High, saved with the other
  settings and applied straight away. Low: no SSAO, haze, shimmer or glow, shadows only to
  60 m. Medium: everything on, shadows to 150 m. High: better SSAO, softer shadows to 260 m.
- 60 fps on all three levels on the Mac (Apple M3, 1280x720).
- All light numbers, one line per time of day, are in the "Light and sky (Session 28)" block
  of `game_config.gd`.
- Not done yet: "fewer people on Low" (comes with the people in Sessions 29 and 30); the main
  menu's desert doesn't use the moving sun.
- Built by a helper agent in parallel; the smoke test has 11 new checks for the sun and the
  Graphics levels.

### Session 26
- The 60 Wahat Al Shams homes are real houses now, built in code from a house kit
  (`scripts/villa_builder.gd`, details in `scripts/villa_extras.gd`, merged into one mesh per
  home by `scripts/mesh_kit.gd` so it stays fast): cream or sand two-storey L-shapes with a flat
  roof, parapet and roof terrace, tilted solar panels on posts, a wind tower (barjeel) with
  slots, small deep windows, a wooden door with a step and a little shade, and a teal plate
  with the house number (1 to 12).
- 3 types per cluster: 10 courtyard villas (side wing with the wind tower, a paved courtyard
  behind a low wall), 1 garden villa (big lawn, hedge, shade tree) and 1 signature villa
  (house 12: bigger, double door, wooden mashrabiya screen upstairs).
- Every home looks different, and the same every time (its number picks): door colour,
  courtyard left or right, golf buggy or bikes, AC units, satellite dish, pot plants, a tree in
  the courtyard, flowers on the wall, toys, panels front or back, and a pool or trampoline on
  garden and signature villas.
- Homes are solid; door spots and lanes stay clear (checked).
- Bilingual cluster signs ("المجموعة ١ / Cluster 1") at all 4 lane ends of every cluster
  (`scripts/cluster_signs.gd`), readable from both sides.
- About 55 to 59 fps in screenshot runs on the Mac.
- Palm Grove keeps its old villas. A data entry with "kind": "spot" gets no house (for the
  school and stables drop-off spots in Session 27).
- Worth knowing: signature villas are a little bigger than the 11 x 11 plot (SIGNATURE_EXTRA_*
  in `game_config.gd`); the mini-map still draws every home as the same square.
- Built by a helper agent in parallel; new smoke test checks for the house kinds, the door
  numbers, the signs and that nothing blocks a door.

### Session 27
- The Plaza has a sunken square: steps down to a round tiled floor with a fountain, 4 date
  palms, benches and two white shade sails. The bike rolls down a gentle hidden slope (0.45 m).
- 6 shops round the Plaza: Pizza, Brain Freeze Gelato, Boba Oasis, plus Shawarma Supreme and
  Sunrise Bakery (new), and Al Sarab Mini Market, now a real pickup shop selling groceries.
- The green spine: 6 white greenhouse domes, farm beds, beehives, a donkey pen with 2 donkeys,
  a basketball court and a playground. The Wahat Farm Stall is the 7th pickup spot (farm juice
  or a salad box).
- Each cluster mini-plaza has a cooling tower, a small playground and benches (the strip stays
  clear to ride).
- Al Shams School (fenced yard, bilingual sign, football pitch, flag): its security booth at the
  gate is the only drop-off spot. The mosque with its minaret is scenery only: never an order.
  The stables: stable block with horses looking out, a paddock with 4 horses, and the stable
  office (the only drop-off spot). The building site: fence, crane, containers, sand piles and a
  bilingual "Phase 2 coming soon" sign.
- New foods with their own freshness and damage numbers: shawarma (medium), cake (breaks on
  bumps), groceries (slow to spoil), farm juice and salad box (spoil in the sun).
- Orders pick up from all 7 pickup spots and go to the 60 homes, the school booth and the
  stable office (who orders and when is Session 32).
- New builders: `scripts/plaza_builder.gd`, `scripts/spine_builder.gd`,
  `scripts/landmark_builder.gd`, `scripts/farm_stall.gd`, and `scripts/props.gd` (benches,
  playgrounds, fences, cooling tower, horses, donkeys).
- Built by a helper agent in parallel and merged with Session 26's houses (both changed how
  homes and drop-off spots are built). The smoke test checks the sunken square, every new
  building, an order from each new shop, that the mosque never gets an order, and that every
  door can be reached.
- Groceries being "a bit heavy" is only in the damage numbers for now.

### Session 29
- People are real animated low-poly humans now (free CC0 model "Animated Human" by Quaternius,
  with idle, walk and run animations; credited in CREDITS.md). Waving, pedalling and lying in
  the clinic bed are poses made in code. Clothes are painted in code; hats, helmets, scarves,
  bags and shoes are small shapes that move with the body (`scripts/person.gd`,
  `scripts/person_pose.gd`, `scripts/people_looks.gd`).
- The rider pedals with hands on the grips and feet on the pedals; on foot they walk or jog
  (animation speed matches). The 3 looks are kept (Classic, Sporty, Chill) on the bike, on
  foot, on the start-screen cards and in the clinic bed.
- Customers come in the 5 outfits (white kandura with ghutra and agal, black abaya with shayla,
  t-shirt, red hoodie, green top with cap): they walk out, wave, and walk back in.
- Teachers, school kids, horse riders and grooms are ready to use (`PeopleLooks.teacher()` etc.)
  for the next sessions; nothing places them yet.
- A proper low-poly bicycle built in code (`scripts/bike_model.gd`): spoked wheels, frame,
  saddle, chain, rack and the orange delivery box. The pedals turn with speed, the handlebars
  and front wheel turn when you steer, and the kickstand drops when you get off. Riding feel
  and the collision box are unchanged.
- **B rings the bell** (a new home-made "brrring-ring", `assets/audio/ring.wav`): customers
  nearby wave again, cats run off, kids on scooters stop and wobble.
- Parked cars are 5 free CC0 Kenney Car Kit models, the same size as before.
- Fixed while merging: a cat could stroll into a parked bike and shove it (the smoke test's
  walking check failed about 1 run in 4 on Palm Grove). Cats now pick somewhere else to go
  when they bump into the bike or you; 6 of 6 runs passed after.
- Not done: plants from a CC0 pack (optional). Kids are a scaled-down adult body.
- Built by a helper agent in parallel. New smoke test checks: pedals turn faster at speed,
  handlebars turn, kickstand down when parked, B rings the bell and scares a cat, every people
  type can walk, wave and stand, cars are the CC0 models.

### Session 31
- Dust puffs come off the back tyre when you ride on sand, and when you brake hard on any
  ground (`scripts/tyre_dust.gd`; where the sand is comes from the map's data list,
  `scripts/ground_type.gd`). Fewer puffs on Low graphics, more on High.
- While you sprint (Shift) the view widens by 7 degrees and thin white speed lines rush out at
  the screen edges (`scripts/speed_lines.gd`); both fade back when you stop.
- On the Delivered card the stars fill in one at a time, each with sparkles and a blip that
  gets higher each time; then gold coins fly out of "You earned" with a coin jingle and the
  total bounces (`scripts/pop_icon.gd`).
- A new order makes the phone shake for a moment and go "bzz-bzz" (plus the old ping).
- 3 new home-made sounds (buzz, pop, coins) from `tools/make_sounds.py`, in CREDITS.md.
- Sound effects now keep playing while the game is paused (the "ka-ching" used to be cut off
  when the Delivered card paused the game).
- No measurable effect on frame rate. Numbers in the "Juice (Session 31)" block of
  `game_config.gd` (SPEED_LINES_ALPHA if the speed lines should be stronger).
- Built by a helper agent in parallel; the smoke test checks the wider view while sprinting,
  the buzz, the pops, the dust and fewer particles on Low.

### Session 30
- Golf buggies with drivers go slowly back and forth on fixed routes (the outer lane of the
  north and south ring road and the spine path; two more on High). They stop and wait when
  the bike or you on foot are in front; stay in the way 5 seconds and they turn round.
- Bumping a buggy, horse, walker, gardener, kid or duck is like bumping a kid: a small knock
  to the food, never a big crash.
- Horses with riders walk and trot on the horse track round the edge; joggers run on the red
  bike track; walkers stroll beside the spine path; gardeners water flower beds with a hose;
  kids run about by every cluster playground.
- Ducks paddle along the stream, birds circle overhead, palms sway, the donkeys stroll round
  their pen, and the stream and fountain water ripple (`assets/shaders/water.gdshader`).
- Every route is its own line in `data/wahat_al_shams.gd` (BUGGIES, HORSE_RIDERS,
  PEOPLE_ROUTES, GARDENERS, PLAY_KIDS, DUCKS, BIRD_FLOCKS): no traffic AI. Built by
  `scripts/life_builder.gd`, moved by `scripts/route_mover.gd`.
- 12 moving things on Low graphics, 36 on High; people far from the camera stop animating.
  Still 120 fps (the screen's limit) on Medium.
- Fixed while merging: a parked bike no longer slides at all when something walks into it
  (a test failed about 1 run in 6 on Palm Grove because of that); 8 of 8 runs passed after.
- Built by a helper agent in parallel. The smoke test checks every route stays clear of
  walls, buggies stop for the bike and turn round, everything moves, and Low has fewer.

### Session 33
- Each shift has 1 or 2 surprise events at random times between 09:00 and 16:00, one at a
  time, never during the tutorial. The phone warns you first ("Heads up!", orange, 6
  seconds), then a teal line says what's on ("Road works: C3 Lane closed till 14:35").
- Road works: barriers, cones, a small yellow digger and bilingual "أعمال طرق / Road works"
  signs close a stretch of a cluster lane or the ring road for 1 to 2 in-game hours, with an
  orange cone on the mini-map. Only the 14 places on the ROAD_WORKS list in
  `data/wahat_al_shams.gd`; the smoke test closes each one in turn and checks every home and
  shop door can still be reached. Never within 15 m of you or your parked bike.
- Horses crossing: a groom leads 2 or 3 horses across a road near the stables (4 places,
  HORSE_CROSSINGS); the road is blocked for about 6 to 8 seconds. Riding into them is only a
  small crash. They wait for you or the parked bike, never shove.
- Files: `scripts/event_manager.gd`, `scripts/road_works.gd`, `scripts/horse_crossing.gd`;
  numbers in the "Random events (Session 33)" block of `game_config.gd`. Palm Grove and the
  test area have no events.
- Fixed while merging with Session 30: golf buggies, horses and walkers now stop at road
  works instead of driving through the barrier (and turn round after a few seconds); the
  crossing groom's speed got its own name (CROSSING_WALK_SPEED) so it doesn't clash with the
  horse riders' speed. New smoke check: a buggy stops at the north ring road works.
- The play-test bot re-plans its route when road works go up or come down, and rides round.
- Known: barriers only span the road, so on the ring road you can ride round on the sand.
  The crossing horses pop in and out at the ends of their path and their legs don't move.
- Built by a helper agent in parallel.

### Session 32
- About 1 in 6 orders is special, with a coloured chip on the phone: **Rush** (red: 70% of the
  time, +50% pay), **Fragile cake** (pink: from Sunrise Bakery, every knock does double
  damage, 60% tip chance on 5 stars), **Neighbour** (purple: at the door "Not home! Leave it
  with the neighbour at C1 · Villa 9", the clock keeps running, +5 Dh) and **Big family**
  (blue: a second bag on the handlebars, top speed 15% lower, a little sway, double pay).
  The Delivered card shows the extra pay on its own row.
- School orders only 08:00 to 15:00; in the 11:30 to 12:30 lunch rush about 1 in 3 orders go
  to the school gate, where a teacher or a school kid comes out. Stables orders go to the
  stable office (a rider or groom comes out). About 1 in 8 pickups is at the Farm Stall.
- 4 regulars order more often: Auntie Mariam (bubble tea, C2 Villa 7), Mr Rashid (shawarma,
  C5 Villa 3), Ms Dana (cake, school gate, school hours only) and Hamdan (farm juice, stable
  office). Pink heart chip, their own lines with your name, 60% tip chance on 5 stars, and the
  save file remembers how many times you've delivered to each.
- 2 shift goals on the phone at the start of each shift (e.g. "Make 8 deliveries 0/8"); each
  one done pays 15 Dh, listed on the shift summary. The Delivered card says when a delivery
  finishes a goal.
- New files: `scripts/order_maker.gd` (who orders what from where), `scripts/shift_goals.gd`.
  Numbers in the "Special orders, goals and regulars (Session 32)" block of `game_config.gd`.
- Palm Grove and the test area leave out what they can't do (no school, no regulars).
- **Goal numbers to decide (Session 34):** with 5-minute shifts and 4 to 6 deliveries,
  "Make 8 deliveries" and "2 school lunch orders" (the lunch rush is only 30 real seconds)
  are effectively impossible, "all 5 clusters" is very unlikely, and "a fragile cake with 5
  stars" only works in about 1 shift in 5. Kept as in the PRD for now.
- Fixed while merging: the old "kids on scooters move" check was flaky (the kid could touch
  the bike after only 0.4 m); the bike now waits 3.5 m ahead instead of 2.5 m.
- Built by a helper agent in parallel. Smoke checks: each special's rule and reward, no school
  order after 15:00, lunch rush share, regulars (heart, name, tips, saved), goal bonus once.

### Session 34
- Play-test bot on Wahat Al Shams. Before tuning, a careful 5-minute shift got 5 deliveries:
  riding to the shop took almost half the shift (the shops are in the Plaza at the west end).
  Now 7 in 10 orders go to the nearer half of homes from the shop (ORDER_NEARBY_HOME_CHANCE
  in `game_config.gd`), so trips are shorter. A careful bot (which never sprints) now gets 5
  to 7 deliveries, about 6; a player who sprints should get 6 to 7. Pay per shift stayed about
  the same (54 to 74 Dh before tips and goals).
- Final shifts: careful 6 deliveries, 5.00 stars, 0 crashes, 69 Dh. Careless 6 deliveries,
  4.67 stars, 9 small crashes, 84 Dh (lucky tips and a goal). Small crashes are cheap now,
  so being careless doesn't cost enough yet: something to look at after Louis plays.
- Shift goals changed to fit 5 minutes (PRD Decisions log, for Louis to confirm): make 6
  deliveries (was 8), a school lunch order (was 2: the lunch rush is only 30 real seconds),
  deliver to 3 different clusters (was all 5).
- Frame rate at the Plaza and the spine (1280x720, vsync off): Low 60 fps, Medium 60 to 67,
  High 70 to 72. 60 fps on Medium: yes.
- Screenshots of the gate, the Plaza, a cluster lane, the spine, the school gate, the stables
  and the sunset all look right.
- Smoke test 5 times on Wahat: 5 of 5 PASS (362 checks each). Palm Grove and the test area
  pass too.
- The play-test bot now rides (instead of walking) when a "leave it with the neighbour" order
  sends it to a far door, and says when a walk takes longer than 20 seconds.
- Not done yet: removing the old Palm Grove map. It's still the smoke test's second map; remove
  it once Louis has played Wahat Al Shams and is happy.
- **Louis's turn:** play a full shift and write down what felt off.

### Session 35A — initial clock (superseded by the correction below)
- `SHIFT_LENGTH` is 480 seconds. The internal 08:00–18:00 time stays continuous:
  48 active seconds per in-game hour. Only the visible clock steps every 10 game
  minutes (8 active seconds). It reads `8:00 AM`, `11:50 AM`, `12:00 PM`, `6:00 PM`.
- New shared formatter `scripts/game_clock.gd` keeps the HUD and event messages
  consistent. The sun is drawn directly, so it does not need a font symbol.
- Tutorial and pause still stop the shift; the final carried delivery can finish
  after 6:00 PM. No new orders arrive after clock-out. The existing 30-second
  last-orders warning, food rates, rewards, goals and map remain as before.
- Godot 4.7.2 import and headless quit completed. Smoke tests: Wahat Al Shams
  **387 PASS**, Palm Grove **297 PASS**, test area **263 PASS**, no failed checks.
  New coverage includes noon/midnight formatting, exact display boundaries,
  continuous time between steps, the 48-second lunch window, real-frame
  pause/tutorial/resume, event times and preserved regular-customer visits.
- One careful eight-minute bot shift on the current map: **9 deliveries, 5.00 stars,
  121 Dh net, 180 XP, 0 crashes and 0 resets**; 5 backing-up manoeuvres and 29 seconds
  walking. This is one random shift, not the future larger map's economy target.
- Rendered clock check at 1280×720 on Apple M3 / Forward+: morning, before noon,
  noon and end of day all fit the panel, with a visible sun and correct AM/PM text.
- Checks ran in an isolated temporary copy with saves/settings redirected there.
  Initial headless import rebuilt absent asset caches and reported sandbox-blocked
  editor-settings writes; headless runs also reported the macOS certificate lookup
  warning. The bot's existing shutdown path intentionally cannot save. These did not
  produce game-script errors or failed smoke checks. A final import with a portable
  temporary editor passed without script/resource/editor-settings errors; only the
  sandbox macOS certificate lookup message remained.
- **Initial manual check (superseded):** import this branch's `project.godot` in Godot and press F5.
  Continue (or complete the application/tutorial), then watch the clock: `8:00 AM`
  becomes `8:10 AM` after 8 active seconds. Press Esc and verify time waits; resume
  and verify it continues. Check noon becomes `12:00 PM`, and a final delivery can
  finish after `6:00 PM`. On road works, the phone's end time also uses AM/PM.
- Session 35B and the rest of the Detail pass remain to be built.

### Session 35A — corrected clock
- Michael clarified the rate: **one active real second equals one game minute**.
  The AM/PM clock now displays `8:00`, `8:01`, `8:02` on successive seconds.
  The existing 8:00 AM–6:00 PM workday therefore lasts **600 seconds (ten minutes)**.
- `GAME_MINUTES_PER_REAL_SECOND` is the explicit rate in `game_config.gd`.
  Shift length is derived from the working hours and that rate. `clock_hours()`
  converts elapsed active seconds to game hours; schedules and sunlight still
  use its precise value, while the HUD and event text show whole minutes.
- Lunch is 11:30 AM–12:30 PM (210–270 active seconds); the school closes at
  3:00 PM (420 seconds). One to two game hours of roadworks last 60–120 seconds.
  The 30-second last-orders warning starts at 5:30 PM.
- Pause, tutorial and delivery-result screens still freeze the clock. You can
  finish a carried order after 6:00 PM; no new orders arrive after clock-out.
  Food rates, stamina, offer countdowns, pickup holds, movement and saves keep
  their existing units and behaviour.
- Godot 4.7.2 import and headless quit completed. Smoke tests passed on all three
  maps: **397** checks on Wahat Al Shams, **307** on Palm Grove and **273** on the
  test area (**977 total**, zero failures). Coverage includes mixed frame lengths,
  exact minute boundaries, lunch and school times, 600-second clock-out,
  pause/tutorial/resume, finishing the last order, and save compatibility.
- Normal-speed rendered stopwatch check on the actual Wahat scene (Apple M3,
  Forward+, 1280×720): **60.024 real seconds advanced 60.033 game minutes**,
  reaching `9:00 AM` from `8:00 AM`. The difference was 0.009 seconds of clock
  pacing, within one physics tick. `Engine.time_scale` was 1 and no fixed-FPS
  override or clock fast-forward was used. The temporary demo overlay reports PASS.
- Checks and the live demo use separate temporary save/settings directories.
  The sandbox's macOS certificate lookup message remains; there were no
  game-script errors or failed checks. The bot also retains its existing warning
  for the deliberately invalid shutdown save path. Stopwatch evidence and screenshots are in
  `/Users/michartmann/.codex/visualizations/2026/11/03/01a1a1e1-bbdf-7f31-98df-b146cc6cb116/corrected-clock/`.
- One complete ten-minute careful bot shift: **11 deliveries, 5.00 stars, 181 Dh
  net, 220 XP, no crashes and no resets**; 7 backing-up manoeuvres and 35 seconds
  walking. Both randomly assigned goals completed. This is one pacing sample
  on the existing map, not a guaranteed earning rate or the larger map's target.
- **Louis's manual check:** open this branch's `project.godot` in Godot and press
  F5. Start a shift and watch `8:00 AM` become `8:01 AM` after one active second.
  After one real minute the clock should read `9:00 AM`; pause with Esc and
  verify time waits, then resume. Noon is four active real minutes after start;
  6:00 PM is ten minutes after start.

## Known bugs
- Play-test bot findings on Wahat Al Shams (to tune in Session 34):
  - A careful 5-minute shift gets 5 to 6 deliveries (target 6 to 8). The rides are long
    (Plaza to cluster 100 to 250 m), not the bot; target times look generous (time meter
    ends around 76 to 84%).
  - At full speed the bike can't make a 90° turn between 4 m lanes: brake to about 12 to 14 km/h
    before lane corners. Careless riding hits villa corners.
  - Cats sit in the cluster mini-plaza strips, the natural shortcut, so fast riders hit them
    a lot (one ice cream lost all its damage to three cat hits).
  - Doors face the narrow lanes, so every stop ends in a three-point turn (S to reverse):
    worth a line in the tutorial.
  - A scooter kid riding head-on can keep bumping a stopped rider until it turns back.
- The play-test bot (`tests/playtest_bot.gd`, `tests/grid_path.gd`) was rebuilt by a helper
  agent: it looks ahead on its route, slows for corners, bumps, cats and doors, steers round
  cats and kids, backs up when blocked. 0 crashes and 0 resets in 11 careful shifts.
  `-- timeline` prints every step.
- None found by the checks. Not play-tested by Louis yet.
- The bot once got stuck nose-to-nose with a kid on a scooter (the kid waits for the bike,
  the bot kept pushing). A person just steers round, but say if it happens to you.
- Palm Grove rides take up to about a minute, not the 2 to 3 minutes the PRD hoped for
  (see "Still open" in PRD.md).
- Godot is in the Downloads folder, not Applications, so the commands in CLAUDE.md
  (/Applications/Godot.app/...) don't find it. Drag Godot.app into Applications to fix it.

- New scripts with class_name need Godot to refresh its class list once. Opening the
  project in the Godot editor does it. If F5 shows "Could not find type Order" or similar,
  close and reopen the project in the editor.

## Next
- Louis play-tests Wahat Al Shams with the "Done when" checklists in BUILD_PLAN.md
  (Sessions 18 to 34) and confirms the Session 34 tuning in the PRD Decisions log.
- Merge `polish-and-graphics` into main (pull request on GitHub).
- Remove the old Palm Grove map once Wahat Al Shams feels right (Session 34 left it in,
  because the smoke test still uses it as a second map).
- Then the Detail pass (Sessions 35 to 46), then Reasons to come back (Sessions 47 to 51), ending with itch.io.
