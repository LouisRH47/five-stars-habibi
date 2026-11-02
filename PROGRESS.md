# Progress

## Current session
Session 7: Mini-map and addresses (built and smoke-tested on the Mac, waiting for Louis
to play-test). Sessions 1 to 6 still need play-testing on a real screen.

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

## Known bugs
- None found yet. Not play-tested by Louis yet.
- Godot is in the Downloads folder, not Applications, so the commands in CLAUDE.md
  (/Applications/Godot.app/...) don't find it. Drag Godot.app into Applications to fix it.

- New scripts with class_name need Godot to refresh its class list once. Opening the
  project in the Godot editor does it. If F5 shows "Could not find type Order" or similar,
  close and reopen the project in the editor.

## Next
- Louis play-tests Sessions 1 to 7 with the checklists in BUILD_PLAN.md.
- First check in Session 5: the Arabic on the welcome sign looks joined up and right-to-left.
- Then Session 8: The three meters.
- Open question for Louis: rides in Palm Grove take up to about a minute, the PRD hoped
  for 2 to 3 minutes. See "Still open" in PRD.md.
