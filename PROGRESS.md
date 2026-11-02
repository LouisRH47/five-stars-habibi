# Progress

## Current session
Session 2: Bike feel and stamina (built, waiting for Louis to test on his Mac).
Session 1 is built but also still needs testing on the Mac.

## What works
- Godot 4.7 project (Forward+), opens with `scenes/main.tscn` as the main scene.
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

## Known bugs
- None found yet. Not tested on a real screen yet.

## Next
- Louis tests Sessions 1 and 2 with their checklists in BUILD_PLAN.md.
- Then Session 3: Palm Grove map.
