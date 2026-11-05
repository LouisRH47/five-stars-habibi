# Build Plan for Claude Code

A step-by-step plan for building Tier 1 of Five Stars Habibi with Claude Code on a Mac. It's written for a total beginner with 1 to 3 hours a week. Everything Claude Code needs is in this repo: `PRD.md` (the design), this file (the steps), `CLAUDE.md` (rules it reads every session) and `PROGRESS.md` (what's done).

## Setup on the Mac (one time, about 30 minutes)

- [ ] **1. Godot.** Go to godotengine.org/download, pick macOS and download the plain **Godot Engine** (NOT the .NET / C# version). Drag it into Applications. The first time, right-click it and choose Open.
- [ ] **2. Claude desktop app.** Install it and sign in with an account that has a paid Claude plan (Claude Code doesn't work on the free plan).
- [ ] **3. GitHub Desktop.** Install it from desktop.github.com and sign in to GitHub.
- [ ] **4. Get the repo onto the Mac.** In GitHub Desktop: File > Clone Repository > `LouisRH47/five-stars-habibi`, and save it in Documents.
- [ ] **5. Open Claude Code on the folder.** In the Claude desktop app, open Claude Code and pick the `five-stars-habibi` folder.
- [ ] **6. Do Session 1.** Paste the Session 1 prompt below. Claude Code creates the Godot project in the folder.
- [ ] **7. Open it in Godot.** In Godot click **Import**, pick the `project.godot` file in the folder, and open it.

**After every session:** Claude Code makes a commit. Then open GitHub Desktop and click **Push origin** so it's saved on GitHub too.

## How to save credits

Most credits get wasted on long, messy sessions. These habits keep each session cheap.

- **One session = one goal.** Paste one session prompt, finish it, commit, stop.
- **Start fresh each time.** Type `/clear` before a new session. Claude Code re-reads CLAUDE.md and PROGRESS.md, so it doesn't need the old chat.
- **Be specific about bugs.** "When I press W the bike goes backwards" is cheap to fix. "It's broken" makes Claude go hunting.
- **Copy the red error text.** If Godot shows an error at the bottom, copy and paste it straight in.
- **Don't ask for extras mid-session.** Write new ideas in a notes file and add them to a later session.
- **Test before asking for more.** Check the session's checklist before moving on, so problems don't pile up.
- **Play before building more.** Don't paste the next session until you've played the last one on your Mac.

## The sessions (Tier 1)

Tier 1 is split into 17 sessions. Most take about an hour, the map sessions may take two. At 1 to 3 hours a week that's roughly 6 to 17 weeks. Do them in order. Start each one with `/clear`, then paste the prompt.

**Why this order:** the delivery loop (order, pick up, drop off, get paid) comes before the big map. If the loop isn't fun on a flat test area with boxes, a pretty map won't save it. The map is then built from a data list so villas can be moved without hand-editing anything.

### Session 1: Project, bicycle and camera (done)

```text
Read CLAUDE.md, PRD.md and BUILD_PLAN.md. We're doing Session 1.
There's no Godot project yet. Create one in this folder (project.godot) for the
Godot 4 version installed at /Applications/Godot.app (check its version first),
using the Forward+ renderer and GDScript.
Then make a flat test area (big ground plane, a few boxes to ride around) and a
bicycle the player can ride: W/S to pedal and brake, A/D to steer, Space for
handbrake. Use a simple box/cylinder model for now. Add a 3D camera that
follows behind and slightly above the rider and smoothly turns with the bike.
Then tell me how to open the project in Godot and test it.
```

Done when:

- [ ] The project opens in Godot without errors
- [ ] The bike moves, steers and stops with W, A, S, D and Space
- [ ] The camera follows smoothly without shaking
- [ ] You can't ride through the boxes

### Session 2: Bike feel and stamina (done)

```text
Session 2. Tune the bicycle so it feels good: gentle acceleration, top speed
around 25 km/h, a small lean when turning, and a bump when hitting things.
Add Shift to sprint. Sprinting drains a stamina bar (shown on screen) and
coasting refills it. Put all the numbers in scripts/game_config.gd.
```

Done when:

- [ ] Riding feels smooth and fun, not floaty or twitchy
- [ ] Shift sprints, the stamina bar drains and refills
- [ ] A speed readout in km/h shows on screen
- [ ] Esc pauses, R puts the bike back at the start, you can't ride off the edge

**Stop here until you have played Sessions 1 and 2 on your Mac.** Don't build Session 3 on top of something nobody has played yet.

### Session 3: One full delivery on the test area (built, needs testing)

```text
Session 3. Before anything else, read PRD.md "Delivery loop" and "Controls".
Build the delivery loop on the current test area (no map yet). Turn three of
the boxes into restaurants (Pizza, Brain Freeze Gelato, Boba Oasis) and ten
boxes into villas with big numbers on them. Add:
1. A small "game state" autoload (scripts/game_state.gd) that holds money,
   the delivery history and the current order, and sends signals when they
   change. Nothing else should store these.
2. An "order" data type (scripts/order.gd) with restaurant, villa number, food
   type, pay and a note.
3. A phone panel in the corner: an order pops up, E accepts, Q skips, ignoring
   it for 30 seconds counts as a skip. Ride to the restaurant marker, press E
   to pick up, ride to the villa marker, press E to deliver, money goes up.
One order at a time. No meters, no stars yet. Keep every number in
game_config.gd. Add the delivery loop to the smoke test in tests/.
```

Done when:

- [ ] Orders pop up, and you can accept or skip
- [ ] Pickup and drop-off work, and money goes up after delivering
- [ ] Doing five deliveries in a row is already a bit fun

### Session 4: Palm Grove part 1, roads and villas (built, needs testing)

```text
Session 4. Start the Palm Grove villa community from PRD.md (City map
section). Make a data file (data/palm_grove.gd or .json) that lists every
villa: number, position, which way it faces. Write a small map builder script
that reads the list and places a villa scene for each one, with a big readable
house number on the front. Lay out roads and one roundabout as simple flat
shapes, 25 to 40 villas, and put the bicycle at the community entrance.
Orders from Session 3 should now use the real villas. Keep the old test area
as a separate scene for testing.
```

Done when:

- [ ] You can ride around the whole community
- [ ] Every villa has a number you can read while riding
- [ ] Moving a villa only means changing one line in the data file

### Session 5: Palm Grove part 2, restaurants and signs (built, needs testing)

```text
Session 5. First, a five-minute test: add a free Arabic font (Noto Sans
Arabic) to assets/fonts and put ONE Label3D sign in the scene with Arabic +
English text. Confirm the Arabic letters show joined up and right-to-left
before building anything else. Then build the restaurant strip at the
community entrance with 3 restaurants (Pizza, Brain Freeze Gelato, Boba Oasis),
each with a bilingual sign, plus bilingual street-name signs. Orders now pick
up from the real restaurants.
```

Done when:

- [ ] Arabic on signs shows joined up and right-to-left
- [ ] The 3 restaurants are easy to spot from the road

### Session 6: Palm Grove part 3, decoration and static obstacles (built, needs testing)

```text
Session 6. Finish Palm Grove: a park, a mosque, a small supermarket, palm
trees, parked cars, and speed bumps that make the bike bounce. Low-poly shapes
or free CC0 assets (Kenney). The bike should collide with cars and bumps.
```

Done when:

- [ ] Palm Grove feels like a real community
- [ ] Speed bumps give a noticeable bump

### Session 7: Mini-map and addresses (built, needs testing)

```text
Session 7. Add a mini-map in the bottom-left corner showing the roads, the
player, and a marker for the next stop with the villa number. Use the villa
data file from Session 4. Some orders should have a short note like "leave it
at the door". No GPS line on the road (that's a later upgrade).
```

Done when:

- [ ] The mini-map turns with you and shows the next stop
- [ ] You can find any villa using just the mini-map and house numbers

### Session 8: The three meters (built, needs testing)

```text
Session 8. Add the time, freshness and damage meters from PRD.md (Delivery
loop, including "How the meters go from green to red"). They show on screen
during a delivery. Food types: pizza (easy), ice cream (melts fast), bubble
tea (spills on bumps). Freshness drains over time, damage drops on bumps, hard
braking and collisions. Time uses the target-time rule in the PRD.
```

Done when:

- [ ] All three meters show and change while riding
- [ ] Ice cream melts faster than pizza, and bubble tea hates speed bumps

### Session 9: Moving obstacles (built, needs testing)

```text
Session 9. Add a few cats that wander slowly and kids on scooters riding
simple routes around Palm Grove. The bike collides with them and it costs
damage. Keep them gentle: they're there to make you ride carefully, not to
block the road.
```

Done when:

- [ ] Cats and kids move around and you can bump into them
- [ ] Bumping them hurts the damage meter

### Session 10: Stars, money, tips and XP (built, needs testing)

```text
Session 10. At the end of each delivery, give 1 to 5 stars using the star
formula in PRD.md. Add pay per delivery (8 to 15 Dh), random tips only on
5-star jobs (40% chance, 2 to 15 Dh), XP and a Rider Level, and a star rating
that averages the last 50 deliveries. Show wallet, rating and level on screen.
Store all of it in the game state autoload.
```

Done when:

- [ ] A clean delivery gets 5 stars, a messy one gets fewer
- [ ] Tips sometimes appear on 5-star jobs, never on lower ones
- [ ] Wallet, rating and XP update correctly

### Session 11: Customers at the door (built, needs testing)

```text
Session 11. When you deliver, a simple customer character comes out of the
villa with a short animation and says one line in a speech bubble (make
15+ different funny lines). Some orders say "leave it at the door" and nobody
comes out.
```

Done when:

- [ ] Customers come out and say different lines
- [ ] Leave-at-the-door orders work

### Session 12: Crashes and insurance (built, needs testing)

```text
Session 12. Add crashes from PRD.md (Crashes, bills and insurance).
Small crash: rider falls off, damage meter jumps, back on after 2 seconds.
Big crash (hitting a car/wall/pole above about 20 km/h): fade out, clinic
screen, order cancelled, hospital bill 150 Dh + repair bill 80 Dh, shift ends.
The boss covers the very first big crash. Insurance (2 Dh per delivery) starts
switched on and can be toggled on the phone. With insurance, a big crash
costs only 20 Dh.
```

Done when:

- [ ] Small and big crashes both happen at the right speeds
- [ ] Bills are right with and without insurance, and the first one is free

### Session 13: Shifts (built, needs testing)

```text
Session 13. Add shifts: one shift is about 10 real minutes (one in-game day,
day shift only). Show the time of day. If the clock runs out mid-delivery, let
the player finish it. At the end, show a summary screen: deliveries, average
stars, money earned, tips, bills, XP.
```

Done when:

- [ ] The shift ends on time and the summary numbers are correct

### Session 14: Application and characters (built, needs testing)

```text
Session 14. Add the start of the game from PRD.md (Start of the game):
a phone-style Snackaroo rider application (name, where you're from), 3 character
presets to pick from, a "Reviewing..." spinner, then "Congrats, you're hired!".
The first order is an easy pizza two streets away that works as a tutorial
with short tips on screen (including that insurance is on).
```

Done when:

- [ ] You can fill in the form and pick a character
- [ ] Customers use your name
- [ ] The tutorial order explains the controls

### Session 15: Menu and saving (built, needs testing)

```text
Session 15. Add a main menu (Play, Settings, Quit) and a proper pause menu.
Save and load money, rating, delivery history, XP, character, name and the
insurance setting through the game state autoload.
```

Done when:

- [ ] Closing and reopening the game keeps your progress

### Session 16: Sound and music (built, needs testing)

```text
Session 16. Add simple sound effects (bike, bell, crash, cash), chill
Arabic-style background music (free to use, listed in CREDITS.md) and
background ambience (birds, distant traffic). Add a volume slider in Settings.
```

Done when:

- [ ] The sounds and music work and aren't annoying

### Session 17: Play-test and tuning (first pass done with the play-test bot; needs Louis's own play-test)

```text
Session 17. I'm going to play-test. Help me tune the numbers in
game_config.gd. Here's what felt off: [write what felt too easy, too hard,
too slow or too boring].
```

Done when:

- [ ] A friend plays for 10 minutes without needing help
- [ ] They want to keep playing

## The sessions (Polish pass, Sessions 18 to 24)

Tier 1 works end to end. This pass makes it feel and look like the mockup (link at the top
of PRD.md) and adds two gameplay rules Louis asked for: hold E to pick up and drop off, and
get off the bike to do it. PRD.md ("Delivery loop", "Controls" and "Screens") and its
Decisions log already describe all of this, so build from the PRD. Same rules as before:
one session at a time, run the headless checks and the smoke test, add a check for every new
system, update PROGRESS.md, commit. The world stays 3D; the cards on top copy the mockup.

### Session 18: Hold E to pick up and drop off (plus a test fix) (built, needs testing)
```text
Session 18. Read CLAUDE.md, PRD.md (Delivery loop and Controls) and PROGRESS.md.
1) Picking up at the restaurant and dropping off at the villa now need E held for
1.5 seconds while you're at the door and going under 5 km/h. Accepting an order
stays a quick tap. Show an orange bar on the phone that fills while E is held;
letting go, moving away or speeding up resets it. If you're at the door but too
fast, the phone says "Slow down, then hold E". After any E action, E has to be
let go before the next hold counts. Put the times (PICKUP_HOLD_TIME,
DROPOFF_HOLD_TIME) and INTERACT_MAX_SPEED_KMH in game_config.gd.
2) Fix the smoke test check "the customer says a line from the list": it fails
about 1 run in 4 because the test hires a rider called Sam, but the check fills
{name} with the default name. Use the real rider name (CustomerSpawner.fill_line).
Smoke test: a short E press does nothing, a full hold picks up and delivers.
Run the smoke test 5 times in a row; it must pass every time.
```

Done when:

- [ ] A quick tap of E at the door does nothing, holding it for 1.5 s picks up or delivers
- [ ] The orange bar fills on the phone and resets when you let go or ride off
- [ ] The smoke test passes 5 times in a row

### Session 19: Get off the bike (walk to the door) (built, needs testing)
```text
Session 19. Read PRD.md (Delivery loop, Controls). Add getting off the bike.
F gets off and back on, only when the bike is under 5 km/h. When you get off,
the bike stays parked where it is (solid, stand down) and you control the rider
on foot: W A S D to walk (about 5 km/h), Shift to jog (about 9 km/h), the camera
follows the rider the same way it follows the bike. Picking up and dropping off
(the hold E from Session 18) only work on foot. Walk back to within 2 m of the
bike and press F to get on. The meters and the shift clock keep running while you
walk, so parking near the door is the skill. If you walk more than 40 m from the
bike the phone says "Your bike is over there" and the mini-map shows the bike.
On foot you can't sprint into cats or kids hard enough to crash, and R puts both
you and the bike back on the road. The phone hints change: "Press F to get off"
near a door on the bike, "Hold E to drop off" at the door on foot, "Press F to
ride" next to the bike. Smoke test: ride to a villa, F, walk to the door, hold E,
walk back, F, ride away.
```

Done when:

- [ ] F gets you off and on, but not while moving fast
- [ ] You can walk around, and the camera follows you smoothly
- [ ] You can only pick up and deliver on foot
- [ ] The bike stays parked and you can't drive it while walking
- [ ] The smoke test does the full off, walk, deliver, back on run

### Session 20: Fonts, colours and panels like the mockup (built, needs testing)
```text
Session 20. Read PRD.md (Screens). Download Baloo 2 and Nunito from Google Fonts'
GitHub repo (SIL Open Font License), put them in assets/fonts with their OFL
licence files, and add them to CREDITS.md. Make one Godot Theme (ui/theme.tres)
with the PRD's fonts and colours and use it everywhere. Restyle the HUD panels,
the meters panel, the mini-map ring and the phone to match the mockup's
"Gameplay" artboard: dark see-through rounded panels, Baloo 2 for big numbers,
Nunito for text, the phone as a white rounded card with the Snackaroo header,
status pill, pick up / drop off rows, food and pay chips and the customer note.
Don't change what any screen does, only how it looks. Take screenshots of the
game and compare them with the mockup.
```

Done when:

- [ ] Every screen uses Baloo 2 and Nunito, and Arabic still shows joined up
- [ ] The HUD and phone look like the mockup's gameplay screen
- [ ] Fonts and their licences are in assets/fonts and CREDITS.md

### Session 21: Start screen like the mockup (built, needs testing)
```text
Session 21. Read PRD.md (Screens: start screen) and look at the mockup's
"Start: rider application" artboard. Rebuild the main menu and the rider
application as one screen: on the left "AL SARAB · السراب", the big
"Five Stars Habibi" title, orange "Rider to Driver" and one line about the
game, in front of a low-poly 3D desert (dunes, a big pale sun, a palm). On the
right a phone. On the main menu the phone has Play (or Continue), New game,
Settings and Quit. The first time you play, the phone becomes the Snackaroo
rider application: name, where you're from, "Pick your look" with 3 cards
(Classic, Sporty, Chill), each showing its own little 3D rider, and a
Submit application button. Then "Reviewing..." and "Congrats, you're hired!"
on the same phone, and "Start riding". Keep everything the application does
now (saving, 43 countries, the tutorial).
```

Done when:

- [ ] The start screen looks like the mockup, with the 3D desert behind the title
- [ ] The 3 look cards each show a little 3D rider, and the picked one is highlighted
- [ ] Play, Continue, New game, Settings and Quit still work, and saving still works

### Session 22: The Delivered card (built, needs testing)
```text
Session 22. Read PRD.md (Screens: Delivered card) and look at the mockup's
"Delivery complete" artboard. After every delivery: pause the game (and the
shift clock), cut the camera to a 3D shot of your rider and the customer at the
villa door (or the bag on the doorstep for leave-at-the-door orders) with the
customer's line in a white speech bubble. On the right show the white card:
"Delivered!", the stars, "Ice cream to Villa 14 · 1:58" (food, villa, ride
time), three tiles Time / Freshness / Damage with a word and a colour each,
then Delivery pay, 5-star tip (only if you got one), Insurance, a bold
"You earned" total and the XP. "Next order · E" (button or E) closes it and the
game carries on. Use the real numbers from GameState. Smoke test: after a
delivery the card shows, its total matches the money you got, and E closes it.
```

Done when:

- [ ] The card shows after every delivery and matches the mockup
- [ ] The 3D shot shows your rider and the customer (or the bag) at the door
- [ ] The numbers on the card are the real ones, and E carries on

### Session 23: The clinic screen like the mockup (built, needs testing)
```text
Session 23. Read PRD.md (Screens: clinic screen) and look at the mockup's
"Big crash: clinic bills" artboard. Rebuild the clinic screen: a simple 3D
clinic room behind it (pale teal walls, a bed with your rider lying in it, a
drip stand), filmed from the side like the mockup. Left: a small red
"BIG CRASH" label, the big title "You woke up at Wahat Al Shams Clinic", one
sentence with what you hit and how fast ("You hit a parked car at 27 km/h. The
ice cream didn't make it, and your shift is over for today.") and a teal Arabic
sign "عيادة واحة الشمس". Right: the white "Your bills" card from the mockup
with the ORDER CANCELLED · 0 STARS tag, Clinic bill, Bike repair (Snackaroo),
Insurance, the red "You pay" total, the yellow insurance tip (only if it was
off), the "Big crashes this week" bar and the buttons "Turn on insurance" (only
if it's off) and "Shift summary". Show the "boss covered it" version for your
first big crash. Keep what it does now (bills, shift ends).
```

Done when:

- [ ] The clinic screen looks like the mockup, with the 3D room behind it
- [ ] The bills are the real ones, including the boss-covered first crash
- [ ] Turn on insurance works, and Shift summary goes to the end-of-shift screen

### Session 24: Play-test the polish pass (built, needs testing)
```text
Session 24. Run the play-test bot for a careful and a careless shift and the
smoke test 5 times. Take screenshots of the gameplay HUD, the start screen, the
Delivered card and the clinic screen, and list anything that doesn't match the
mockup. Check that walking to the door doesn't make deliveries too slow: a careful
shift should still get about 10 deliveries. Tune game_config.gd if not.
Then I'll play it myself; here's what felt off: [write it here].
```

Done when:

- [ ] All four screens match the mockup closely
- [ ] A careful shift still gets about 10 deliveries
- [ ] Louis has played a full shift and is happy with it

## The sessions (Graphics pass, Sessions 25 to 34)

The polish pass made the screens look right. This pass fixes Louis's two biggest problems:
the map feels empty, and deliveries get the same after a few. It moves Tier 1 to a new
community, Wahat Al Shams, builds Dubai-style houses, adds light, people and life, and adds
special orders, goals and events. Everything is already in PRD.md: "Shifts", "Special
orders, goals and events", "Graphics and feel" and "Wahat Al Shams, the Tier 1 community"
in the city map section. Build from the PRD. Same rules as before: one session at a time,
headless checks and smoke test, a smoke test check for every new system, PROGRESS.md,
commit. Keep the game running at 60 fps on Louis's Mac on Medium: check the frame time
in every session that adds things to the map.

### Session 25: Wahat Al Shams layout (and 5-minute shifts) (built, needs testing)
```text
Session 25. Read CLAUDE.md, PRD.md (Shifts, and "Wahat Al Shams, the Tier 1
community") and PROGRESS.md.
1) Shifts are now 5 minutes: SHIFT_LENGTH = 300 in game_config.gd (08:00 to
18:00 stays, so 30 s per in-game hour). Fix anything that assumed 10 minutes.
2) Build the new map (sketch: docs/wahat_al_shams_map.svg) from a new data list data/wahat_al_shams.gd and the builder
scripts (reuse map_builder, place_builder and sign_builder where you can), in a
new scene scenes/wahat_al_shams.tscn. About 400 m east-west by 300 m north-south:
tree belt and horse track round the edge, ring road, main gate on the west with
the bilingual welcome sign, the Plaza area by the gate (flat for now, shops come
in Session 27), the green spine west to east (grass, paths, stream; no domes yet),
5 cluster plots (C1 to C3 north, C4 and C5 south) with narrow lanes and a
mini-plaza space in each, solar car parks on the ring road by each cluster (no
door more than 40 m away), bollards at the lane entrances, and plain plots for
the school, mosque, stables and building site. 60 homes as simple placeholder
boxes with door spots, numbered 1 to 12 per cluster ("Villa 7, Cluster 3").
Move the 3 restaurants and the mini market to the Plaza so deliveries work.
Phone, mini-map and customers use the new addresses ("C3 · Villa 7"). Cats,
kids and speed bumps get new spots. Main menu starts the new map. Keep
palm_grove.tscn as an old test map for now.
Smoke test: runs on Wahat Al Shams by default, rides from the gate into the
Plaza, and checks every home's door spot can be reached by bike (no walls in the
way). The play-test bot also runs on the new map.
```

Done when:

- [ ] The game starts in Wahat Al Shams and a full delivery works there
- [ ] A shift lasts 5 minutes, 08:00 to 18:00
- [ ] Every home has an address like "Villa 7, Cluster 3" on the phone and mini-map
- [ ] No car can get into a cluster, but the bike can

### Session 26: The house kit and the 3 villa types (built, needs testing)
```text
Session 26. Read PRD.md ("The houses" in the Wahat Al Shams section) and look at
docs/villa_types.svg. Make a
house kit in code (scripts/villa_builder.gd plus small part scripts if needed):
L-shaped two-storey block, flat roof with parapet, roof terrace, tilted solar
panel canopy on posts, wind tower (barjeel) with slots, small deep windows,
wooden door with a house number, low courtyard wall with a gap, a wooden
mashrabiya screen. Use matt cream and sand colours (LowPoly helper). Build the
3 types: courtyard villa (10 per cluster), garden villa (1, big lawn and tree)
and signature villa (1, bigger corner home with the mashrabiya). Replace the
placeholder boxes from Session 25. Make each home different using its number
as the seed: door colour, plants, a golf buggy or bikes outside, toys, AC units,
a satellite dish, panels on the front or back, and a small pool or trampoline
on garden and signature villas. Add the bilingual cluster signs at the lane
entrances. Merge meshes or use MultiMesh so 60 homes stay fast.
Take screenshots of a lane, a mini-plaza and a signature villa.
```

Done when:

- [ ] The homes look like docs/villa_types.svg: cream L-shape, roof terrace, solar panels, wind tower
- [ ] You can tell homes apart by their details, and they're the same every time
- [ ] Still 60 fps on Medium, and door spots still work

### Session 27: The Plaza, the spine and the landmarks (built, needs testing)
```text
Session 27. Read PRD.md (Wahat Al Shams section: the Plaza, green spine,
school, mosque, stables, building site, and the shops table). Build:
- The Plaza: a sunken round square (steps down, fountain, date palms, shade
  sails, benches) with 6 shop fronts round it, each with a bilingual sign and
  door spot: Pizza, Brain Freeze Gelato, Boba Oasis, Shawarma Supreme, Sunrise
  Bakery, Al Sarab Mini Market.
- The green spine: 6 white dome greenhouses, farm beds, beehives, a donkey pen,
  a basketball court, a playground, and the Wahat Farm Stall with a door spot.
- The cluster mini-plazas: a cooling tower, a small playground and benches.
- Al Shams School with a fenced yard and a security booth at the gate (the only
  drop-off spot), the mosque with a minaret (no door spot, scenery only), the
  stables with a stable block, a paddock and the stable office (the only drop-off
  spot), and the building site with a crane and "Phase 2 coming soon".
- New foods in game_config.gd: shawarma, cake, groceries, farm juice/salad, with
  freshness and damage numbers like the PRD table.
Orders can now pick up from all 7 pickup spots and drop off at homes, the
school booth and the stable office (just the spots for now; who orders and when
comes in Session 32). Smoke test: an order from each new shop works, the mosque
never gets an order, the school and stables only use their one spot.
```

Done when:

- [ ] The Plaza looks like a real little hub with 6 shops round a sunken square
- [ ] The spine has the domes, farm, donkeys, court and playground
- [ ] Orders work from every shop and the farm stall, to homes, the school booth and the stable office
- [ ] The mosque never gets an order

### Session 28: Light, sky and the graphics setting (built, needs testing)
```text
Session 28. Read PRD.md (Graphics and feel: Light, Graphics setting). Make the
sun follow the shift clock: low and warm at 08:00, high and white at noon, a
golden sunset from 17:00 to 18:00 (sun colour, angle, sky colours and ambient
light all change smoothly). Add SSAO, a light haze towards the edge of the map
(fog), a gentle glow, and heat shimmer above the roads around noon (a simple
screen or road shader). Add a Graphics setting (Low / Medium / High, default
Medium) to the Settings panel and save it with the other settings: Low turns off
SSAO, shimmer and haze, shorter shadow distance; High turns everything on.
Smoke test: the sun angle at 08:00, 12:00 and 18:00 is different, and switching
Low/Medium/High doesn't give errors. Take screenshots at 08:00, 12:00 and 17:30.
```

Done when:

- [ ] Morning, noon and sunset look clearly different, and the sunset is golden
- [ ] Low / Medium / High works and is saved
- [ ] Still 60 fps on Medium

### Session 29: Animated people and the real bike (built, needs testing)
```text
Session 29. Read PRD.md (Graphics and feel: Art, People move, The bike).
Download a free CC0 character pack with animations (Kenney or Quaternius,
check the licence says CC0), put it in assets/ and credit it in CREDITS.md.
Use it for the rider (pedalling on the bike, idle, walk, jog on foot),
customers (idle, walk out, wave), and the new types: teachers, school kids,
riders and grooms. Keep the 3 looks (Classic, Sporty, Chill) and the 5 resident
outfits by colouring or swapping parts. Build a proper low-poly bike in code or
from a CC0 model: pedals turn with speed, handlebars turn when you steer, the
kickstand drops when you get off. B rings the bell (a new home-made sound in
tools/make_sounds.py): people near you look up and wave, cats move aside.
Also use CC0 packs for the parked cars in the solar car parks and for plants.
Smoke test: B plays the bell, pedals turn faster at higher speed.
```

Done when:

- [ ] The rider and customers walk, wave and pedal, no more sliding capsules
- [ ] The bike's pedals, handlebars and kickstand move, and B rings the bell
- [ ] Every new asset is CC0 and listed in CREDITS.md

### Session 30: Life on the map (built, needs testing)
```text
Session 30. Read PRD.md (Graphics and feel: Life on the map). Add:
golf buggies that drive slowly on fixed routes round the ring road and spine
paths (they stop and wait if you're in the way, bumping one is like bumping a
kid), horses with riders walking and trotting on the edge track, joggers and
walkers on the paths, gardeners watering in front of homes, kids playing at the
cluster mini-plazas, birds flying over, palms swaying, the stream and fountain
water moving, ducks on the stream and donkeys in their pen. No traffic AI: every
buggy, horse and walker follows its own path from the data list. Fewer of them
on Low. Smoke test: buggies move along their route and stop for the bike.
```

Done when:

- [ ] Wherever you ride you see someone or something moving
- [ ] Buggies stop for you, and nothing walks through walls
- [ ] Still 60 fps on Medium

### Session 31: Juice (built, needs testing)
```text
Session 31. Read PRD.md (Graphics and feel: Juice). Add: dust puffs from the
tyres on sand and when braking hard (GPUParticles3D, fewer on Low), speed lines
at the screen edges and a slightly wider camera (FOV) while sprinting, coin and
star pops (little animated icons and a sound) when you deliver, and the phone
buzzing (a quick shake plus a buzz sound) when a new order comes in. Use Tweens
for the small animations. Keep every effect short so it doesn't get annoying.
Smoke test: sprinting raises the FOV and it comes back after, a new order makes
the phone buzz.
```

Done when:

- [ ] Riding, sprinting, braking and delivering all feel punchier
- [ ] Nothing flashes or shakes so much it's annoying

### Session 32: Special orders, school and stables orders, regulars, goals (built, needs testing)
```text
Session 32. Read PRD.md (Special orders, goals and events). Add:
- Special orders (rush, fragile cake, neighbour, big family order) with their
  rules and rewards, about 1 in 6 orders, a coloured chip on the phone.
- School orders from teachers and kids, only 08:00 to 15:00, lunch rush 11:30 to
  12:30. Stables orders from riders and grooms. Farm orders from the farm stall.
- The 4 regular customers with a heart on the phone, their own lines that use
  your name, and a 60% tip chance.
- 2 shift goals on the phone at the start of each shift, a 15 Dh bonus each,
  shown on the shift summary.
Put every number in game_config.gd. Save regulars' progress in the save file.
Smoke test: each special order type can be made and finished, a school order
never comes after 15:00, a done goal adds its bonus.
```

Done when:

- [ ] Each special order works and feels different
- [ ] School orders stop after 15:00 and pick up at lunch
- [ ] The regulars show up and know your name
- [ ] Goals show at the start and pay out on the summary

### Session 33: Random events (built, needs testing)
```text
Session 33. Read PRD.md (Random events). Add road works (cones, a barrier and a
small digger close one cluster lane or one part of the ring road for 1 to 2
in-game hours, with a cone icon on the mini-map) and horses crossing (a groom
leads 2 or 3 horses across a path for about 5 s; riding into them is a small
crash). At most 2 events a shift, one at a time, the phone warns you first. Make
sure road works never block the only way to a home. Smoke test: each event
starts and ends, and every home is still reachable during road works.
```

Done when:

- [ ] Road works and horses crossing both happen and the phone warns you
- [ ] You can always still reach every home

### Session 34: Play-test the graphics pass (built, needs testing)
```text
Session 34. Run the play-test bot for a careful and a careless shift on
Wahat Al Shams, and the smoke test 5 times. A careful 5-minute shift should get
about 6 to 8 deliveries; tune game_config.gd if not (pay too, so a careful shift
still earns about the same per minute as before). Check the frame time on Low,
Medium and High. Take screenshots: the gate, the Plaza, a cluster lane, the
spine, the school gate, the stables, and the sunset. If everything works, remove
the old Palm Grove map and its data. Then I'll play it myself; here's what felt
off: [write it here].
```

Done when:

- [ ] A careful shift gets about 6 to 8 deliveries and feels busy
- [ ] The map never feels empty, and the deliveries feel different from each other
- [ ] 60 fps on Medium
- [ ] Louis has played a full shift and is happy with it

## The sessions (Detail pass, Sessions 35 to 46)

See the [implementation and acceptance ledger](docs/implementation-status.md) for the current evidence and open gates for Sessions 35–51.
Louis and friend feedback and the school-photo comparison are skipped at the user's request on 4 November 2026.

Louis played the graphics pass. The houses, playgrounds, stables and NPCs are good. What he wants
changed: the map should copy the real community at real size, the homes should be joined rows,
there are too many blank spaces and plain surfaces, the restaurants need insides, the school is
hard to find, and money should buy upgrades and clothes. Everything is in PRD.md: "Wahat Al Shams,
the Tier 1 community" (city map section), "Shops and upgrades", "Shifts", "Controls" and
"Graphics and feel". Sketches: docs/wahat_al_shams_map.svg (layout), docs/villa_types.svg
(houses, unchanged), docs/shop_screens.svg (shop screens). Same rules as before: one session at a
time, headless checks, smoke test and play-test bot, a smoke test check for every new system,
PROGRESS.md, commit. The map is now about 5 times bigger and has 500 homes: check the frame time
on Medium after every session that adds things to the map, and use merged meshes, MultiMesh and
simpler far-away versions (visibility ranges) to keep it at 60 fps.

### Session 35: Real-size map, the new layout and the corrected AM/PM clock

**35A clock rule:** one real gameplay second equals one game minute. The 8:00 AM–6:00 PM
shift lasts ten active real minutes, and the AM/PM display advances every minute.
Keep the sun icon and matching event times, with pause/tutorial/final-delivery/save checks.
**35B** covers the real-size map, addresses and routes. The original sequence called for
measuring route times and earnings on the full placeholder map before adding detailed
buildings. See PROGRESS.md for the 35A results and manual test.

```text
Session 35. Read CLAUDE.md, PRD.md ("Wahat Al Shams" in the city map section,
Shifts) and PROGRESS.md, and look at docs/wahat_al_shams_map.svg.
1) The fixed clock rate is one real gameplay second per game minute. Derive
SHIFT_LENGTH from 08:00 to 18:00 at that rate: 600 active seconds (ten real
minutes, 60 s per game hour). The clock reads "9:40 AM" and advances one
minute per active second, with a small sun icon. Use that same game clock
for lunch, events and sunlight. Keep action timers in real seconds.
2) Rebuild data/wahat_al_shams.gd at real size, about 940 m west to east and
500 m north to south, following the sketch: highway on the west with two
entrances (north-west and south-west), tree belt, horse track, blue run and
cycle track, ring road, then mosque, bus station (with its own short road to
the ring road) and a bigger Plaza area in the north-west; school, C Institute,
jumping arena and stables plots in the south-west; the green spine west to
east; 5 cluster plots (C1 to C3 north, C4 and C5 south) with their lanes;
solar car park plots in the gaps between clusters; building site plots on the
empty patches. Plain shapes are fine for now; later sessions dress them.
3) 500 door spots (100 per cluster) on placeholder blocks, numbered 1 to 100
per cluster: "Villa 45, Cluster 1" on the phone, "C1 · Villa 45" on the
mini-map. Each shift starts in front of the bus station. Move the shops' door
spots to the new Plaza so deliveries still work.
4) The mini-map and route finder work on the bigger map. Smoke test and
play-test bot run on the new map. Take a top-down screenshot and compare it
with the sketch.
```

Done when:

- [ ] The map is real size and laid out like the sketch, with nothing big left blank
- [x] A shift lasts 10 active real minutes and the AM/PM clock advances one game minute per second
- [ ] You start in front of the bus station and a full delivery works

### Session 36: Joined rows of homes and the camera fix

```text
Session 36. Read PRD.md ("The homes" and "Addresses" in the Wahat Al Shams
section). Replace the placeholder blocks with the Session 26 house kit, but
joined like the real ones: homes side by side in long rows with no gaps, two
rows back to back with a wall between, a lane on both sides so every front
door faces a lane, and now and then a small alley through a row. 4 double
rows of 12 to 13 homes a side per cluster: 90 courtyard, 8 garden and 2
signature villas per cluster (signature villas on corners). Keep the small
details per home (door colour, plants, bikes, AC units...). Build each double
row as one merged mesh, with a simpler version far away. Keep the cluster
mini-plazas. Camera fix: cast a ray (or use a SpringArm3D) from the rider to
the camera and pull the camera in front of any wall, so it never ends up
inside a house; ease it back out smoothly.
Smoke test: every door spot can be reached; the camera never ends inside a
house collider while riding a lane.
```

Done when:

- [ ] Clusters look like the real ones from above: long joined rows with lanes between
- [ ] The camera never goes inside a house
- [ ] Still 60 fps on Medium with all 500 homes

### Session 37: Car parks with solar roofs, cars, buggies and buses

```text
Session 37. Read PRD.md (Solar car parks, "Who drives where", Bus station).
Build the solar car parks in the gaps between clusters (not behind homes): a
short road off the ring road, car bays, and a solar panel roof over every bay,
with parked cars. Cars drive slowly round the ring road on set routes and pull
in and out of the car parks; they never enter the lanes (bollards). Move the
golf buggies off the ring road: they only drive the cluster lanes and spine
paths, and stop for you. People walk, and kids ride bikes and scooters, on the
lanes and paths. A bus drives round the ring road into the bus station every
in-game hour, waits, and leaves. No real traffic AI: everything follows its
own path from the data list. Smoke test: no buggy on the ring road, no car in
a lane, cars and buggies stop for the bike.
```

Done when:

- [ ] Every car park has solar roofs and sits between clusters
- [ ] Cars only on the ring road, buggies only inside, and the bus comes and goes

### Session 38: Horse track, run and cycle track, jumping arena and stables

```text
Session 38. Read PRD.md (Horse track, Run and cycle track, Horse jumping
arena, Stables). Make the edge horse track dirt and sand with white horse rails
on both sides, with gaps where the gate roads cross. Horses with riders walk
and trot round it; nobody else can get on it (the rails block the bike). Make
the run and cycle track beside it blue, for runners, cyclists and you, never
buggies or cars. Build the jumping arena next to the school: sand, white horse
rails, a few jumps, and a horse with a rider that jumps now and then. Move the
stables (stable block, paddock, stable office drop-off spot) next to it.
```

Done when:

- [ ] Horses go round the edge on their own track, and you ride the blue track beside it
- [ ] The jumping arena has horses jumping

### Session 39: The Plaza, restaurant fronts, mosque, bus station and checkpoints

```text
Session 39. Read PRD.md (The Plaza, the restaurant table, Mosque, Bus
station, Highway and 2 checkpoints). Build the bigger Plaza: five low-rise
blocks with flats and offices above and shop fronts below, round the sunken
square (fountain, date palms, shade sails, benches). 12 shop fronts, each
different (awning colour, sign shape, outside seats) with a bilingual sign:
the 10 restaurants from the PRD table plus Pedal Point Bikes and Dune Drip.
Rename the old shops (Pizza to 1000 Pizza, Boba Oasis to Spill the Tea,
Sunrise Bakery to Bread & Zaatar, the mini market to Grand Groceries) and add
the new foods to game_config.gd (pad thai, sushi, tacos, burgers, coffee,
manakish) with freshness and damage numbers like the PRD table. Put the
mosque in front of the Plaza and the bus station between them (shelter, bay,
bus, "Coming soon: travel to other districts"). Build the two checkpoints:
booth, red-and-white barrier and one guard who waves; the barrier lifts for
cars and the bike rides through a side gap. Smoke test: an order from each of
the 10 restaurants can be picked up.
```

Done when:

- [ ] The Plaza feels like a real little town centre with 12 different shop fronts
- [ ] Mosque, bus station and checkpoints look right, and the guard waves

### Session 40: Restaurant insides and the side-panel style

```text
Session 40. Read PRD.md ("Restaurant fronts and interiors" and "Shop
screens"). Give every restaurant a walk-in inside, each different (the PRD
lists what's in each): a counter with a staff member, 2 to 4 tables with a few
customers, a menu board, decor. Picking up now happens inside: walk in, hold E
at the counter, the staff member hands you the bag. Make one reusable side
panel (ui/side_panel) in the game style (dark see-through, orange header,
Baloo 2 and Nunito) that shows the order while you're at the counter; the
shops, the C Institute and the gym will use it too. The camera works indoors
(no walls in the way). Smoke test: walk into each restaurant, hold E at the
counter, walk out.
```

Done when:

- [ ] Every restaurant has its own inside, and no two look the same
- [ ] Picking up at the counter works and the side panel shows the order

### Session 41: Fair Grade International School and the C Institute

```text
Session 41. Read PRD.md (Fair Grade International School, C Institute). Build
the school from the PRD description: a 3-storey sand building with curving
wings, white rounded balcony bands, flat white roofs with AC boxes, railings
and a rooftop garden; a big boxy sports hall with a dark window strip and the
bilingual sign along the top, flags at the entrance; long solar roofs over the
school car park; a fenced football pitch, two shaded pools, basketball and
tennis courts, two shaded playgrounds; a low white wall and the gate security
booth (the only drop-off spot). Make it easy to see from far away. Build the C
Institute beside it, with its huge glass front and wide stepped seats facing
the spine (people sitting on them) and a small car park behind; inside, one
tall modern lobby up to the roof with a reception desk and a receptionist.
Walk in and hold E at reception to deliver (side panel). Add teachers, kids and
institute staff as customers. Smoke test: a school order and a C Institute
order both work.
```

Done when:

- [ ] You can spot the school from across the map, and it looks like Louis's photos
- [ ] The C Institute faces the spine, and you can walk in and hand food to the receptionist

### Session 42: The green spine: hills, grass, domes path, gym and pools

```text
Session 42. Read PRD.md ("The green spine"). Give the spine a real grass
texture with tufts and flowers, gentle hills between 0.5 and 1.5 m that the
bike rolls over smoothly (no hill steeper than the bike can ride), and more
trees. Space the domes evenly along one path that links them all, with no big
gaps. Fix the glitchy dome doors (z-fighting: move the door a little in front
of the dome or cut a hole). Build the gym in the middle: a small box rounded at
the back, glass front with treadmills inside, a lap pool along its side, and
the gym reception drop-off spot (side panel). Build the community pool a
little way off: sunbeds, umbrellas, a kids' area and people swimming. Smoke
test: the bike rides over the hills without getting stuck; a gym order works.
```

Done when:

- [ ] The spine looks green and alive, with little hills and no big gaps between domes
- [ ] The gym, lap pool and community pool are there, and the dome doors look right

### Session 43: Textures, details and building sites everywhere

```text
Session 43. Read PRD.md ("Details everywhere", Building sites). Add real-looking
textures (free CC0, e.g. ambientCG or Poly Haven, credited in CREDITS.md) for
grass, sand, paving patterns and asphalt, with road lines and kerbs. Add props
so nothing looks plain: lamp posts, bins, recycling points, bike racks,
electric car chargers, planters, benches and signs. Fill every empty patch with
a building site: fence with a bilingual "Coming soon" banner, a crane, sand
piles, a site cabin and a couple of workers. Take screenshots from 10 places
and fix anything that still looks blank.
```

Done when:

- [ ] No big blank or plain areas anywhere on the map
- [ ] Textures and props make it feel like a real place, still 60 fps on Medium

### Session 44: Speed feel and fixes

```text
Session 44. Read PRD.md ("Graphics and feel": Speed, Camera). Top speed 28
km/h, sprint 36 km/h (game_config.gd). Stronger speed lines, a bigger camera
stretch while sprinting and a wind sound (tools/make_sounds.py). Remove the
heat shimmer completely (it looked like a warpy smear in front of the bike).
Find and fix the people with no head (check every outfit and pack model).
Re-tune the play-test bot for the new speeds. Smoke test: no person model is
missing a head mesh.
```

Done when:

- [ ] Riding and sprinting feel fast, with no warpy smear
- [ ] Everyone has a head

### Session 44A: Rider falls and crash presentation (planned)

```text
Read PRD.md “Crashes, bills and insurance”, Planned crash upgrade.
Capture the collision before stopping the bike: relative impact speed, direction,
angle and obstacle category/hardness. Build a short fall sequence for both rider
and bike: gentle tip/recovery, sideways skid and hard frontal tumble. Match the
direction/intensity to the impact; keep the rider visible and use suitable sound
and camera feedback. A major crash must finish its fall before the clinic fade.
Minor crashes recover back into gameplay. Keep the existing soft-character
collision policy. Use reliable authored/physics-assisted falls first; full ragdoll
is optional. Lock normal controls during the fall, guarantee recovery/transition,
and prevent bounce contacts from creating extra accidents.
```

Done when:

- [ ] A soft/slow hit, a glancing scrape and a hard frontal collision have visibly different falls
- [ ] Direction and intensity reflect the captured impact, with readable camera framing
- [ ] A major crash shows the fall before the hospital; a minor fall returns control safely
- [ ] Secondary bounce contacts cannot repeat crash counts, cancellation or consequences
- [ ] Louis watches the reactions at normal speed and likes how they look and feel

### Session 44B: Impact-based crash bills and insurance (planned)

```text
Use Session 44A's single captured impact record to choose a severity band.
Replace flat treatment/repair bills with tunable bands based on relative impact
speed, angle and obstacle hardness. An equally fast glancing wall scrape should
cost less than a head-on hit; a harder obstacle or a stronger impact should
increase the bill. Minor recoverable falls have little or no charge. Insurance
reduces the bill with a severity-dependent, capped contribution; keep the first
major crash covered by the boss. The clinic explains the obstacle, impact speed,
severity, treatment, repair, insurance and final amount due. Charge once per
accident, then preserve the major-crash order-cancellation and shift-ending flow.
Put all thresholds/prices/caps in game_config.gd and tune against shift earnings.
Exact amounts are playtest values. When Session 45 adds the rocket, test that its
forced-major-crash rule uses this same animation and billing flow.
```

Done when:

- [ ] Representative low/medium/high impacts produce distinct, explainable bills
- [ ] Head-on versus glancing and soft versus hard obstacle cases follow the intended severity order
- [ ] First-crash cover and insurance work, including different capped insured payments by severity
- [ ] One fall creates one bill, one crash count and at most one cancelled order
- [ ] Tests verify severity boundaries and billing; a playtest checks the costs feel proportionate

### Session 45: Pedal Point Bikes (upgrades, cart and checkout, rocket booster)

```text
Session 45. Read PRD.md ("Shops and upgrades": shop screens and Pedal Point
Bikes) and look at docs/shop_screens.svg. This replaces the old gear shop
session. Build the bike shop inside (bikes on the wall, tool pegboard, a
mechanic at the workbench) and the shop screen: walk in, hold E at the
mechanic, the camera turns to your bike on a stand (it turns slowly, drag to
turn it) and the side panel opens on the left with the upgrade list: level,
price, Owned, locked, NEW. Cart and checkout: E adds to the cart, C buys
everything in it. Make every upgrade work (GPS route line on the road and
mini-map, louder bell, insulated bag, anti-spill box, stamina +10% up to 10
times, better brakes, comfy tyres, aluminium and carbon frames, bike paint and
box colours). The rocket booster: Level 10, 10,000 Dh, X fires it for 4 s at
80 km/h with flames, 30 s to recharge, triple bump damage, any crash is a big
crash. Show the next goal with a progress bar on the phone and the shift
summary. Items in a data file, prices in game_config.gd, save what you own.
Smoke test: buy two upgrades through the cart, check they work and are saved.
```

Done when:

- [ ] The bike shop looks like the mockup, and you see your bike while you shop
- [ ] Cart and checkout work, and every upgrade does what it says
- [ ] The rocket booster is crazy fast and only for late game

### Session 46: Dune Drip clothes shop, then play-test the detail pass

```text
Session 46. Read PRD.md ("Shops and upgrades": Dune Drip) and look at
docs/shop_screens.svg. Build the clothes shop inside (racks, a shelf of caps and
glasses, a rug in front of a big mirror, a cashier at the counter). Hold E at
the cashier: the camera turns to face your rider standing on the rug, like in
GTA's clothes shops, and the side panel opens with types (caps, glasses,
helmets, tops, shoes, bags). A/D or a click tries items on straight away, drag
turns your rider, E adds to the cart, C checks out, Esc leaves and puts your
old look back if you didn't buy. Clothes show on your rider everywhere. Make
the clothes from the CC0 character pack's parts or simple shapes. Save them.
Then play-test: run the bot for a careful and a careless ten-minute shift and the
smoke test 5 times; a careful shift should feel busy and earn enough to buy the
GPS route after about one shift. Tune game_config.gd. Screenshots: checkpoints,
bus station, Plaza, a restaurant inside, a cluster row, the spine with the gym,
the school, the C Institute, the jumping arena, both shops. Then I'll play it
myself; here's what felt off: [write it here].
```

Done when:

- [ ] Trying on clothes feels like a real game shop, and what you buy shows everywhere
- [ ] A careful ten-minute shift feels busy and pays for the first upgrade in about one shift
- [ ] Louis has played a full shift and is happy with it

## Reasons to come back (Sessions 47 to 51)

Players come back when they always have a next goal, every delivery feels good, skill pays off, and there are characters they care about. Right now money and XP don't buy anything, so these sessions come before the itch.io release. The design is in PRD.md, "Reasons to come back". These are ideas, not orders: cross out any you don't want. The old gear shop session is now Session 45 (Pedal Point Bikes). Same rules as before: one session at a time, play it before the next one.

### Session 47: Streaks, personal bests and PERFECT!

```text
Session 47. Read PRD.md "Reasons to come back", 5-star streak and personal
bests, and "A perfect delivery feels special". Each 5-star delivery in a row
adds +5% tip chance (max +30%); a crash or a delivery under 5 stars resets it.
Show the streak on the phone. Track personal bests (best shift earnings,
longest streak, most deliveries in a shift, fastest ride to each home) and show
"New best!" on the shift summary. Save them. On the Delivered card, all three
meters green shows "PERFECT!" with a jingle, and a tip gets its own jingle
(make the sounds in tools/make_sounds.py).
```

Done when:

- [ ] A streak makes you ride more carefully, and losing it stings a little
- [ ] A perfect delivery and a new best feel good

### Session 48: Choosing orders

```text
Session 48. Read PRD.md "Reasons to come back", Choosing orders, and the
"better order" rule in Stars. At a rating of 4.5 or more, half the time show
two orders side by side on the phone: 1 or 2 picks one, Q skips both (counts
as one skip). One of the two is a better order. Keep the 30-second timer.
Special orders and regulars can be one of the two.
```

Done when:

- [ ] Choosing between two orders is a real decision
- [ ] A high rating feels worth having

### Session 49: Tomorrow's special

```text
Session 49. Read PRD.md "Reasons to come back", Tomorrow's special. Each shift
is a kind of day: normal, Hot Noon, Rush Hour or a shop special. Show today's
kind of day by the clock and tomorrow's on the shift summary. It must work with
the lunch rush, the shift goals and the random events. Numbers in
game_config.gd.
```

Done when:

- [ ] Shifts feel different from each other
- [ ] Seeing tomorrow's special makes you want one more shift

### Session 50: Collections, regulars and the profile page

```text
Session 50. Read PRD.md "Reasons to come back", Collections and "Regulars get
to know you". Add a Profile page to the phone: the Wahat Al Shams stamp card
(a stamp for each of the 500 homes, grouped by cluster, plus the school gate,
the stable office, the C Institute and the gym; 20 Dh for every 25 homes in a
cluster, a gold box colour for a full cluster), the
cats and horses you've met (give each a name in the data file) and the
customer lines you've heard. Give each regular lines for a first visit,
getting friendly and best friends. Save it all.
```

Done when:

- [ ] You can see how much of Wahat Al Shams you've collected
- [ ] The regulars feel like they know you

### Session 51: Final play-test, then itch.io and the browser

```text
Session 51. Run the play-test bot for 5 shifts in a row (careful) and check
money, XP and upgrades come at a good pace: the GPS route after about one
shift, the first frame after about a week of play, the rocket booster only
after a long time. Tune
game_config.gd if not. Run the smoke test 5 times. Then export Mac and Windows
versions for itch.io, and check the browser version at
fivestarshabibi.middleleap.com (Mac and iPad) is up to date and plays well. Here's what felt off when I played: [write it here].
```

Done when:

- [ ] A friend plays for 10 minutes and wants to keep going
- [ ] It's on itch.io
- [ ] The browser version plays the same game on a Mac and an iPad

## Looks pass (Sessions 52 to 59)

From Louis's play-test of the detail pass on 4 November. Everything is in PRD.md, "Looks pass".
Same rules as always: one session at a time, headless checks, smoke test and the focused tests,
a check for every new thing, PROGRESS.md, commit. Check the frame rate on Low, Medium and High
after every session that adds things, and take screenshots of what changed.

### Session 52: Sharper graphics, no flicker, C Institute and the bug fixes

```text
Session 52. Read PRD.md "Looks pass" (Sharper graphics, No more flicker, C Institute
fix, Bugs found in testing).
1) Anti-aliasing per level: Low FXAA, Medium MSAA 4x, High MSAA 4x + TAA, full
resolution on desktop (keep scaling_3d/scale.web = 0.75). 4 shadow cascades and a
bigger shadow map on Medium and High. Crisp 3D text and signs. On first start, test
the computer and pick Low/Medium/High (save it; Settings can change it).
2) Fix the flicker: merge the flat ground layers (roads, lanes, paths, lawns, paving,
courts, plazas) into one ground mesh with painted areas, or give each layer a clear
height step plus render priority. Check the camera near/far planes. Fix the dome doors.
3) Turn the C Institute so a long glass side faces the spine (east) with the stepped
seats in front, and add big windows on the opposite side too.
4) Fix the crash loop (push the bike back after a small crash with a short grace
period; standing people step aside) and make crashes cost more so a careful shift
clearly earns more than a careless one.
Smoke test, all focused tests, and the play-test bot careful and careless (twice).
Screenshots at full screen before and after.
```

Done when:

- [ ] Full screen looks sharp on Louis's Mac, with no jagged edges
- [ ] Roads, paths and the dome doors don't flicker
- [x] The C Institute's glass and seats face the spine, with windows on both sides
- [x] The careless bot earns clearly less than the careful one and never gets stuck in a crash loop

### Session 53: The free asset kits (built, needs testing)

```text
Session 53. Read PRD.md "Looks pass", Interiors. Download the CC0 kits: KayKit
Restaurant Bits and KayKit Furniture Bits (GitHub: KayKit-Game-Assets), Kenney
Furniture Kit and Food Kit (kenney.nl), a CC0 supermarket pack, and CC0 gym models
from Poly Pizza (check each model's licence is CC0, skip anything else). Put them
in assets/kits/<pack>/ with their licence files, credit them in CREDITS.md, use the
glTF versions, and make a small prop library (scripts/props.gd) that places a model
by name with a position, rotation and scale. Keep the downloads small: only the
models we use.
```

Done when:

- [ ] The kits are in assets/kits with licences, and CREDITS.md lists them
- [ ] A test scene shows a row of props from each kit

### Session 54: The new restaurant room, and the first 5 restaurants (built, needs testing)

```text
Session 54. Read PRD.md "Looks pass", Interiors and the table. Make one restaurant
room template: about 12 x 10 m inside, 4.5 m ceiling (the outside stays the same,
the rest is a storeroom you can't enter), big glass front, sliding glass door, menu
board, kitchen with a cook behind the counter, staff at the counter, tables with
people eating, drinks fridge, bin, plants, hanging lamps with warm light and soft
shadows, tiled floor in the shop's colours. Short queue: sometimes 1 or 2 people,
2 to 4 seconds. The camera moves closer indoors. Each place gets its own background
sound in tools/make_sounds.py. Build 1000 Pizza, Brain Freeze Gelato, Spill the Tea,
Shawarma Supreme and Bread & Zaatar with the props from the table. Smoke test: walk
into each, wait in the short queue, hold E, walk out.
```

Done when:

- [ ] The 5 restaurants look like the designs, cosy and full, not big and empty
- [ ] You can see inside from the Plaza, and the doors slide open
- [ ] The queue is short and never annoying

### Session 55: The other 5 (Tok Tok Thai, Sushi You, Mario Bonito, Burgerology, Grand Groceries) (built, needs testing)

```text
Session 55. Read PRD.md "Looks pass", the table. Using the Session 54 template, build
Tok Tok Thai, Sushi You (sushi bar with a moving conveyor belt, stools, fish case,
two chefs, lanterns, curtain, booth, pick-up counter), Mario Bonito and Burgerology.
Grand Groceries is a supermarket instead: drinks fridges along the back wall, 3 shelf
units with hanging bilingual aisle signs and price strips, fruit and veg stand, bread
shelf, sweets rack, 2 checkouts with belts and a cashier; pick up at checkout 1;
shoppers with trolleys and baskets. Smoke test: an order from each works.
```

Done when:

- [ ] No two restaurants look alike, and Sushi You's belt moves
- [ ] Grand Groceries looks like a real supermarket

### Session 56: The gym and the C Institute inside (built, needs testing)

```text
Session 56. Read PRD.md "Looks pass", the Wahat Gym and C Institute rows. Build the
gym as a real gym (glass wall onto the spine and lap pool, 4 treadmills facing the
glass, bikes, squat rack with barbell, dumbbell rack, 2 rowing machines, yoga mats,
kettlebells, mirror wall with "Train hard · تمرّن بقوة", rubber floor, water fountain,
towel stand, reception with a smoothie cooler) with people running, rowing and
lifting. Build the C Institute lobby two storeys tall (glass both sides, balcony,
stairs, stepped seats with people on laptops, the talk screen that changes during
the shift, hanging plants, wood ceiling, reception with the C logo). Smoke test: gym
and institute orders work.
```

Done when:

- [ ] The gym looks and feels like a gym
- [ ] The C Institute lobby is tall and bright, and the talk screen changes

### Session 57: Bike shop, clothes shop, stable office, farm stall and school booth (built, needs testing)

```text
Session 57. Read PRD.md "Looks pass", the last 5 rows of the table. Rebuild Pedal
Point Bikes, Dune Drip, the stable office, the Wahat Farm Stall and the Fair Grade
school gate booth to match. Keep the shop screens (side panel, cart, mirror) working.
Smoke test: both shops still sell, and the three drop-off spots work.
```

Done when:

- [ ] Every place you go into is as detailed as the restaurants

### Session 58: Plaza, streets and the spine (built, needs testing)

```text
Session 58. Read PRD.md "Looks pass", More detail outside. Plaza: café tables outside
the restaurants, a juice kiosk, string lights that come on at sunset, more people.
Streets and lanes: street lamps that light up at sunset (road markings and kerbs are in Session 61),
bins, bilingual street signs, bike racks. Spine: real grass blades (MultiMesh) on
Medium and High, a sparser version on Low, plus flowers, rocks and more trees.
```

Done when:

- [ ] The Plaza, streets and spine no longer look plain
- [ ] Low still runs smoothly on an iPad-like setting

### Session 59: Play-test the looks pass (automatic checks done, needs Louis's play)

```text
Session 59. Run the smoke test and every focused test, the play-test bot careful and
careless, and the frame-rate check on Low, Medium and High at 1920 x 1080 and full
screen. Screenshots of every interior, the Plaza, a street, the spine, and full
screen from the bike. List anything that still flickers or looks plain and fix it.
Then I'll play it myself; here's what felt off: [write it here].
```

Done when:

- [ ] Every interior matches its design, and nothing flickers
- [ ] 60 fps on Medium on Louis's Mac
- [ ] Louis has played a full shift and is happy with how it looks

## World polish pass (Sessions 60 to 74)

**Order:** Session 60 (the road network) was built straight after looks pass Session 52, at Louis's request. Then do looks pass Sessions 53 to 59 (interiors), then Sessions 61 to 74. Road markings and kerbs from looks Session 58 are done in Session 61 instead, so they aren't built twice. Louis played the detail pass on 5 November 2026.
He likes the houses, construction sites, grass, buggies, car parks, gym, community
pool and swimmers, water, trees, food stall, light posts, lifeguard, gym pool, horse riding and
the Medium and Low graphics settings. Leave those alone unless a session says otherwise.

What he wants changed: a proper road network (the biggest job), real road textures, rounder
shapes, no glitching textures, no blank sand, more greenery, real-looking signs, people who
dress for where they are and don't vanish, a football pitch at the school, better horses,
donkeys and playgrounds, a full map on M and a resolution setting.

**The approved road plan is the source of truth for the layout:**
[Wahat Al Shams road plan](https://claude.ai/artifact/M7enEb5UZm5waPm9WizpuD) (a copy is in
`docs/road_plan_2026-11-05.svg`). Its numbered list explains each change. Reference photos
Louis took in the real community are described in the sessions that use them.

Same rules as before: one session at a time, headless checks, smoke test and play-test bot,
a smoke test check for every new system, PROGRESS.md, commit. The map data is generated by
`tools/build_wahat_data.py`: change the generator, then regenerate `data/wahat_al_shams.gd`.
Never hand-edit the generated file. Keep all 500 addresses (100 per cluster, same numbers and
IDs) even where homes move. Check the frame time on Medium after any session that adds things.

**Working style:** before each session, write a short plan. Then split the work between
several agents running in parallel where the parts don't touch the same files (for example
textures, signs and data in Session 65).

### Session 60: The road network from the approved plan (built, needs testing)

```text
Session 60. Read CLAUDE.md, PRD.md (City map: Wahat Al Shams) and PROGRESS.md, then open
docs/road_plan_2026-11-05.svg. First update PRD.md's Wahat section to match the plan and
add the decisions to the Decisions log. Then change tools/build_wahat_data.py and
regenerate the data:
1) The ring road is the only main road. It connects to exactly four things: the two gate
   roads from the highway, the bus station loop (off the north side, next to the mosque)
   and one wide road into the stables car park at the back. Nothing else touches it.
2) Remove: the old Bus Access road, the Plaza Link, the Stables Road, the
   road beside the jumping arena, the north part of the Western Link and the cluster
   alleys that run through the end houses.
3) The inside network is one connected set of roads with rounded corners (radius about
   12 to 14 m), with no dead ends: the spine road (east-west, the only road with red
   tracks); the cluster front road (z -40) that curves into a roundabout east of the
   C Institute, loops round the east end of the park and comes back as the south road,
   which curves into the school road; the school road, which bends up into the west end
   of the spine road; the road behind the C Institute (from the roundabout west, then
   down to the spine road); and the roundabout's north exit, which curves into the east
   side of the Plaza between the restaurants and the clothes shop.
4) Cluster lanes are asphalt. Every cluster has a front cross road and a back cross road
   joining all five lanes; only the front one links out (one entrance link per cluster).
   No cluster road touches the ring road. Keep at least 12 m between any cluster road and
   the ring road (Cluster 3 moves 10 m west, Clusters 4 and 5 move 6 m north, and the back
   cross roads sit at z -189 and 189).
5) Add the stables car park (beside the stables, off the ring road) and a row of roofed
   school car park bays right at the school entrance, beside the school road. The phase 3
   site south of the mosque already exists. Majlis Gardens and the pitch come later
   (Sessions 66 and 72).
6) Buses only drive on the ring road and the bus loop. Move START to the bus station
   platform. Update the route finder, GPS, mini-map, bus recovery and the play-test bot.
Take a top-down screenshot and compare it with the plan.
```

Done when:

- [ ] A top-down screenshot matches the approved road plan
- [ ] Driving the ring road, the only ways off are the two gates, the bus loop and the stables car park
- [ ] Every inside road joins another road or a roundabout: no road just stops
- [ ] All 500 addresses still work and a full delivery works from the new start
- [ ] Smoke test, navigation test and bus recovery test pass

### Session 61: Road surfaces, markings and junctions (built, needs testing)

```text
Session 61. Make the roads look real.
1) Use a proper CC0 asphalt texture (Poly Haven or ambientCG, credited in CREDITS.md),
   with light wear and a slightly darker centre. Low graphics can use a plain version.
2) Yellow dashed centre line on every road, and white direction arrows on each side
   every 40 m (drive on the right, like the UAE). The ring road gets arrows every 60 m.
3) Kerbs on both sides. Corners and junctions are real curved meshes, not overlapping
   rectangles. Where asphalt meets pavers, the asphalt runs through on top and the
   pavers stop at its edge. No two flat surfaces at the same height, so no flickering
   ("glitching textures").
4) Remove all the tyre marks. Instead, add faint, short skid marks only when the rider
   brakes hard, and let them fade after a while.
5) Re-place the speed bumps and road works on the new roads.
```

Done when:

- [ ] Every road has a yellow centre line and arrows showing which way each side goes
- [ ] No flickering anywhere where roads, pavers and grass meet (check every cluster junction)
- [ ] No tyre marks except short fading ones after a hard brake
- [ ] Frame time on Medium is no worse than before

### Session 62: The spine road and red walking tracks (built, needs testing)

```text
Session 62. Louis's photo: a paver road with a yellow line, then a narrow planter with a
low kerb and grass, then a smooth red walking track, all under leaning date palms, with
hedges and purple flower beds. Copy that look for the spine road only.
1) Spine road cross-section, both sides: asphalt, planter (about 2 m, kerb, grass, small
   shrubs), red walking track (about 2.5 m, matte red-brown, slightly raised).
2) Buggies and the bike can't drive onto the red track: a kerb blocks them, with marked
   crossing gaps at each junction and path. People walk and jog on it.
3) Date palms, hedges, bougainvillea and purple flower beds along the spine planters.
4) Connect the grass pathway at the C Institute to the spine road, and turn the
   C Institute benches so people sit facing outwards.
```

Done when:

- [ ] The spine road looks like the photo, with red tracks on both sides
- [ ] You can't ride onto the red track except at the crossing gaps
- [ ] Joggers and walkers use the red tracks
- [ ] The C Institute path goes somewhere and its benches face outwards

### Session 63: Greenery, round tracks and no bare sand (built, needs testing)

```text
Session 63. Make the edges green and round.
1) Palms, trees and hedges in the strip between the ring road and the blue track, all the
   way round.
2) Round corners on the blue track and the horse track, matching the ring road. Give the
   blue track a texture (fine rubbery surface with lane lines), not flat blue.
3) Replace bare sand in front of houses and beside roads with pavers, grass and planters.
   Sand stays only at the stables, the jumping arena and the horse track, where the
   horses ride.
4) Make the edge of the map more detailed outside the horse track: a thick tree belt,
   low dunes and a few far-off shapes so the world doesn't end in flat sand.
```

Done when:

- [ ] There's no plain sand anywhere except the horse areas
- [ ] The tracks have curved corners and the blue track has a texture
- [ ] Looking out past the fence shows trees and dunes, not an empty edge

### Session 64: Bus station loop, bus stop and car parks (built, needs testing)

```text
Session 64. 1) Build the bus station as a loop off the ring road: buses turn in, go round
a platform island, then turn back out. The island has two detailed shelters (roof,
glass back panel with a route map, benches, a bin and a small sign), and 3 to 5 people
waiting who board when a bus stops. The bus stop is right next to the road, not far
across the sand.
2) Build the stables car park and the school car park with the same solar roofs, cars
and markings as the other car parks.
```

Done when:

- [ ] Buses loop through the station and people get on
- [ ] Both new car parks look like the existing ones

### Session 65: Cluster entrances and signs (built, needs testing)

```text
Session 65. Louis's photos are of the real signs.
1) Cluster sign: a dark green board on a pale blue metal frame with a pole, like the
   real "SIKKA E" sign. Ours says "Cluster 3" (Arabic المجموعة ٣ under it) where the real
   one says SIKKA E, with arrows and house ranges ("Villa 1-25 ←") and an EXIT line.
   One at each cluster entrance, standing on the planter beside the lane, never in the
   road.
2) Police sign: a white board with a red "Attention" header and a camera icon, a made-up
   emblem (a star and a dhow, no real police badge) and the text "5-Star Habibi Police:
   Area is monitored by Habibi Smart Home Security" in English and Arabic. One at each
   cluster entrance and a few along the red tracks.
3) Small bilingual STOP signs where each cluster entrance meets the road.
4) Move the bins to the back of each cluster beside the road. Move the pool sign so it
   stands in front of the gate, not behind it.
5) Big end houses: a larger version of the normal house kit at the road end of each row
   where there's empty space now.
Check the Arabic letters are joined and right-to-left on every sign.
```

Done when:

- [ ] Every cluster has its green sign, police sign and stop sign beside the lane
- [ ] No sign stands in the road
- [ ] The end houses match the others, just bigger
- [ ] Bins are at the back and the pool sign is in front of the gate

### Session 66: Majlis Gardens and the new building site (built, needs testing)

```text
Session 66. 1) Majlis Gardens in the empty strip between the car park and Cluster 1: a
small fountain, palm shade, benches, curving paver paths that join the paths around it,
a small community garden bed and a few people sitting or walking.
2) Phase 3 building site south of the mosque, dressed like phase 2 (fence, crane,
materials, sign "Phase 3 coming soon" in English and Arabic).
```

Done when:

- [ ] The blank space by Cluster 1 is a park people use
- [ ] The phase 3 site looks like phase 2

### Session 67: Glitch fixes, full map and resolution setting (built, needs testing)

```text
Session 67. 1) Fix the flickering textures on the restaurant walkways and any other
place where two surfaces overlap.
2) The school pool shade floats: give it posts and a proper roof.
3) Press M to open a full-screen map of the whole community, with names, your position,
the current pickup and drop-off and a legend. M or Esc closes it. The game pauses while
it's open.
4) Add a Resolution option to the graphics tab: window size choices on desktop and a
render scale (50, 75, 100%) everywhere, saved with the other settings.
```

Done when:

- [ ] No flickering at the restaurants
- [ ] M shows the whole map and closes again
- [ ] Changing resolution works and is remembered

### Session 68: People who live here (built, needs testing)

```text
Session 68. 1) Customers who walk out of a restaurant keep walking along the paths to a
home in a cluster and go in the door. Nobody vanishes in plain sight. Only people near
the rider are fully animated; the rest move along cheaply in the background.
2) Give every place its own kind of person (list below). Swimmers wear swimwear.
```

| Place | Who you see |
| --- | --- |
| Community pool, gym pool, school pool | Swimmers in swimwear, lifeguard in red and yellow |
| Gym | Gym clothes, towels, water bottles |
| School | Pupils in uniform, teachers with lanyards |
| Stables and arena | Riders in jodhpurs and helmets, grooms |
| Plaza and restaurants | Shoppers with bags, families, waiters in aprons |
| Bus station | Commuters with backpacks and suitcases |
| Spine road red tracks | Joggers, dog walkers, parents with buggies |
| Majlis Gardens and playgrounds | Kids playing, parents on benches |
| Beekeeper | Beekeeper in a white suit and veil |
| Building sites | Workers in hi-vis vests and hard hats |
| Farm beds and planters | Gardeners with hats |
| Clusters | Neighbours in casual clothes, kids on scooters |

Done when:

- [ ] Follow someone out of a restaurant: they walk home and go inside
- [ ] Each place has its own kind of people and swimmers wear swimwear

### Session 69: The beekeeper as a pickup (built, needs testing)

```text
Session 69. The beekeeper works like a restaurant: orders for honey jars and wax
candles, picked up at a stall beside the hives and delivered to homes. It shows on the
phone, mini-map and full map.
```

Done when:

- [ ] A honey order can be picked up at the beekeeper and delivered

### Session 70: Blender models and textures (built, needs testing)

```text
Session 70. Blender is installed on Louis's Mac. Run it from the command line (headless)
with Python scripts kept in tools/blender/, so every model can be rebuilt. Export .glb
files into assets/models/ with their own textures. Original work only.
1) A new horse (better shape, mane and tail, a few coat colours) that works with the
   existing riding animation, and a donkey (shorter, longer ears, grey-brown) for the
   donkey pen. The current "horse" looks like a donkey: replace it.
2) New textures for the things that need work: the blue track, the red track, the horse
   track sand, the pavers and the playground surfaces.
Keep the polygon count low so Low graphics still runs smoothly.
```

Done when:

- [ ] The horses look like horses and the donkeys look like donkeys
- [ ] The tracks and pavers use the new textures
- [ ] The Blender scripts rebuild every model and texture

### Session 71: New playgrounds (built, needs testing)

```text
Session 71. Design new playgrounds in Blender: rounded slides, a climbing frame, swings,
a small spinner and soft rubber flooring, in bright but soft colours. Less blocky than
now. Use them in every cluster playground and in Majlis Gardens, with kids playing.
```

Done when:

- [ ] Every playground uses the new rounded designs and kids play on them

### Session 72: School football pitch (built, needs testing)

```text
Session 72. Replace the green area in front of the school with a full football pitch:
markings, two goals with nets, a running track along one side, and a fence of tall posts
(taller than now) with netting. Remove the tennis court and the basketball court. Four
floodlights light only the pitch, and switch on automatically when it gets dark. Add
pupils playing during the day.
```

Done when:

- [ ] There's a full pitch with goals and a running track, fenced with tall posts
- [ ] The floodlights come on at dusk and light only the pitch

### Session 73: More life at the stables (built, needs testing)

```text
Session 73. Add more jumps to the arena and more riders doing them. Use the new horses,
with a few riders waiting their turn and grooms walking horses near the stables.
```

Done when:

- [ ] Several riders take turns over several jumps

### Session 74: Play-test the world polish pass (automatic checks done, needs Louis's play)

```text
Session 74. Run the smoke test, every focused test suite and the play-test bot. Check
the frame time on Low, Medium and High at the busiest spots (Plaza, bus station, spine).
Take a top-down screenshot and compare it with the approved road plan again. Then I'll
play a full shift. Here's what felt off: [write it here].
```

Done when:

- [ ] All tests pass and Medium stays at 60 fps
- [ ] Louis plays a shift and is happy with the roads, greenery, signs and people

### Later (not in this pass)

- **Delivery robot:** a small robot that can do deliveries, as an upgrade. Plan it after
  this pass.
- **Desktop game instead of only the browser:** the repo already has
  `tools/build_desktop.py`. Decide after Session 74 whether the main version should be the
  Mac and Windows download (faster loading, bigger textures) with the browser version kept
  as a lighter demo.


## Fix pass (Sessions 75 to 84)

From Louis's play on his Mac on 5 November 2026, after the world polish pass. Roads, signs,
bus stop, playgrounds, Majlis Gardens, NPC placement and the gym are good. What needs work:
invisible walls, kerbs that don't join up, sharp 90° corners, the Plaza floor, the box-shaped
shops, car park layouts, textures that got worse, swimmers and the lifeguard, the gym/stream
clash, NPCs that look lifeless, and a few odd spots (the blue patch at the C Institute, the
grass gap at the cluster playgrounds).

**Textures (chosen 5 Nov, real CC0 photo textures from Poly Haven, saved in tex_dl/ for the
build):** running_track (blue, with lane lines) for the blue bike track; the same photo
recoloured red, one lane without the line, for the red walking tracks; brick_pavement_02,
tinted warm sandy grey like Louis's lane photo, for paver lanes and footpaths;
square_concrete_pavers for the new square Plaza floor; the old aerial_grass_rock (before
5 Nov) mixed with leafy_grass for the lawns; the old sand_01 for sand; the old water look.
Keep the new road asphalt. Credit each in CREDITS.md (Poly Haven, CC0).

Same rules as always: one session at a time, headless checks, smoke test, focused tests,
play-test bot careful and careless, a check for every new thing, PROGRESS.md, commit. Before
handing over, open the game on Louis's Mac (Forward+) and take screenshots of what changed.

### Session 75: Ride freely, jump on foot, buggies on roads

```text
Session 75. 1) Remove every invisible wall that isn't a real object: the solid spine kerbs
(scripts/spine_tracks.gd _solid_kerb), any invisible kerbs along other red tracks, the
blue track and car parks, and anything else the bike bumps into where nothing is visible
(walk the bike along every road edge with a test to find them). Low visible kerbs stay;
riding over one gives a small bump and a little speed loss, never a crash.
2) Remove all speed bumps except the ones on the ring road.
3) On foot only, Space makes the rider jump (about 0.6 m, short cooldown, a landing
animation). On the bike Space stays the handbrake. Update the PRD Controls table and the
pause menu key list.
4) Buggies only drive on roads: build their routes from the road network (ROADS and the
rounded road chains) instead of straight lines across the clusters, keep them on their side
of the yellow line, and slow down at junctions and the roundabout.
```

Done when:

- [ ] You can ride across every red track and kerb anywhere, with only a small bump
- [ ] Speed bumps are only on the ring road
- [ ] Space jumps when walking and still brakes on the bike
- [ ] Every buggy stays on asphalt for a whole shift (test checks this)

### Session 76: Kerbs that join up and curved corners

```text
Session 76. Louis's screenshots show kerbs that don't meet (roundabout, cluster entrances,
junctions) and sharp 90° turns. 1) Rebuild kerbs as continuous strips that follow every
road edge, curve round every corner, close up at junctions (the kerb turns into the side
road), wrap the whole roundabout (outer ring and island) and leave gaps only for crossings
and car park entrances. 2) Every 90° corner where two roads meet gets a curved inside
corner (radius about 6 m for lanes, 10 m for bigger roads), including the cluster lane
corners and the cluster entrances. 3) The C Institute access road follows a smooth curve
from the spine road to the door. 4) Add a test that finds kerb ends that don't touch
another kerb, a gap or a crossing (0 allowed).
```

Done when:

- [ ] No kerb ends in mid-air anywhere (the test finds 0)
- [ ] The roundabout kerbs join all the way round
- [ ] Every road corner is curved, including the C Institute road

### Session 77: A square Plaza floor and the Dune Drip buggy park

```text
Session 77. 1) Replace the round Plaza paving with one square paved floor using the
square_concrete_pavers texture, running from the bike shop to Dune Drip and from the north
restaurant row to the south row, so every restaurant door, both shop doors and the café
tables stand on paving. Nothing stands on grass. Keep the fountain and sunken square where
they are now. 2) The road from the roundabout no longer ends at nothing: it leads to a small
buggy car park (4 to 6 spaces, markings, a buggy or two parked) behind Dune Drip, with a
footpath from there into the Plaza. 3) Check the ground at every restaurant entrance is
paving (test).
```

Done when:

- [ ] The Plaza floor is one square of paving touching every door
- [ ] The Plaza road ends in a small buggy park behind Dune Drip

### Session 78: Bike shop and Dune Drip look like real buildings

```text
Session 78. Keep their fronts and insides. Change the box shape: a stepped roofline with a
parapet, a shaded arcade with columns along the Plaza side, a small wind tower or roof
feature, window bays and trim on the side walls, a shop-colour band, and details round the
outside (Pedal Point: bike rack with bikes, a pump stand; Dune Drip: planters, a bench).
Make it look good and cool, in the same Arabic-modern style as the houses. Do the same for
any other blank wall that faces the Plaza.
```

Done when:

- [ ] Neither shop looks like a plain box from any side

### Session 79: Car parks laid out properly, and a mosque car park

```text
Session 79. Every car park (between the clusters, beside C3 and C5, the stables and the
school) uses one layout: a row of spaces along one side, two rows in the middle facing each
other nose to nose, a row across the end, aisles between, solar roofs over every row and
cars in most spaces. Painted bay lines and arrows. The entrance stays where it is. Add a
mosque car park (about 12 spaces, same style) in front of the mosque, joined to the ring
road (update the PRD: the ring road now also meets the mosque car park).
```

Done when:

- [ ] Every car park has the side row, two middle rows and an end row, mostly full, with roofs
- [ ] The mosque has its own car park off the ring road

### Session 80: The C Institute front, seats and the basketball court

```text
Session 80. 1) Remove the blue (pool-looking) patch in front of the C Institute; make it
grass and put a small 5-a-side football pitch there (lines, two small goals with nets) with
people playing during the day. 2) Raise the outdoor seats/steps so seated NPCs' feet show
above the surface (check every bench and step seat in the game for the same problem).
3) Make the basketball court more detailed: proper lines, hoops with nets and backboards,
a fence, benches and a couple of players.
```

Done when:

- [ ] No blue patch, and people play football in front of the C Institute
- [ ] Nobody's feet disappear into a seat
- [ ] The basketball court looks finished

### Session 81: Gym, stream and pools

```text
Session 81. 1) Flatten the ground around the gym and the community pool so no hill dips into
water or a building. The stream ends in a small pond with stones round the edge before the
gym instead of running under it. 2) The community pool keeps its layout but looks less
basic: tiled deck, a proper edge and coping, ladders, lane ropes, loungers and umbrellas,
a shower post, plants. 3) Swimmers in all three pools swim properly: arm strokes, kicking,
heads above the water, laps across the pool, a couple resting at the edge; they wear
swimwear and nobody floats like they're dead. 4) The lifeguard sits on a tall lifeguard
chair, turns to look around, sometimes stands up and blows a whistle. 5) Water uses the old
look from before 5 November (or better).
```

Done when:

- [ ] Nothing glitches into the water or the gym
- [ ] Swimmers swim and the lifeguard sits on his chair and watches

### Session 82: Textures

```text
Session 82. Use the textures chosen above (copy them from tex_dl/ into assets/textures/,
with .import files, credited in CREDITS.md). 1) Grass: the old aerial_grass_rock mixed with
leafy_grass so it doesn't repeat. Sand: the old sand_01. Pavers and footpaths:
brick_pavement_02 tinted warm sandy grey. Blue track: running_track. Red track: running_track
recoloured red (one lane, no line). Keep the new road asphalt. 2) Remove all the rectangle
grass blade clumps (scripts/spine_greenery.gd); keep flowers, rocks and trees. 3) Fix the
glitchy textures on signs (text flicker or shimmer). 4) Bins grey instead of green. 5) Fill
the grass gap beside each cluster playground with the paving. 6) Look at every surface on
Low, Medium and High on Louis's Mac and fix anything blurry, stretched or too repetitive
(texture scale per surface in one place).
```

Done when:

- [ ] Grass, sand, pavers and tracks look like real photos, not flat colour
- [ ] No rectangle grass clumps
- [ ] Signs don't shimmer, bins are grey, no grass gaps by the playgrounds

### Session 83: People who look alive

```text
Session 83. 1) Every NPC that stands or sits moves a little: breathing, turning the head to
look around, shifting weight, and pairs talking with hand gestures. Add simple eyes and a
smile to faces. Keep it cheap: only people near the rider animate fully. 2) Check every
outfit (swimwear, gym kit, uniforms, jodhpurs, hi-vis, bee suit, waiters, commuters) for
clothes poking through bodies or floating, and fix them all. Add a test that builds each
outfit and checks the clothes stay on the body.
```

Done when:

- [ ] No NPC stands frozen, and faces have eyes
- [ ] No glitched clothes on any outfit

### Session 84: Play-test the fix pass on Louis's Mac

```text
Session 84. Run the smoke test, every focused suite and the play-test bot careful and
careless. Then open the game on Louis's Mac and take screenshots of every spot changed in
Sessions 75 to 83 (Plaza, shops, car parks, roundabout and kerbs, cluster entrances, pools,
gym, C Institute front, tracks). Fix anything that still looks wrong, then hand over.
```

Done when:

- [ ] All tests pass and Louis is happy with the screenshots and his own play


## When something breaks

Copy one of these and fill in the brackets.

**Error in Godot (red text at the bottom):**

```text
Godot shows this error when I [what you did]:
[paste the red error text]
Please fix it and tell me how to check it's fixed.
```

**Something works wrong:**

```text
When I [what you did], [what happened]. It should [what you expected].
Please find the cause and fix just that.
```

**Everything is broken and you want to undo:**

```text
The last changes broke the game. Go back to the last git commit
that worked and tell me what you undid.
```

**Lost track of where you are:**

```text
Read PROGRESS.md and BUILD_PLAN.md and tell me which session I'm on
and what's left in it.
```

## After Tier 1

Once Sessions 47 to 51 feel fun and the game is on itch.io and in the browser (Session 51), friends can play it and give feedback. After that, the next block of sessions is the motorbike test (yard course, instructor, theory quiz), then the motorbike, Old Town, night shifts and running costs. Ask Claude Code to "write the Tier 2 sessions for BUILD_PLAN.md in the same style as Tier 1" so the plan keeps growing as you go.

## Confirmed choices

- Simple low-poly graphics, using basic shapes and free CC0 asset packs like Kenney
- Claude Code used through the Claude desktop app
- Keyboard controls for now (W A S D, Shift, Space, E, Q); controller support later
- Built on a paid Claude plan (Claude Code doesn't work on the free plan)
- About one 1-hour session a week
