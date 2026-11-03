# Five Stars Habibi

*Rider to Driver*

A 3D job-sim game made in Godot 4. Start as a bicycle food delivery rider in Al Sarab, a made-up Dubai-style city, and work your way up to motorbikes, taxis and a luxury chauffeur service.

Browser play: **https://fivestarshabibi.middleleap.com**

MacBook: keyboard controls. iPad: landscape touch controls (device testing needed).
See [browser testing and releases](docs/WEB_RELEASE.md) for deployment, named
releases, rollback, and local builds.

- `PRD.md`: the full game design (what the game is), with a decisions log. This is the one true copy
- `BUILD_PLAN.md`: step-by-step sessions for building it with Claude Code
- `CLAUDE.md`: rules Claude Code reads every session
- `PROGRESS.md`: what's done so far


The current build covers bicycle shifts in Wahat Al Shams. Later motorbike/taxi careers remain design only.

Open `project.godot` in Godot 4.7.2, import the assets, then run the project. One active real second is one game minute; the 8 AM–6 PM shift lasts ten active minutes.

| Control | Action |
| --- | --- |
| W/S, A/D | Pedal/brake and steer; walk and turn on foot |
| Shift / Space | Sprint / handbrake |
| F / E | Get off/on the bike / hold to pick up, deliver or shop |
| 1/2 / Q | Choose an offer / skip |
| B / I / P | Bell / insurance / profile |
| X | Fire an owned, charged rocket booster |
| R / Esc | Recover nearby / pause or leave a shop |

In a shop, W/S switches category, A/D previews items, E adds to the cart and C checks out. Drag to turn the 3D preview. Esc restores an unbought look.

For isolated checks, run `python3 tools/prepare_validation.py /private/tmp/habibi-check`, import that copied project, and run its `tests/smoke_test.gd`. The helper redirects player progress, settings and engine logs into the temporary folder. `tests/playtest_bot.gd -- shifts=5` exercises five consecutive shifts; add `careless` for a reckless run. See `docs/implementation-status.md` for exact evidence and remaining acceptance gates.
