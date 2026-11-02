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

### Session 10: Stars, money, tips and XP

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

### Session 11: Customers at the door

```text
Session 11. When you deliver, a simple customer character comes out of the
villa with a short animation and says one line in a speech bubble (make
15+ different funny lines). Some orders say "leave it at the door" and nobody
comes out.
```

Done when:

- [ ] Customers come out and say different lines
- [ ] Leave-at-the-door orders work

### Session 12: Crashes and insurance

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

### Session 13: Shifts

```text
Session 13. Add shifts: one shift is about 10 real minutes (one in-game day,
day shift only). Show the time of day. If the clock runs out mid-delivery, let
the player finish it. At the end, show a summary screen: deliveries, average
stars, money earned, tips, bills, XP.
```

Done when:

- [ ] The shift ends on time and the summary numbers are correct

### Session 14: Application and characters

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

### Session 15: Menu and saving

```text
Session 15. Add a main menu (Play, Settings, Quit) and a proper pause menu.
Save and load money, rating, delivery history, XP, character, name and the
insurance setting through the game state autoload.
```

Done when:

- [ ] Closing and reopening the game keeps your progress

### Session 16: Sound and music

```text
Session 16. Add simple sound effects (bike, bell, crash, cash), chill
Arabic-style background music (free to use, listed in CREDITS.md) and
background ambience (birds, distant traffic). Add a volume slider in Settings.
```

Done when:

- [ ] The sounds and music work and aren't annoying

### Session 17: Play-test and tuning

```text
Session 17. I'm going to play-test. Help me tune the numbers in
game_config.gd. Here's what felt off: [write what felt too easy, too hard,
too slow or too boring].
```

Done when:

- [ ] A friend plays for 10 minutes without needing help
- [ ] They want to keep playing

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

Once Session 17 feels fun, upload it to itch.io for free so friends can play it and give feedback (ask Claude Code to export Mac and Windows versions). After that, the next block of sessions is the motorbike test (yard course, instructor, theory quiz), then the motorbike, Old Town, night shifts and running costs. Ask Claude Code to "write the Tier 2 sessions for BUILD_PLAN.md in the same style as Tier 1" so the plan keeps growing as you go.

## Confirmed choices

- Simple low-poly graphics, using basic shapes and free CC0 asset packs like Kenney
- Claude Code used through the Claude desktop app
- Keyboard controls for now (W A S D, Shift, Space, E, Q); controller support later
- Built on a paid Claude plan (Claude Code doesn't work on the free plan)
- About one 1-hour session a week
