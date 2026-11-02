# Progress

## Current session
Session 1: Project, bicycle and camera (built, waiting for Louis to test on his Mac)

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

## Known bugs
- None found yet. Not tested on a real screen yet.

## Next
- Louis tests Session 1 with its checklist in BUILD_PLAN.md.
- Then Session 2: bike feel and stamina.
