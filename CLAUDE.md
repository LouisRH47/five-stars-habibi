# Five Stars Habibi

A 3D job-sim driving game made in Godot 4 with GDScript. You start as a bicycle food
delivery rider in a villa community in Al Sarab (a made-up, Dubai-style desert city) and
climb a career ladder up to luxury chauffeur. Full design: GAME_DESIGN.md.
Build steps: BUILD_PLAN.md. What's done so far: PROGRESS.md.

## Who you're working with
- Louis is a total beginner. He doesn't write code himself.
- Explain things in short, simple words. No jargon without a one-line explanation.
- After every change, tell him exactly how to test it in Godot (which scene to open,
  press F5 or F6, which keys to press, what he should see).

## How to work
- Only build the current session from BUILD_PLAN.md. Don't jump ahead.
- Small steps. Get one thing working before adding the next.
- Before handing over, run Godot headless to catch script errors:
  /Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
- At the end of every session: update PROGRESS.md (what works, what's next,
  known bugs) and make a git commit with a clear message. Louis pushes to GitHub
  with GitHub Desktop (or ask him if he wants you to push).

## Tech rules
- Godot 4, GDScript only (no C#, no .NET). 3D, Forward+ renderer.
- Folders: scenes/, scripts/, assets/, ui/. One script per job, keep scripts short.
- Put tuning numbers (speeds, pay, timers, prices) in one place:
  scripts/game_config.gd, so they're easy to change later.
- Graphics: simple low-poly. Use basic shapes or free CC0 assets (e.g. Kenney).
  Never paid or copyrighted assets.
- Never use real company names or logos. Use the made-up brands in GAME_DESIGN.md
  (Snackaroo, Dune Express, Yalla Cabs, Falcon Ride, Mirage Black).
- Currency is Dh (game dirhams).
- All game text (menus, phone, customers) is English only.
- Signs on buildings, shops and roads are bilingual: Arabic + English, like Dubai.
  Use a free Arabic font (e.g. Noto Sans Arabic) and check Arabic letters show
  connected and right-to-left, not as separate or backwards letters.
- Music: chill Arabic-style background music, only free-to-use tracks
  (CC0 or credited in a CREDITS.md file).
