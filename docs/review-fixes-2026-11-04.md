# Implementation review fixes — 4 November 2026

The review found seven integration defects after the initial plan closeout. All
seven are corrected on `codex/plan-review-fixes`, based on the reviewed
`codex/detail-web-integration` commit `da974f5`. Feedback and the school-photo
comparison remain skipped; itch.io remains on hold. This branch has not been
deployed.

| Finding | Corrected behavior | Regression coverage |
| --- | --- | --- |
| Tutorial stalls after a major crash | The next shift reoffers the unfinished tutorial. Completion timers from an earlier attempt cannot finish a restarted tutorial. | Offered, accepted and picked-up tutorial crashes; normal completion resumes the clock and order dispatch; stale timer guard. |
| Insurance changes a bill during a fall | The bike records coverage at impact and billing uses that recorded value. First-crash boss cover remains intact. | Both I-toggle directions during a real fall and the first-crash exception. |
| Buses deadlock on the station spur | One bus at a time uses the access road. Due arrivals wait until the road and entry are clear, then continue in order. | 125 active seconds of obstruction, queued arrivals reaching/leaving the bay, and no overlapping buses. |
| Streak goal ignores a minor crash | Goal progress uses each delivery's actual streak, capped to deliveries made this shift. | Crash breaks an unfinished run; an already-earned goal survives; yesterday's streak cannot complete today's goal. |
| No touch rocket control | Owning the rocket exposes a Boost button, with recharge time and unavailable-state handling. | Actual scaled touch input fires the production bike; four viewport layouts; pause, focus and rotation release input. |
| Stamina bar caps at 100 after upgrades | HUD maximum follows the bike's current stamina capacity. | Capacity changes immediately; 150/200 displays 75%, not full. |
| Reception instructions remain above result screens | Stage changes close the panel immediately; paused modal cleanup runs, with restoration only for an active handoff. | Institute and gym handoffs, Pause, Profile, delivery results, shift summary and next shift. |

## Verification

Each regression was demonstrated on the original source before its fix. The new
lifecycle suite failed 11 checks, the streak test one, the bus suite five, touch
six, stamina three, and reception ten. The corrected checks pass.

The combined release pipeline passed on an isolated snapshot of the final runtime:

- Wahat smoke: **432** assertions.
- Touch: **61** assertions, including four iPad viewport sizes.
- Fifteen focused suites: **392** assertions, including lifecycle 38, bus recovery
  7, reception 20, replay 48, gear/HUD 7, crash 43 and traffic 39.
- Additional smoke runs: Palm Grove **309**, test area **275**.
- Total: **1,469 Godot assertions**, **7 packaging tests**, **5 worker tests**.
- Strict import, startup and Web export completed. Native headless logs contain
  the previously identified macOS certificate-store diagnostic, with no script
  errors.

The build now runs all 15 focused suites before exporting, rather than depending
only on smoke and touch checks. The validation helper supports both macOS and Linux
temporary directories and excludes generated build/SDK directories from its copy.

Combined logs: `/private/tmp/habibi-plan-fixes-final/`. Individual before/after
evidence: `/private/tmp/habibi-lifecycle-fix-before` and `-after`,
`/private/tmp/habibi-bus-fix-baseline` and `-check`, and
`/private/tmp/habibi-ui-fixes-before` and `-after`. A separate unobstructed traffic
control ran 1,200 simulated seconds with continuing bus arrivals and departures.

A separate Web export from the unmodified runtime paths was rendered in an
isolated Chrome context. Normal application controls created a rider, E accepted
the tutorial, and the rider persisted through save/reload. Only that test save
was then seeded with tutorial completion, late-game XP/money, rocket ownership
and ten stamina upgrades. In a 1024×768 touch-enabled context, a normal tap on
**Boost** changed its label to **Boosting**, showed rocket flames and reached
**80 km/h**. The browser recorded zero errors. Screenshots and the exact test-save
changes are in `/private/tmp/habibi-plan-fixes-browser/results.json` and the PNGs
beside it. This checks browser rendering and input, not physical iPad performance.

## Checking it in Godot

Use Godot 4.7.2 and this branch. To keep ordinary player progress separate, create
an isolated copy first:

```sh
python3 tools/prepare_validation.py /private/tmp/habibi-review-fixes-demo
```

Import `/private/tmp/habibi-review-fixes-demo/project/project.godot` in Godot and
press **F5**. Create a rider, accept the tutorial, and collide with a wall at speed.
After the fall, select **Shift summary**, then **Start next shift**. A fresh pizza
tutorial offer should appear. Completing it should start the normal clock and orders.

On a touch device, an owned rocket adds **Boost** above the left steering controls.
Tap it to fire; its label shows recharge seconds afterward. Purchasing stamina
capacity changes the stamina bar's scale immediately. At the institute or gym,
holding E to finish a handoff removes the reception instructions before the result
card appears. Pause or Profile also hides those instructions until riding resumes.

For the complete automated verification, run the local build command from
[WEB_RELEASE.md](WEB_RELEASE.md). The regression suites supply controlled states
for late-game upgrades and crash coverage, without requiring a long playthrough.
