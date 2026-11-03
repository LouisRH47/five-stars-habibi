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

### Session 29: Animated people and the real bike

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

### Session 30: Life on the map

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

### Session 31: Juice

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

### Session 32: Special orders, school and stables orders, regulars, goals

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

### Session 33: Random events

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

### Session 34: Play-test the graphics pass

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

Once the graphics pass (Session 34) feels fun, upload it to itch.io for free so friends can play it and give feedback (ask Claude Code to export Mac and Windows versions). After that, the next block of sessions is the motorbike test (yard course, instructor, theory quiz), then the motorbike, Old Town, night shifts and running costs. Ask Claude Code to "write the Tier 2 sessions for BUILD_PLAN.md in the same style as Tier 1" so the plan keeps growing as you go.

## Confirmed choices

- Simple low-poly graphics, using basic shapes and free CC0 asset packs like Kenney
- Claude Code used through the Claude desktop app
- Keyboard controls for now (W A S D, Shift, Space, E, Q); controller support later
- Built on a paid Claude plan (Claude Code doesn't work on the free plan)
- About one 1-hour session a week
