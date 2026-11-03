# Complete plan: implementation and acceptance ledger

Base: main ac47818 plus the verified clock and crash plan through808413b.

Completion requires code, automated checks, rendered evidence and the listed human/release gates. A passing narrow check does not close a whole session.

| Requirement | Status | Evidence needed |
| --- | --- | --- |
| 35 Real-size map, the new layout and the corrected AM/PM clock — The map is real size and laid out like the sketch, with nothing big left blank | Implemented and checked | Source + targeted check + visible acceptance |
| 35 Real-size map, the new layout and the corrected AM/PM clock — A shift lasts 10 active real minutes and the AM/PM clock advances one game minute per second | Verified clock, recheck integration | Source + targeted check + visible acceptance |
| 35 Real-size map, the new layout and the corrected AM/PM clock — You start in front of the bus station and a full delivery works | Implemented and checked | Source + targeted check + visible acceptance |
| 36 Joined rows of homes and the camera fix — Clusters look like the real ones from above: long joined rows with lanes between | Implemented and checked | Source + targeted check + visible acceptance |
| 36 Joined rows of homes and the camera fix — The camera never goes inside a house | Implemented and checked | Source + targeted check + visible acceptance |
| 36 Joined rows of homes and the camera fix — Still 60 fps on Medium with all 500 homes | Passed stationary samples; moving target open | Source + targeted check + visible acceptance |
| 37 Car parks with solar roofs, cars, buggies and buses — Every car park has solar roofs and sits between clusters | Implemented and checked | Source + targeted check + visible acceptance |
| 37 Car parks with solar roofs, cars, buggies and buses — Cars only on the ring road, buggies only inside, and the bus comes and goes | Implemented and checked | Source + targeted check + visible acceptance |
| 38 Horse track, run and cycle track, jumping arena and stables — Horses go round the edge on their own track, and you ride the blue track beside it | Implemented and checked | Source + targeted check + visible acceptance |
| 38 Horse track, run and cycle track, jumping arena and stables — The jumping arena has horses jumping | Implemented and checked | Source + targeted check + visible acceptance |
| 39 The Plaza, restaurant fronts, mosque, bus station and checkpoints — The Plaza feels like a real little town centre with 12 different shop fronts | Implemented; playtest open | Source + targeted check + visible acceptance |
| 39 The Plaza, restaurant fronts, mosque, bus station and checkpoints — Mosque, bus station and checkpoints look right, and the guard waves | Implemented; playtest open | Source + targeted check + visible acceptance |
| 40 Restaurant insides and the side-panel style — Every restaurant has its own inside, and no two look the same | Implemented; playtest open | Source + targeted check + visible acceptance |
| 40 Restaurant insides and the side-panel style — Picking up at the counter works and the side panel shows the order | Implemented and checked | Source + targeted check + visible acceptance |
| 41 Fair Grade International School and the C Institute — You can spot the school from across the map, and it looks like Louis's photos | Awaiting human / release | Source + targeted check + visible acceptance |
| 41 Fair Grade International School and the C Institute — The C Institute faces the spine, and you can walk in and hand food to the receptionist | Implemented and checked | Source + targeted check + visible acceptance |
| 42 The green spine: hills, grass, domes path, gym and pools — The spine looks green and alive, with little hills and no big gaps between domes | Implemented and checked | Source + targeted check + visible acceptance |
| 42 The green spine: hills, grass, domes path, gym and pools — The gym, lap pool and community pool are there, and the dome doors look right | Implemented; playtest open | Source + targeted check + visible acceptance |
| 43 Textures, details and building sites everywhere — No big blank or plain areas anywhere on the map | Implemented and checked | Source + targeted check + visible acceptance |
| 43 Textures, details and building sites everywhere — Textures and props make it feel like a real place, still 60 fps on Medium | Passed stationary samples; moving target open | Source + targeted check + visible acceptance |
| 44 Speed feel and fixes — Riding and sprinting feel fast, with no warpy smear | Implemented and checked | Source + targeted check + visible acceptance |
| 44 Speed feel and fixes — Everyone has a head | Implemented and checked | Source + targeted check + visible acceptance |
| 44A Rider falls and crash presentation (planned) — A soft/slow hit, a glancing scrape and a hard frontal collision have visibly different falls | Implemented and checked | Source + targeted check + visible acceptance |
| 44A Rider falls and crash presentation (planned) — Direction and intensity reflect the captured impact, with readable camera framing | Implemented and checked | Source + targeted check + visible acceptance |
| 44A Rider falls and crash presentation (planned) — A major crash shows the fall before the hospital; a minor fall returns control safely | Implemented and checked | Source + targeted check + visible acceptance |
| 44A Rider falls and crash presentation (planned) — Secondary bounce contacts cannot repeat crash counts, cancellation or consequences | Implemented and checked | Source + targeted check + visible acceptance |
| 44A Rider falls and crash presentation (planned) — Louis watches the reactions at normal speed and likes how they look and feel | Awaiting human / release | Source + targeted check + visible acceptance |
| 44B Impact-based crash bills and insurance (planned) — Representative low/medium/high impacts produce distinct, explainable bills | Implemented and checked | Source + targeted check + visible acceptance |
| 44B Impact-based crash bills and insurance (planned) — Head-on versus glancing and soft versus hard obstacle cases follow the intended severity order | Implemented and checked | Source + targeted check + visible acceptance |
| 44B Impact-based crash bills and insurance (planned) — First-crash cover and insurance work, including different capped insured payments by severity | Implemented and checked | Source + targeted check + visible acceptance |
| 44B Impact-based crash bills and insurance (planned) — One fall creates one bill, one crash count and at most one cancelled order | Implemented and checked | Source + targeted check + visible acceptance |
| 44B Impact-based crash bills and insurance (planned) — Tests verify severity boundaries and billing; a playtest checks the costs feel proportionate | Implemented and checked | Source + targeted check + visible acceptance |
| 45 Pedal Point Bikes (upgrades, cart and checkout, rocket booster) — The bike shop looks like the mockup, and you see your bike while you shop | Implemented; playtest open | Source + targeted check + visible acceptance |
| 45 Pedal Point Bikes (upgrades, cart and checkout, rocket booster) — Cart and checkout work, and every upgrade does what it says | Implemented and checked | Source + targeted check + visible acceptance |
| 45 Pedal Point Bikes (upgrades, cart and checkout, rocket booster) — The rocket booster is crazy fast and only for late game | Implemented and checked | Source + targeted check + visible acceptance |
| 46 Dune Drip clothes shop, then play-test the detail pass — Trying on clothes feels like a real game shop, and what you buy shows everywhere | Implemented; playtest open | Source + targeted check + visible acceptance |
| 46 Dune Drip clothes shop, then play-test the detail pass — A careful ten-minute shift feels busy and pays for the first upgrade in about one shift | Implemented; playtest open | Source + targeted check + visible acceptance |
| 46 Dune Drip clothes shop, then play-test the detail pass — Louis has played a full shift and is happy with it | Awaiting human / release | Source + targeted check + visible acceptance |
| 47 Streaks, personal bests and PERFECT! — A streak makes you ride more carefully, and losing it stings a little | Implemented; playtest open | Source + targeted check + visible acceptance |
| 47 Streaks, personal bests and PERFECT! — A perfect delivery and a new best feel good | Implemented; playtest open | Source + targeted check + visible acceptance |
| 48 Choosing orders — Choosing between two orders is a real decision | Implemented and checked | Source + targeted check + visible acceptance |
| 48 Choosing orders — A high rating feels worth having | Implemented; playtest open | Source + targeted check + visible acceptance |
| 49 Tomorrow's special — Shifts feel different from each other | Implemented and checked | Source + targeted check + visible acceptance |
| 49 Tomorrow's special — Seeing tomorrow's special makes you want one more shift | Implemented; playtest open | Source + targeted check + visible acceptance |
| 50 Collections, regulars and the profile page — You can see how much of Wahat Al Shams you've collected | Implemented and checked | Source + targeted check + visible acceptance |
| 50 Collections, regulars and the profile page — The regulars feel like they know you | Implemented and checked | Source + targeted check + visible acceptance |
| 51 Final play-test, then itch.io — A friend plays for 10 minutes and wants to keep going | Awaiting human / release | Source + targeted check + visible acceptance |
| 51 Final play-test, then itch.io — It's on itch.io | Awaiting human / release | Source + targeted check + visible acceptance |

## Cross-cutting invariants

- Clock: one active real second = one game minute; 08:00–18:00 = 600 active seconds.
- 500 unique home IDs, 100 per cluster, plus four special venues; legacy IDs stay stable.
- Counter pickup requires a clear indoor walking target; bike parking has a separate approach.
- 60 fps at Medium/1920×1080 on the Mac is a rendered gate, never inferred from headless checks.
- One accident and one bill; show the fall before the clinic; preserve insurance, first-crash and rocket rules.
- Validation snapshots redirect every user:// script path and the engine log into /private/tmp.
- No diagnostic banners in ordinary gameplay.
- Mac/Windows exports and itch.io release remain open until actual artifacts and hosting are verified.

## Execution log

- Created codex/detail-pass-complete worktree at 808413b, preserving the corrected clock branch. Latest main verified ac47818; no open PRs at that check.
- Removed all clock-check banner construction from the temporary live-clock harness; the ordinary source never contained it. Opened and visually verified the clean playable demo.
- Implemented 940×500 m data, 500 joined homes plus four venues, separate approach/entrance/counter APIs, ten distinct walk-in restaurants, both shops, school/institute/gym/pools, terrain/detail/traffic/rails/arena, crash sequences and replay/progression modules. The final verification below records the tested implementation and remaining human acceptance gates.
- Focused agent checks: housing/camera pass; shops35 pass; crash/traffic/wind pass; replay42 pass; replay UI13 pass; navigation9 pass. These are scoped results, not proof of the entire plan.
- Full built-world check at /private/tmp/habibi-full-latest/world-final.log:27/27 pass, including all504 approach/door targets clear and reachable, every pickup counter walk-in route, 20 near/far row meshes and clock/speed invariants. Includes construction-road/parking, cross-row alley, static-batch, next-shift rider and existing-clinic outfit guards. Comfy-tyre camera response also passes three observable checks in gear.log.
- Fixed three construction-site footprint conflicts, inserted central cross-row alleys, moved Plaza–C1 road clear of homes, moved buggy routes off mini-plaza obstacles and flattened the spine's main path through hills. School visual review also fixed playground/pool overlaps and swimmer height.
- Rendered twelve world viewpoints at /private/tmp/habibi-full-check-next. Review led to transparent glass, warm counter lighting, visible menu/sign boards, outside seats, bowed school wings, rounded gym rear, spine planting, correctly seated visitors and kitchen motion. Fresh images still required after these changes.
- Initial performance samples were below target despite static batching saving 3,622 submissions. Profiling found mini-map rebuilding cost 5–6 ms per frame. The final foreground samples below use cached rendering and the original resolution.
- Clean Palm Grove/test-area smoke pass; Wahat smoke caught geometry and stale fixture contracts, being rerun. Careful full-shift bot is running; subsequent careless/five-shift balance and repeated smoke gates remain open.
- Official Godot4.7.2 export templates are downloaded and SHA256 verified in /private/tmp/habibi-export-sdk; independent Mac/Windows preset probes exported successfully, actual game exports remain held. No publishing. Louis/friend normal-speed acceptance remains a human gate.
- Fresh whole-branch review found next-shift actor desync, stale clinic outfit and missing tyre hill comfort. All three fixes were scoped-reviewed and their behavior checks pass. GPS sampling was raised above the hills and ignores moving actors; navigation11 focused checks pass. No unresolved P1 finding in that code review.

## Final verification evidence

- GitHub main rechecked at ac47818f648ad98f901ae5caa79ecd2988731b30 after implementation.
- All 12 focused suites passed on an isolated Git archive of fa770a4, including all 39 crash checks, 38 traffic checks and 27 world checks. The runtime fingerprint before save-path redirection matches the desktop distribution manifest. Verification import and all suites exited cleanly with no script or resource errors. The cold import logged font/theme diagnostics while building its cache. Evidence: /private/tmp/habibi-focused-final-m7xc12yu/focused-results.json.
- Wahat smoke: five runs of416 checks; Palm Grove309; test area275. Total2664. Clean repeat logs: /private/tmp/habibi-replay-check-9b1qxx9c/. After the final west-side scenery patch, the exact-source world check passed27 and Wahat smoke passed416 again; logs /private/tmp/habibi-final-checks/site-final.log and /private/tmp/habibi-replay-exact-final/wahat-smoke-84m.log.
- Focused native 1920×1080 Medium / Forward+ Metal (Apple M3): bus87.5 fps (p95 15.11ms), cluster97.5 fps (13.34ms), spine83.5 fps (16.64ms). Each 10 seconds after a 5-second warmup, foreground focus throughout. Stationary views before the final off-camera west-side scenery patch; rare p99 spikes20–25ms. /private/tmp/habibi-performance-validation/focused-results.json
- Pre-batching native 1920×1080 Medium / Forward+ Metal (Apple M3), 90 seconds after a 5-second warmup, foreground focus throughout: 56.0 fps overall (p95 28.0ms), 55.9 fps mounted, and 56.3 fps on foot. The careful test rider covered 464 m and picked up the order before the sample ended en route. The editor runtime and automated rider limit what this proves about the shipping runtime. The first release probe lost focus and was excluded. Evidence: /var/folders/4y/_yv4hds908d_n8013jncngmm0000gn/T/habibi-final-moving-9qzz22fu/native.log.
- Batched each moving palm crown from 11 mesh surfaces to three while retaining the sway pivot and the three original materials. Geometry comparison matched every sampled vertex and colour and found a maximum normal difference below 0.0001. In the paired Mac release probe, three valid 16-second foreground passes covered roughly 124 m of the spine at 28 km/h. The original pass averaged 39.2 FPS and 2,422 draw calls per frame. The batched passes averaged 36.3 and 50.5 FPS with 1,790 and 1,656 draw calls. The shift lighting advanced between passes. These samples show fewer draw calls with variable FPS, and a fourth pass and graphics tuning retries lost focus. Evidence: /private/tmp/habibi-final-native-route/crown-pair-results.json and the matching fixed-input CSV files. Geometry check: /private/tmp/habibi-palm-check/crown-geometry.log.
- Mini-map drawing fell about98%; cached world chunks preserve rotation/addresses/GPS. Repeated phone style/theme invalidations went from72 over8 unchanged frames to0. Static batching preserves colliders and colours.
- Five careful shifts net110/141/98/140/156 Dh, 645 total, 538 XP, 27 deliveries, Level6; GPS50 after first shift. One boss-covered major crash and one small crash across five shifts; zero stuck resets/backups. Fresh careless shift:5 deliveries,126 Dh,100 XP,2 small crashes, no major crash or reset. See /private/tmp/habibi-careless-final-rsupxld2/verification-report.md. The bot now prints only the current shift's job rows; recorded structured results were already correct.
- Actual cart replay buys first aluminium frame on shift5. Fixed-income extrapolation reaches rocket on shift94, not an observed 94-shift playtest. Retained specified 10,000 Dh price for human pacing review.
- Both desktop builds use runtime fingerprint 10de3bad0932f8adee431eba00e7dbee9b32773c4f3866e6d583573b0babba5e. Review and portable ZIPs are in /private/tmp/habibi-desktop-review-final-v3-corrected/artifacts and /private/tmp/habibi-desktop-distribution-final-v3-corrected/artifacts. ZIP CRC/SHA256, Mac universal architecture/ad-hoc signature and Windows x64 PE checks pass. Mac menu and separately packaged Wahat QA entry both launch cleanly. Windows runtime is unverified. Nothing uploaded or published.

The final gameplay capture shows 8:02 AM after two active seconds and no diagnostic banner. The overhead view was refreshed after fencing the last large unused patch west of the Institute; all roads and delivery targets remain clear.

In the packaged Mac review app, Continue loaded the isolated Shift 2 demo save into Wahat. The normal HUD showed 8:05 AM and a Bread & Zaatar delivery offer for Villa 100 in Cluster 3, with no clock diagnostic banner.

After palm batching, the geometry comparison, static batching suite, 27 world checks and all 416 Wahat smoke checks passed, including palm sway. The paired desktop rebuilds at /private/tmp/habibi-palm-check/review and /private/tmp/habibi-palm-check/distribution use runtime fingerprint e16ed943ed029cda8794ff85d12b32af5a43d4f055da1838c207995912d4bf01. ZIP integrity, checksums, Mac signatures, Windows executable headers, and the Mac menu and packaged Wahat headless launch passed. Verification logs are under /private/tmp/habibi-palm-check.

## Remaining acceptance

- Establish at least 60 FPS during representative moving gameplay at Medium. Repeat the Mac release probe with sustained foreground focus and the full HUD.
- Louis can use Continue in the Mac review app for a ten-minute active shift. Record whether the shift feels busy enough and whether he would play another. Review the soft hit, glancing scrape and hard frontal fall at normal speed, including the transition to the clinic and whether the resulting bills feel proportionate. Compare the school against Louis's photos.
- Give the friend the portable build to try from New Game. After ten minutes, record whether they want to keep playing and where they hesitated or stopped.
- On a native Windows x64 machine, extract the portable ZIP, launch the executable, start a shift and verify movement and a pickup and delivery. The archive and executable structure have already been checked on Mac.
- Record the itch.io project URL and publishing approval, upload both platform builds, then verify the downloads from the published page.
