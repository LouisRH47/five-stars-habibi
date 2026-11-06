## Life pass (Sessions 86 to 97)

From Louis's play on 6 November 2026 after the fix pass. He likes the restaurants, the Plaza,
the gym inside, the pools, the lifeguard, the roads, the signs, the playgrounds, Majlis Gardens,
the football and basketball courts, the grocery store, the construction site and the juice stand.
This pass adds the things he asked for: a loading screen, real crash physics, three delivery
companies with logos, a proper phone app, a flea market, the mansion and its owner DJ Salad,
and a long list of look fixes. **Build this block before the rest of the Steam pass** (Session 85
is built; Sessions 98 to 102 are the old 86 to 90).

Decisions Louis made on 6 Nov (all in the PRD Decisions log):
- Loading screen: the start-screen desert with a bike riding along the bottom, a progress bar
  and rotating tips; shown until the whole world is built, and again at the start of each shift.
- Three companies on the application form, same jobs, one perk each: **Snackaroo** (orange,
  default, +10% tips), **Zoomaroo** (green, customers wait 20% longer), **Deliverooz** (teal,
  bigger box so less food damage). Switch later in the phone for a small fee. One drawn logo per
  company on the box, shirt, phone, van and signs.
- Crashes have three levels: bump (under 12 km/h or anything soft: wobble, 10 Dh, small rating
  hit), fall (12 to 22 km/h: fall off, 30 Dh, food damage), big crash (over 22 km/h into something
  hard: hospital, 150 Dh). Real ragdoll instead of the spinning stick; the message says the real
  speed.
- Flea market in the Plaza about every third Friday, 8 stalls, extra people, one-off orders;
  the phone tells you the day before.
- The mansion by Cluster 5 (between its car park and the road): Arab-modern, two floors,
  courtyard pool, garage, wall and gate. 25,000 Dh, needs Tier 3 and DJ Salad's tasks. Once
  owned you start shifts there, can walk in, and the garage holds your bikes.
- **DJ Salad** owns it until you buy it: a bit overweight, DJ look, takes deliveries from day one,
  "For sale" sign up from the start. At Tier 3 you message him; he sets 3 tasks (10 five-star
  deliveries to him, a special package from the bee farm, a timed airport delivery once you're a
  taxi driver) before he sells.
- Press P opens a full phone with apps: Jobs, Profile, Collection, Messages, Company, Map,
  Settings. Mock-up first, then build. Orders still pop up on the small corner phone.
- C Institute: second floor inside (balcony, glass offices with people, meeting room, stairs and
  a lift you can use); outside keeps the big glass but goes more modern.
- Dubai-style skyline, very faint, far behind the Plaza, made-up shapes with one tall spire.
- Space jumps on foot only (from the fix pass). Blender for new models (stroller, logos, mansion
  details) with scripts in tools/blender/.

Research notes (6 Nov): Godot's threaded-load progress only counts files and jumps 0 to 100, so
the loading bar must count the world builder's own steps and build a few per frame. Ragdolls use
PhysicalBone3D on the rider's Skeleton3D ("Create physical skeleton", then delete the tiny bones;
keep about 8); start with physical_bones_start_simulation() and give the bones their own
collision layer so the rider's capsule doesn't fight them. UAE delivery apps by size: Talabat
(about 45%), Deliveroo, Careem Food, Noon Food. Modern Arabic villa look: white render, a tall
pointed entrance arch with a full-height geometric mashrabiya screen, the upper floor as a
"floating" box, courtyard pool, flat roof, sandstone and vertical fins, lights in the arches at
night.

Same rules as always: one session at a time, headless checks, smoke test, focused tests, the
play-test bot careful and careless, a check for every new thing, PROGRESS.md, commit. Run the game
on the Mac and screenshot every spot you change. Before each session write a short plan and use
parallel agents where files don't overlap.

### Session 86: Loading screen

```text
Session 86. Make a real loading screen. 1) Split the world build (WahatBuilder and
everything it calls) into named steps: ground, roads, clusters, Plaza, venues, spine, edges,
people, traffic, and so on. Build a few steps per frame instead of all at once, and report
"step X of N" to the screen. 2) The screen: the start-screen desert (sun, dunes, one palm),
a small 3D bike that rides along the bottom edge as the bar fills, a progress bar with the
step name under it ("Laying the roads..."), and a tip that changes every 3 s (controls,
facts about Al Sarab, Snackaroo jokes). Minimum 1 s on screen, fade out when done. 3) Show
it at game start, on New game/Continue, and at the start of every shift (shorter). 4) Nothing
from the world shows until the last step is built and textures are ready (warm the shaders:
draw one frame hidden). Test: the smoke test checks the steps run in order and the screen
closes.
```

Done when:

- [ ] A moving bar with step names, a riding bike and tips, no frozen frame, no half-built world

### Session 87: Crash physics and the three crash levels

```text
Session 87. 1) Three crash levels in CrashImpact and game_config.gd: bump (speed under
CRASH_BUMP_KMH 12, or soft things like hedges and bins at any speed: the bike wobbles, you
stay on, 10 Dh repair, small rating hit, a short "Bump! 9 km/h" toast), fall (12 to 22 km/h:
you fall off, 30 Dh, food damage as now), big (over 22 km/h into hard things: hospital, the
clinic screen, 150 Dh). The message always shows the real speed at impact. 2) Replace the
falling animation with a ragdoll: physical bones on the rider (about 8: head, chest, hips,
upper and lower arms as one each, upper and lower legs as one each), the bike becomes a
RigidBody3D that slides and tips over, the rider tumbles with the real speed, lies still,
then gets up (blend back from ragdoll to the standing pose over 0.5 s) and walks to the bike.
Camera follows the body, not the bike, while down. 3) Tune so a small bump at walking speed
never throws you. Keep the 2 s grace time. 4) Update the PRD crash section. Tests: the crash
impact test gets the three levels; the careless bot still finishes a shift.
```

Done when:

- [ ] Bumps don't knock you off, falls look like a real tumble, and the toast shows the real speed
- [ ] Three different bills, all in game_config.gd

### Session 88: Three companies and their logos

```text
Session 88. 1) Logos: one drawn logo per company (vector made by a script in tools/logos/,
exported as PNG at 1024 and 256): Snackaroo (orange rounded bag with a lightning bolt, bubbly
font), Zoomaroo (green speech bubble with a wink), Deliverooz (teal kangaroo-ish shape, no
real logo copied). Also an Arabic word mark under each. 2) The application form offers the
three companies as cards with logo, colour and perk. The choice is saved and sets the box
colour and logo, the shirt, the phone app's name and colour, the start-screen app, and the
Snackaroo signs on buildings/vans where the company is shown. 3) Perks: Snackaroo +10% tips,
Zoomaroo customers wait 20% longer before cancelling, Deliverooz box is bigger and food damage
is 25% lower. All numbers in game_config.gd. 4) Switch company later in the phone's Company
app for 50 Dh (keeps your stars and level). 5) Old saves default to Snackaroo. Tests: an order
from each company, the perk numbers, the logo on the box.
```

Done when:

- [ ] You pick a company at the start and see its logo on your box, shirt and phone
- [ ] Each perk works and you can switch in the phone

### Session 89: The phone app

```text
Session 89. First make a mock-up (one HTML page in docs/phone_mockup.html with every screen)
and show Louis; build only after he says yes. Then: P opens a full phone in the middle of the
screen (the game pauses). Home screen with app icons: Jobs (choose which order types you want
offered next: normal, fragile, VIP, far; and see today's shift goals), Profile (name, company,
stars, Rider Level with the XP bar and "X XP to level N", career tier and what the next tier
needs, lifetime stats), Collection (bikes, looks, gear owned and locked), Messages (chats with
the regulars and DJ Salad; unread badge on the icon), Company (switch), Map (the full map from
M), Settings (the settings panel). Esc or P closes. The small corner phone stays for orders.
On phones a HUD button opens it. Tests: every app opens and closes; the unread badge works.
```

Done when:

- [ ] Louis approved the mock-up, and every app on the phone works

### Session 90: Plaza and gym fixes

```text
Session 90. 1) Extend the Plaza paving on the Dune Drip side only: from the shops past the
buggy park and along the road almost to the roundabout, so the walk from the roundabout is
paved; the other side of the road stays grass. No overlapping surfaces. 2) The buggy park is 3
times bigger (about 15 spaces) and sits behind Dune Drip. 3) The homes above the restaurants:
make them look like the house kit (windows with frames, trim, roof edge, AC units, plants on
balconies) and close the gap between them and the restaurant fronts. 4) Every bench outside the
restaurants faces outwards. 5) The pizza oven's flue connects to the oven. 6) The waiter
outside each restaurant does something: wipes a table, carries plates in and out, chats to a
diner, or goes inside; never just stands. 7) Gym: 15% smaller so it clears the road, a second
entrance on the spine side, and the same outside treatment as the restaurants (glass front,
colour band, sign, plants). 8) Majlis Gardens: the last path piece joins the road edge
smoothly with a crossing, no overlap. Screenshots of every spot.
```

Done when:

- [ ] Paving reaches almost to the roundabout on one side, the buggy park is 3x and behind Dune Drip
- [ ] Nothing in the Plaza overlaps, benches face out, waiters move, the gym clears the road

### Session 91: C Institute inside and out, and the pond

```text
Session 91. 1) Second floor inside: a balcony round the lobby, glass-walled offices with
people at desks on laptops, a meeting room with a screen and 6 people, plants, stairs and a
lift (press E, doors close, you come out upstairs). The talk screen stays. 2) Outside: keep the
big glass but go more modern: slim white frames, a flat roof with a sun shade, vertical fins
on the sunny side, a lit sign. 3) Where the stream ends near the C Institute, add a big pond
with stones round the edge, reeds, a small wooden deck with two benches and ducks. 4) Make
sure nothing overlaps the football pitch or the road.
```

Done when:

- [ ] You can go upstairs in the C Institute and see people working
- [ ] The pond looks right from the road and the Institute steps

### Session 92: People fixes and the player's look

```text
Session 92. 1) New stroller model in Blender (tools/blender/make_stroller.py): hood, frame,
four wheels that turn, a child inside. The parent holds the handle with both hands and pushes
it (the stroller is attached to the hands, not sliding on its own). 2) Talking pairs: replace
the mid-step idle pose with a relaxed standing pose (feet under hips), face each other at a
polite distance, and take turns speaking so it doesn't look like a fight. 3) Sunbeds at the
community pool: 4 people lying on them in swimwear, one reading. 4) Joggers' and runners'
trousers and shirts: fix the stretching when the legs swing (check with the outfits test at
run speed). 5) Construction workers: carry things, hammer, use the mixer, talk by the crane;
clothes fixed. 6) The player: rounder shoes with laces and soles, a cap or helmet with the
company logo, a company shirt, and the box with the logo. 7) Check every NPC on screen at the
courts for the flicker Louis saw (probably two meshes at the same place).
```

Done when:

- [ ] Strollers look real and are pushed, pairs look like they're chatting, sunbeds are used
- [ ] No stretching clothes on runners, workers work, the player looks better

### Session 93: Landscape

```text
Session 93. 1) Small hills, about 0.5 m high, in the empty areas only (between clusters and
the ring road, round the park, past the school) with a test that no hill touches a road,
building, path, pitch, pool or car park. 2) Bushes with more shape: rounded clumps of 3 to 5
spheres with leaf texture and a few flowers, not one green cube. Trees get a slightly
better trunk and 2 to 3 canopy layers; keep them cheap. 3) A faint Dubai-style skyline far
behind the Plaza only: flat silhouettes with one very tall spire, hazy, made-up shapes.
4) Crane: a real texture (rust, yellow paint, warning stripes) and a hook that moves slowly.
5) Police sign: fix the back face (it's see-through or z-fights from behind). 6) Community
pool: a fence all round with a gate, and a paved path from the red track to the gate.
```

Done when:

- [ ] Gentle hills in empty ground only, better bushes and trees, a faint skyline from the Plaza
- [ ] The police sign looks right from behind, the pool has a gate and path

### Session 94: The flea market

```text
Session 94. On about every third Friday (game calendar; the phone's Messages app tells you
the day before) the Plaza hosts a flea market: 8 stalls with canopies (old books, carpets and
lamps, spices, dates, toys, phone cases, a tea stand, a falafel stand), stallholders, 20 extra
people browsing, bunting and music. During it, 3 one-off orders come from the stalls (pickup
at a stall, deliver to a home) with a 50% tip bonus. Stalls pack up at the end of the shift.
Everything keeps clear of the restaurant doors and the paths. Test: force a market day and
make a stall delivery.
```

Done when:

- [ ] A market appears on market Fridays, with orders from the stalls

### Session 95: The mansion and DJ Salad

```text
Session 95. 1) The plot: by Cluster 5, from its car park to the road, walled with a gate and
a "For sale · للبيع" sign with a made-up agency and "25,000 Dh". 2) The house: Arab-modern in
the same style as the villas but big: white render, a tall pointed entrance arch with a
geometric mashrabiya screen, the upper floor as a floating box with sandstone and vertical
fins, flat roof, a courtyard pool with loungers, palms, a double garage, lights in the arches
at night. Inside: a big majlis, kitchen, a DJ corner with decks and speakers, stairs, two
bedrooms upstairs, a roof terrace. Made with the house kit plus Blender pieces. 3) DJ Salad:
a bit overweight (wider body, round belly), headphones round his neck, sunglasses, a bright
shirt, gold chain; he hangs around the pool or his decks, and his music (a free chill track)
plays faintly from the house. He takes deliveries from day one as a regular customer with his
own lines ("Habibi, the beats don't drop without my shawarma"). 4) The house appears on the
map and full map.
```

Done when:

- [ ] The mansion stands by Cluster 5 with its sign, and DJ Salad orders from you

### Session 96: Buying the mansion

```text
Session 96. 1) At Tier 3 (Snackaroo Pro) a Messages chat with DJ Salad unlocks: you can ask
"Is the house for sale?" He replies with 3 tasks, shown as a checklist in the chat: deliver 10
orders to him with 5 stars; bring him a special package from the bee farm (a one-off order
that appears once you ask); once you're a taxi driver, a timed airport pickup for him (until
Tier 4 exists, a timed delivery across the whole map). 2) When all three are done he offers the
house for 25,000 Dh; buying it takes the money, removes the sign, and DJ Salad moves out (he
becomes a regular who lives in Cluster 5 and still orders). 3) Owning it: you start every
shift at the mansion, you can walk in and up to the roof, the garage shows your owned bikes,
and the Profile app shows "Home: the mansion". Everything is saved. Tests: the task checklist,
the purchase, the new start spot.
```

Done when:

- [ ] You can message DJ Salad at Tier 3, do his tasks, buy the house and start there

### Session 97: Play-test the life pass

```text
Session 97. Run the smoke test, every focused suite and the play-test bot careful and
careless. On the Mac: screenshots of the loading screen, a bump, a fall and a big crash, each
company's logo on the box, every phone app, the Plaza paving, the gym, the C Institute upstairs
and the pond, a stroller, a talking pair, the sunbeds, the hills and skyline, the flea market,
the mansion by day and night, and DJ Salad. Fix what's wrong, then hand over.
```

Done when:

- [ ] All tests pass and Louis has played a shift with everything above

