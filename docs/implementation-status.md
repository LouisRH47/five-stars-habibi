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

The stamina and delivery bars now emit style notifications only when their fill colours change. The isolated check went from 40 to zero stable-colour notifications across 10 updates of all four bars, with five expected colour transitions and values intact in both runs. The walking rider and clinic patient stop processing while hidden. Seven checks covered initial inactive state, repeated dismounting, remounting, and the patient animating during the paused clinic screen. All 416 Wahat smoke checks passed on this revision. Evidence: /private/tmp/habibi-style-check/style.log, animation-recheck.log and wahat-smoke.log, and /private/tmp/habibi-palm-check/style-baseline.log.

The current portable exports are at /private/tmp/habibi-ui-export-check/distribution. The archive CRCs, checksums, Mac signature and platform architectures passed and the source fingerprint matches adf37d10897156007614853daabbc39da35d4f8b9b3d89b955c8a0e6290ed547. The earlier review app and its launch evidence cover the palm revision.

The follow-up release profiler returned zero for GPU timings. A shorter-shadow sample recorded a median 312 shadow draw calls against 905 in the baseline segment, but focus loss and heavy background load made the frame times incomparable. Medium quality settings were retained. Evidence: /private/tmp/habibi-spine-profile/fixed-input-results.json and CSVs.

Dispatch now evaluates each door distance once per sort. In 162 paired seeded comparisons across Wahat, Palm Grove, the test area and an edited fixture, the orders and next random value matched. A forced fallback with 30 equally distant homes and two equivalent shops also matched. On Wahat, measured medians were 30.7 to 6.0 ms for ordinary generation, 64.6 to 10.1 ms for the short-ride path and 79.3 to 14.6 ms for better-offer generation. These are headless call timings on this Mac. Evidence: /private/tmp/habibi-dispatch-check/compare.log and fallback.log.

The stream now uses 12 short mesh chunks for its 68 original pieces. All 2,448 triangle corners matched within 0.00004 m, with normal error below 0.0001. Every chunk retained the world-space water shader and flow speed. Replay, replay UI and shared navigation/GPS suites passed on this revision. Evidence: /private/tmp/habibi-dispatch-check/stream.log and the focused suite logs.

All 416 Wahat smoke checks passed on the dispatch and stream revision. Current Mac and Windows archives at /private/tmp/habibi-dispatch-check/distribution match runtime fingerprint c87daee91b01019acae71114b544b7b5137e1a78c75a80eb74022fd5a7de4a89 and passed archive, checksum, architecture and Mac signature checks. The private Mac release comparison loaded Wahat with the native Metal renderer and built the district, but the desktop tool could not attach in time to start the foreground samples. Evidence: /private/tmp/habibi-dispatch-check/wahat.log, distribution/manifest.json and /private/tmp/habibi-spine-foreground/native.log.

The perimeter now uses 24 spatial batches each for trunks and crowns. The native release check matched all 714 transforms for each part at millimetre precision, mesh arrays, materials and shadow settings. On matched foreground views, the spine went from about 1.04 million to 0.57 million rendered primitives and the north ring from 1.00 million to 0.57 million. Total draw calls rose about 1–3%. Frame rates varied between repeated baselines, so those samples establish the geometry savings and leave moving FPS open. Evidence: /private/tmp/habibi-tree-native/native.log.

The fixed-camera shadow and upscaling probe lost focus during the run. Shorter shadows reduced shadow submissions at the same view, but the mixed-focus timing was inconclusive and Medium quality settings stayed unchanged. Evidence: /private/tmp/habibi-static-matched/native.log.

The tree-batch revision passed all 416 Wahat smoke checks. The current desktop archives at /private/tmp/habibi-tree-check/distribution match runtime fingerprint 8cbe72e5e6a33ff3827d2bacf815e9b8fc7499b5a7c0f583a05cc7e1915f45d9 and passed checksums, archive integrity, platform architecture and Mac signature checks.

The moving release probe sampled three 14-second routes at Medium, 1920×1080, with the normal HUD and an active order. All samples kept window focus, ran at 28 km/h, and had zero crashes. On the shared M3 Mac, averages were 36.3 FPS on the spine, 29.9 from plaza to C1, and 23.6 on the north ring. The p95 frame times were 52.5, 67.4 and 97.4 ms. The host had heavy background activity and memory pressure, and the run fell short of the 60 FPS target. Evidence: /private/tmp/habibi-tree-moving/fixed-input-results.json.

Wahat now uses a 64-pixel sky radiance texture on Low and Medium and the existing 256 on High. The two fully focused fixed-view pairs at Medium and 1080p with the clock active averaged 24.6 to 34.2 FPS and 29.1 to 31.0 FPS. The p95 improved in one pair and worsened in the other. A third pair lost focus. The three matched lighting captures showed no material visual change in the sampled sky, stream and nearby buildings. A focused settings check verified Low, Medium, High and back to Medium, with the original shadow distances and sky settings on the other maps. Evidence: /private/tmp/habibi-sky-native/native.log and /private/tmp/habibi-sky-check/quality.log.

All 416 Wahat smoke checks passed on the sky revision. The current portable archives at /private/tmp/habibi-sky-export-check/distribution match fingerprint ef5861d81ee1be168a0cf36bcb07bdfd3732b7002dda32c80180d1114396ce1c and passed integrity, architecture and Mac signature checks. The matched 14-second moving spine route averaged 52.5 FPS at Medium and 1080p with the 64-pixel setting active, 28 km/h throughout, no focus loss, and p95 frame time 31.5 ms. The plaza and north-ring samples lost focus during the combined run. A separate north-ring run reached 70.7 FPS with p95 18.5 ms, but never held focus and was excluded. Results: /private/tmp/habibi-sky-moving/three-route-results.json and north-native.log.

The shadow probe compared Medium's four cascades at 150 m with two cascades at 110 m on the same active-order spine segment. Shadow draw calls fell from about 820 to 430 per frame. Average FPS did not improve across either repeat, and focus was lost during the run. The current shadow settings were retained. Evidence: /private/tmp/habibi-shadow-moving/fixed-input-results.json and native.log.

Permanent staff and diners in walk-in venues now pause their animation beyond 85 m from the camera and resume within 70 m. Their models stay visible in their last pose. The focused check covered all 34 rigs, zero active from the spine view, a visible seated pose at distance, both sides of the hysteresis range, and resumed animation on approach. The shop suite and all 416 Wahat smoke checks passed. Evidence: /private/tmp/habibi-venue-check/venue-final.log, shop.log and wahat.log.

Four focused eight-second moving spine passes at Medium and 1080p averaged 60.0–60.1 FPS. The baseline passes kept all 34 venue rigs active and the distance-gated passes ended with zero active. The p95 frame times ranged from 17.8 to 17.9 ms. There was no measurable frame-rate gain in this A/B. The current portable exports passed checksums, archive integrity, platform architecture and Mac signature checks and match runtime fingerprint fd9b3cb0d19cdfbce597a331e462913c197878834de1225415b842271b60fbd4. Evidence: /private/tmp/habibi-venue-native/fixed-input-results.json and /private/tmp/habibi-venue-export-check/distribution/manifest.json.

The follow-up 14-second release runs on the spine, plaza and north ring lost focus, so the broader 60 FPS moving gate remains open. Evidence: /private/tmp/habibi-venue-moving/fixed-input-results.json.

## Remaining acceptance

- Establish at least 60 FPS during representative moving gameplay at Medium. Repeat the Mac release probe with sustained foreground focus and the full HUD.
- Louis can use Continue in the Mac review app for a ten-minute active shift. Record whether the shift feels busy enough and whether he would play another. Review the soft hit, glancing scrape and hard frontal fall at normal speed, including the transition to the clinic and whether the resulting bills feel proportionate. Compare the school against Louis's photos.
- Give the friend the portable build to try from New Game. After ten minutes, record whether they want to keep playing and where they hesitated or stopped.
- On a native Windows x64 machine, extract the portable ZIP, launch the executable, start a shift and verify movement and a pickup and delivery. The archive and executable structure have already been checked on Mac.
- Record the itch.io project URL and publishing approval, upload both platform builds, then verify the downloads from the published page.
