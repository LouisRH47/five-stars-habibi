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

## The sessions (Tier 1)

Tier 1 is split into 14 sessions of about 1 hour each, so at 1 to 3 hours a week it takes roughly 5 to 14 weeks. Do them in order. Start each one with `/clear`, then paste the prompt.

### Session 1: Project, bicycle and camera

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

### Session 2: Bike feel and stamina

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

### Session 3: Palm Grove map

```text
Session 3. Build the Palm Grove villa community from PRD.md (City map
section): roads, a roundabout, 25 to 40 villas with big readable house numbers,
a restaurant strip at the entrance with 3 restaurants (Pizza, Brain Freeze
Gelato, Boba Oasis), a park, a small supermarket, palm trees. All signs
(restaurants, shops, street names) show Arabic and English, like in Dubai.
Low-poly shapes or free CC0 assets. Put the bicycle at the entrance.
```

Done when:

- [ ] You can ride around the whole community
- [ ] Every villa has a number you can read while riding
- [ ] The 3 restaurants are easy to spot
- [ ] Arabic on signs shows joined up and right-to-left

### Session 4: Obstacles

```text
Session 4. Add obstacles to Palm Grove: speed bumps that make the bike bounce,
parked cars, a few cats that wander slowly, and kids on scooters riding
simple routes. The bike should collide with all of them.
```

Done when:

- [ ] Speed bumps give a noticeable bump
- [ ] Cats and kids move around and you can bump into them

### Session 5: Phone and orders

```text
Session 5. Add the phone UI and order system from PRD.md (Delivery
loop). An order pops up on a phone in the corner showing restaurant, villa
number, food type and pay. Press E to accept or Q to skip. Ride to the
restaurant marker, press E to pick up, ride to the villa marker, press E to
deliver, get paid. One order at a time. No meters yet.
```

Done when:

- [ ] Orders pop up, and you can accept or skip
- [ ] Pickup and drop-off work, and money goes up after delivering

### Session 6: Mini-map and addresses

```text
Session 6. Add a mini-map in the bottom-left corner showing the roads, the
player, and a marker for the next stop with the villa number. Some orders
should have a short note like "leave it at the door". No GPS line on the road
(that's a later upgrade).
```

Done when:

- [ ] The mini-map turns with you and shows the next stop
- [ ] You can find any villa using just the mini-map and house numbers

### Session 7: Customers at the door

```text
Session 7. When you deliver, a simple customer character comes out of the
villa with a short animation and says one line in a speech bubble (make
15+ different funny lines). Some orders say "leave it at the door" and nobody
comes out.
```

Done when:

- [ ] Customers come out and say different lines
- [ ] Leave-at-the-door orders work

### Session 8: The three meters

```text
Session 8. Add the time, heat and damage meters from PRD.md (Delivery
loop). They show on screen during a delivery. Food types: pizza (easy),
ice cream (melts fast), bubble tea (spills on bumps). Heat drains over time,
damage goes up on bumps, hard braking and collisions.
```

Done when:

- [ ] All three meters show and change while riding
- [ ] Ice cream melts faster than pizza, and bubble tea hates speed bumps

### Session 9: Stars, money, tips and XP

```text
Session 9. At the end of each delivery, give 1 to 5 stars based on the meters.
Add pay per delivery (8 to 15 Dh), random tips only on 5-star jobs (40% chance,
2 to 15 Dh), an XP bar, and a star rating that averages the last 50
deliveries. Show wallet, rating and XP on screen.
```

Done when:

- [ ] A clean delivery gets 5 stars, a messy one gets fewer
- [ ] Tips sometimes appear on 5-star jobs, never on lower ones
- [ ] Wallet, rating and XP update correctly

### Session 10: Crashes and insurance

```text
Session 10. Add crashes from PRD.md (Crashes, bills and insurance).
Small crash: rider falls off, damage meter jumps, back on after 2 seconds.
Big crash (hitting a car/wall/pole above about 20 km/h): fade out, clinic
screen, order cancelled, hospital bill 150 Dh + repair bill 80 Dh, shift ends.
Add an insurance on/off toggle (2 Dh per delivery). With insurance, a big crash
costs only 20 Dh.
```

Done when:

- [ ] Small and big crashes both happen at the right speeds
- [ ] Bills are right with and without insurance

### Session 11: Shifts

```text
Session 11. Add shifts: one shift is about 10 real minutes (one in-game day,
day shift only). Show the time of day. At the end, show a summary screen:
deliveries, average stars, money earned, tips, bills, XP.
```

Done when:

- [ ] The shift ends on time and the summary numbers are correct

### Session 12: Application and characters

```text
Session 12. Add the start of the game from PRD.md (Start of the game):
a phone-style Snackaroo rider application (name, where you're from), 3 character
presets to pick from, a "Reviewing..." spinner, then "Congrats, you're hired!".
The first order is an easy pizza two streets away that works as a tutorial
with short tips on screen.
```

Done when:

- [ ] You can fill in the form and pick a character
- [ ] Customers use your name
- [ ] The tutorial order explains the controls

### Session 13: Menu, saving, sound and music

```text
Session 13. Add a main menu (Play, Settings, Quit), save and load (money,
rating, XP, character, insurance setting), simple sound effects (bike, bell,
crash, cash), chill Arabic-style background music (free to use, listed in
CREDITS.md) and background ambience.
```

Done when:

- [ ] Closing and reopening the game keeps your progress
- [ ] The sounds and music work and aren't annoying

### Session 14: Play-test and tuning

```text
Session 14. I'm going to play-test. Help me tune the numbers in
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

Once Session 14 feels fun, upload it to itch.io for free so friends can play it and give feedback (ask Claude Code to export Mac and Windows versions). After that, the next block of sessions is the motorbike test (yard course, instructor, theory quiz), then the motorbike, Old Town, night shifts and running costs. Ask Claude Code to "write the Tier 2 sessions for BUILD_PLAN.md in the same style as Tier 1" so the plan keeps growing as you go.

## Confirmed choices

- Simple low-poly graphics, using basic shapes and free CC0 asset packs like Kenney
- Claude Code used through the Claude desktop app
- Keyboard controls for now (W A S D, Shift, Space, E, Q); controller support later
- Built on a paid Claude plan (Claude Code doesn't work on the free plan)
- About one 1-hour session a week
