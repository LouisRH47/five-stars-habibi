# Polish pass plan (Sessions 66 to 72): better looks, better screens

Written 4 November 2026, after the Looks pass (Sessions 52 to 64) was merged into `looks-build`.
Louis asked: *"think about things you could add, like improved graphic styles and improved UI and
everything. Please research and try to add that."* This file is the research and the plan. Nothing in
it is built yet. The appendix has the PRD text, a Decisions-log line and the BUILD_PLAN prompts, ready
for the lead to paste in.

**Pictures:** what it looks like now, in game: [docs/polish/before_hud.jpg](polish/before_hud.jpg) and
the start screen [docs/polish/before_start.jpg](polish/before_start.jpg). A layout mock of the HUD after
Sessions 68 to 70: [docs/polish/after_hud_mock.svg](polish/after_hud_mock.svg)
([jpg preview](polish/after_hud_mock.jpg)). Copies are in /home/claude/out/polish_*.

## 1. What we saw (the starting point)

From the in-game screenshots (real Forward+ renderer, 1280 x 720) and the Session 55 to 64 renders:

- **The world** is bright and clean now (Session 55: AgX tone mapping, exposure 1.3, saturation 1.3,
  soft shadows, haze from 130 m), but:
  - The ground blurs into a smear only a few metres ahead (paving and roads at a low angle). The
    project uses Godot's default anisotropic filtering level (4x).
  - The sky is a plain two-colour gradient (ProceduralSkyMaterial) with no clouds, so the top half of
    the screen is empty, and big gradients can show banding.
  - Water (stream, fountain, pools) is one flat colour with sine ripples. There's no edge foam and no
    depth.
  - Roads and car parks are perfectly clean: no tyre marks, no oil, no sand blown onto the edges,
    no manholes.
  - The orange delivery beam is a plain see-through cylinder.
  - Very few particles: only the tyre dust (GPUParticles3D).
- **The UI** follows the mockup's colours and fonts, but:
  - Much of the text is small. The base window is 1920 x 1080 and many phone and clock labels are
    13 to 16 px, below the 18 px minimum for PC body text in the
    [Xbox Accessibility Guidelines (XAG 101)](https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-101-text-display.md).
  - The phone is one long white column (status, order, chips, accept/skip, two goals, insurance,
    a profile button, the next-goal bar), so the important part (what to do next) doesn't stand out.
  - Wallet, rating and level live inside the phone. In the mockup they sit as three chips at the top
    left.
  - The clock panel is big but mostly empty (time, "Shift 1", "A sunny day"). The mockup has a shift
    progress bar and a temperature line.
  - The speed panel has the number and "km/h" on different lines with a lot of empty space.
  - Colour is the only thing that tells good from bad on the meter bars (green, orange, red).
  - The start screen is a flat 2D desert with a palm that is half behind the phone. The phone has a
    big empty gap above the buttons.
  - There are no UI sounds apart from the delivery jingles, and no hover or press feel on buttons.
  - There are no accessibility options (text size, colour help, less shaking).

## 2. Research: what we learned

**Schedule I (Louis's reference).** Reviews describe it as simple graphics with an odd, cartoony art
style ([Notebookcheck](https://www.notebookcheck.net/Steam-This-game-looks-like-trash-but-gets-Overwhelmingly-Positive-reviews.977584.0.html),
[PC Gamer](https://www.pcgamer.com/games/sim/you-may-act-like-walter-white-and-look-like-rick-and-morty-but-this-drug-dealer-sim-blowing-up-on-steam-isnt-just-a-goofy-meme-game)).
None of them say much about its lighting, so we copy the feeling: simple flat-coloured shapes, and
lighting, sky and colour doing the heavy lifting. Session 55 did the basics. The next steps are a
sky with clouds, a colour grade and small surface details. No outlines by default (Louis can try
them, see item L8).

**Making low poly look good** ([Game Developer, "How To Make Low Poly Look Good"](https://www.gamedeveloper.com/design/how-to-make-low-poly-look-good)):
- Lighting is "THE most important part": a sun to one side, a sky for fill light, and bounce light.
  For us that means SSIL on High (L5).
- Flat colours, with complexity coming from light. Don't make everything equally saturated, and
  don't push grass to neon.
- Haze separates near from far. We already have it.
- Colour grading: "warm the highlights, cool the shadows slightly, and add vignetting" (L3, L4).
  Light depth of field gives a "miniature" feel, which suits menus and the Delivered card (S1, S4).

**What Godot 4 (4.7) can do on each renderer.** From the docs:
[renderer feature table](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html),
[environment and post-processing](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html).
The browser and iPad use **Compatibility**. The Mac uses **Forward+**.

| Feature | Compatibility (web, iPad) | Forward+ (Mac) | Used for |
| --- | --- | --- | --- |
| Tonemapping, Adjustments (incl. colour-correction LUT) | yes | yes | L3 colour grade |
| Glow | yes | yes | already on |
| SSAO | yes, a simpler version since 4.6 (only radius and intensity) | yes | L5 (could: web Medium) |
| SSIL, SDFGI, volumetric fog, SSR | no | yes | L5 SSIL on High only |
| Depth of field blur | **no** | yes | S1/S4 menus: desktop only, web shows no blur |
| Decals | yes, 8 per surface and 64 per view | yes, no limit | W3 road wear |
| GPU particles | yes, but no trails and no SDF collision | yes | W4/W5 |
| Screen and depth texture in shaders | yes | yes | W2 water foam, S5 pause blur, L8 outline |
| FXAA / SMAA / TAA | SSAA only | all | already set in Session 52 |
| Debanding | no | yes | L1 |

Other Godot facts we use:
- `Viewport.anisotropic_filtering_level` (default 4x) sharpens textures seen at a low angle
  ([Viewport class](https://docs.godotengine.org/en/stable/classes/class_viewport.html)).
- `Environment.adjustment_color_correction` takes a 1D gradient or a **3D LUT**. A 17³ or 33³ texture
  is enough, imported as Texture3D with 33 horizontal slices
  ([docs](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html)).
- Sky shaders can skip expensive parts in the lighting pass with `AT_CUBEMAP_PASS`. Clouds then
  cost only the pixels you can see.
- Decals have Distance Fade (begin and length) to cut their cost
  ([Using decals](https://docs.godotengine.org/en/stable/tutorials/3d/using_decals.html)).
- Tweens run while the game is paused if they are bound to a node with `process_mode = ALWAYS`, or set
  `TWEEN_PAUSE_PROCESS`. `TRANS_BACK` + `EASE_OUT` gives the small overshoot "pop"
  ([Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html)).

**Free shaders and assets (only CC0, or written by us).**
- Outline by inverted hull, **CC0**: [godotshaders "The simplest outline shader"](https://godotshaders.com/shader/the-simplest-outline-shader-via-material/).
  The post-process outline ([godotshaders](https://godotshaders.com/shader/high-quality-post-process-outline-fixed-for-4-3))
  is **MIT**, and it needs the normal buffer (Forward+ only). Don't copy it. Write our own depth-only one if Louis wants outlines.
- Fake light shafts (a cone mesh, additive, Fresnel fade), **CC0**: [godotshaders "Fake Godrays"](https://godotshaders.com/shader/fake-godrays-godot-4-2/).
- Stylised sky ([godotshaders](https://godotshaders.com/shader/stylized-sky/)) and stylised water
  ([godotshaders](https://godotshaders.com/shader/stylized-water-for-godot-4-x)) are **MIT**. Don't copy
  them. We write our own (the ideas are general: a gradient by height, noise clouds, foam where water
  depth is small, colour by depth).
- Particle sprites: **Kenney Particle Pack** (80 sprites, **CC0**), listed on the
  [Godot Asset Library](https://godotengine.org/asset-library/asset/784). Or make soft circles and
  sparkles with a script (simplest, no download).
- Sounds: keep making them with tools/make_sounds.py (ours, CC0).

**UI motion ("juice").** Material Design 3 motion tokens give a sensible scale
([material-web tokens](https://github.com/material-components/material-web/blob/main/tokens/versions/v0_192/_md-sys-motion.scss)):
short 50 to 200 ms (button feedback), medium 250 to 400 ms (panels sliding), long 450 to 600 ms (big
reveals). Emphasised easing is cubic-bezier(0.2, 0, 0, 1). Classic talks on game feel: Jonasson and
Purho, ["Juice it or lose it"](https://www.youtube.com/watch?v=Fy0aCDmgnxg), and Jan Willem Nijman,
["The art of screenshake"](https://www.youtube.com/watch?v=AJdEqssNZ-U). Every action gets an answer
(sound, movement, colour), but small, and never in the way.

**Delivery and driver apps (layout patterns only, no brands).**
- A ride-hailing offer card has an **8 to 11 second** window to accept. The redesign grouped the
  information, used one icon and colour system, and made **tap targets bigger, contrast higher and
  text larger**, for both quick and slow deciders
  ([offer card case study](https://contra.com/p/eUcrB3Ao-uber-driver-offer-card-experience-redesign)).
- Drivers see what they earned **after each trip** on screen, with daily totals one tap away
  ([driver app announcement](https://www.uber.com/blog/introducing-the-new-driver-app/)).
- Common pattern: pay big at the top, then distance and time, then a pickup → drop-off timeline with
  two dots and a line, and an accept button with a ring that runs down. Our offers wait 30 s (PRD), so
  the ring runs 30 s.

**Delivery results.** Death Stranding grades each delivery on completion, time and package condition
([Twinfinite guide](https://twinfinite.net/guides/death-stranding-delivery-score-how-to-improve-what-it-is/)).
That's the same as our Time / Freshness / Damage tiles, so the Delivered card can reveal them one by
one, like a report card.

**Mini-maps.** A rotating (heading-up) map is best for following a route. North-up is best for learning
a big area you cross again and again. Offer both
([Game Developer, "Minimap rotation"](https://www.gamedeveloper.com/design/minimap-rotation)). Ours is
heading-up today. Keep it as the default and add a setting.

**Accessibility.** [Game Accessibility Guidelines, basic](https://gameaccessibilityguidelines.com/basic/):
"Use an easily readable default font size", "Ensure no essential information is conveyed by a fixed
colour alone", "Provide high contrast between text/UI and background", "Avoid flickering images and
repetitive patterns", separate volume controls (we have them). XAG 101: PC body text at least
**18 px at 1080p**, and players should be able to scale text up to **200%**. For colour help, use the
Okabe-Ito colour-blind-safe set (blue #0072B2, orange #E69F00, vermilion #D55E00, plus icons and
words), never colour alone.

## 3. The improvements (30), by priority

Each item has an ID: **L** = light and look, **W** = world details, **H** = HUD, **P** = phone and
mini-map, **S** = screens, menus, sounds and accessibility. "Cost" is on Low (iPad and web,
Compatibility), Medium and High. Every new thing sits behind a GameConfig flag (true = new), and the
old path stays, so nothing is deleted.

### Must (the biggest visible wins, low risk)

**L1. Sharp ground into the distance, no banding in the sky** (Session 67)
- Louis sees: paving, roads and grass stay crisp much further ahead instead of turning into a smear.
  Smooth sky gradients.
- Why: our screenshot shows the blur 5 m ahead. Anisotropic filtering fixes textures at low angles,
  and debanding removes stripes in gradients (Forward+ only, see the table).
- How: in sun_cycle.gd `apply_graphics()`: `get_viewport().anisotropic_filtering_level` =
  `Viewport.ANISOTROPY_16X` on Medium and High, `ANISOTROPY_4X` on Low. `get_viewport().use_debanding`
  = true on desktop. Make sure ground materials use `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC`
  (terrain_materials.gd does already; check grass/sand/paving in static batches). Numbers in
  GameConfig: `ANISO_LEVEL := [Viewport.ANISOTROPY_4X, Viewport.ANISOTROPY_16X, Viewport.ANISOTROPY_16X]`.
- Cost: almost free on GPUs. Web: 4x (no change).
- Risk: very low.
- Done when: a test reads the viewport level per Graphics setting, and a screenshot of the Plaza paving
  looking down the street is crisp 20 m ahead.

**L2. A stylised sky with soft clouds and a sun** (Session 67)
- Louis sees: a warm sky with slow, soft, flat-bottomed cartoon clouds and a glowing sun disc. In the
  morning the clouds are peach, white at noon, gold and pink at sunset.
- Why: the top third of every screenshot is an empty gradient. Clouds give depth and show which way
  the light comes from (Schedule I and cosy games always have them).
- How: new `assets/shaders/sky_stylized.gdshader` (`shader_type sky;`), written by us:
  - Gradient: `top`, `horizon`, `ground_horizon` uniforms, fed from LIGHT_KEYS (sun_cycle sets them, like
    it sets ProceduralSkyMaterial today).
  - Sun disc: `smoothstep` on `dot(EYEDIR, LIGHT0_DIRECTION)`, size 2.5°, plus a soft halo 12°.
  - Clouds: two octaves of value noise on `EYEDIR.xz / (EYEDIR.y + 0.15)` (a flat cloud layer),
    stepped with `smoothstep(0.55, 0.62, n)` for cartoon edges, bottoms 15% darker, scrolling
    0.004 units/s. Fade out below 6° above the horizon.
  - `if (AT_CUBEMAP_PASS) { no clouds }`, so the lighting cubemap stays cheap.
  - New script `scripts/sky_look.gd` builds the ShaderMaterial and swaps it in when
    `GameConfig.SKY_STYLIZED` is true. The old ProceduralSkyMaterial stays when the flag is false.
- Cost: Low (web/iPad) gets the gradient and sun only (`clouds_on = false`). Medium and High get clouds.
  Sky pixels only, a few noise reads each.
- Risk: medium. The sky drives ambient light, so check that colours stay warm (compare screenshots at
  8, 12 and 17.5 h). The sky radiance is incremental already.
- Done when: renders at 08:30, 12:00 and 17:30 show clouds coloured for the time of day. Flag off = the
  old sky. Test: the sky material is a ShaderMaterial on Medium, with clouds off on Low.

**L3. A colour grade (warm highlights, cool shadows)** (Session 67)
- Louis sees: the picture looks "finished", like a film still. Sunny parts are warm and golden, shade
  is a little blue-teal (our teal), and whites aren't grey.
- Why: the Game Developer article's colour-correction advice. It works on every renderer (Adjustments),
  so the browser gets it too.
- How: `tools/make_luts.py` (plain Python, writes PNGs) makes 33³ LUT strips (33 x 1089 px) in
  `assets/luts/`: `neutral.png`, `golden.png` (lift shadows +0.02 blue, highlights ×1.04 red ×0.97
  blue, a tiny S-curve), `fresh.png` (cleaner, less warm). Each `.import` sets Texture3D with 33
  slices. sun_cycle `_apply_look()` sets `env.adjustment_color_correction`. `GameConfig.LOOK_LUT :=
  "golden"` ("neutral" = off). Keep saturation 1.3, or drop it to 1.2 if the LUT adds colour.
- Cost: one texture read per pixel on all levels. Fine on iPad.
- Risk: low. It can look too orange, which is why Louis picks (see section 6).
- Done when: before/after renders at 10 h and 17 h for "golden" and "fresh" are in
  /home/claude/out/, and Louis picks one.

**W1. A better delivery beam, with a ring and an arrival burst** (Session 68)
- Louis sees: the target is a soft light column that fades out at the top, with small sparkles rising,
  and a glowing ring on the ground at the door that pulses slowly and shrinks as you get close.
  **Orange** for pick-up, **teal** for drop-off (matching the phone). When you arrive and the
  handover starts, the ring bursts outward and the beam fades.
- Why: it's the thing you look at most. Crazy-Taxi-style games make the target loud and clear, and
  colour tells you which step you're on.
- How: `scripts/arrival_marker.gd` (new, a Node3D with a beam cylinder, a ring (TorusMesh or flat
  quad) and a small GPUParticles3D with 16 sparkles) and `assets/shaders/beam.gdshader` (unshaded,
  `blend_add`, alpha = `(1-UV.y)^1.5`, scrolling stripes 0.6 m apart moving up 0.8 m/s, Fresnel edge).
  Only change in `delivery_manager.gd`: `_make_marker()` returns the new marker when
  `GameConfig.MARKER_V2` is true. The marker gets `set_step(stage)` and `burst()`, called from
  `_on_stage_changed` with the same `visible` logic. Ring radius 1.6 m (pulse ±10% at 1 Hz). The ring
  shrinks to 1.1 m within 8 m of the door.
- Cost: tiny (2 meshes, 16 particles). Web OK (no trails).
- Risk: low. The marker has no collision, so keep it that way. Don't change the door spot.
- Done when: the smoke test still passes. The new test checks: orange on TO_RESTAURANT, teal on
  TO_VILLA, burst on arrival, hidden in NONE/OFFERED, MARKER_V2=false gives the old cylinder.

**W2. Water that looks wet** (Session 68)
- Louis sees: the stream, fountain and pools get a lighter rim of foam where the water meets stones and
  walls, deeper blue in the middle, sparkles where the sun hits, and in the pools moving light
  patterns (caustics) on the tiles.
- Why: water is flat colour today. Foam at the edges is the classic trick in stylised water.
- How: rewrite `assets/shaders/water.gdshader` (keep the old one as `water_v1.gdshader`). Use
  `hint_depth_texture` (works on Compatibility) to get water depth. Foam where depth < 0.25 m
  (`smoothstep`), broken up by noise. Colour mixes `shallow` → `deep` over 0 to 1.2 m. Sun glints:
  a `pow(dot(reflect, sun), 64)` highlight. A `uniform int kind` (0 stream, 1 pool, 2 fountain): pools
  add a voronoi caustic pattern (2 layers, 0.7 m cells) and a clearer tint. One line in `pool.gd` sets
  `kind = 1`. ambient_motion.gd sets 2 for the fountain (if it builds the fountain's material; else
  leave the default). Reverse-Z note: use `textureLod(depth, SCREEN_UV, 0.0).r` and
  `INV_PROJECTION_MATRIX` the 4.3+ way.
- Cost: one depth read and a little maths per water pixel. Web OK. Low: `kind` caustics off.
- Risk: medium. Depth on Compatibility uses 24-bit without reverse Z, so test both. The foam can
  flicker at a distance: fade it out after 60 m.
- Done when: renders of the stream at 10 h, the community pool at 12 h and the fountain at 17 h show
  edge foam and the pool caustics. pool_test and spine_test pass.

**H1. HUD laid out like the mockup: wallet, rating and level chips at the top left** (Session 69)
- Louis sees: three dark chips at the top left (WALLET 126 Dh / RATING 4.8 ★ / LEVEL 3 with an XP bar
  and "3 in a row"), like the mockup. When money comes in, the wallet number counts up and a green
  "+15" floats up next to it. When you level up, the XP chip flashes gold.
- Why: the mockup is the agreed look. The phone gets lighter (P1). Players glance at money and stars
  all the time, so they should be outside the busy phone.
- How: new `scripts/hud_chips.gd`, a Control added under the existing `HUD` CanvasLayer so the
  Delivered card's hide list still hides it. Built in code with `UiPalette` sizes. It listens to
  `GameState.money_changed` and `stats_changed`. `UiJuice.count_up(label, from, to, 0.6)`. Floating
  "+N": a Label tweened 24 px up and faded over 0.8 s. `GameConfig.HUD_TOP_CHIPS := true` (made in
  Session 66). The phone hides its own wallet and stars header when it's true (P1).
- Cost: none.
- Risk: low. The meters panel is at the top left today, so H3 moves it to the bottom centre (as in the
  mockup), and both are in the same session.
- Done when: the HUD test finds no overlap between any two HUD panels at 1280x720, 1920x1080, 1024x768
  and 2732x2048 (iPad), at text sizes 100% and 130%.

**H2. A clock that tells you more** (Session 69)
- Louis sees: "☀ 11:42 AM" in big letters, a line "Shift 3 · 41°C · Brain Freeze special" and a thin
  yellow shift-progress bar. In the last in-game hour the bar turns orange and the clock pulses gently
  once a minute.
- Why: the mockup's clock (time, "Day shift · 46°C", progress bar). The empty clock box is now useful,
  and the temperature is Dubai flavour that also explains why ice cream melts.
- How: `shift_screen.gd` builds the clock. Temperature from the hour: `lerp` over
  `GameConfig.SHIFT_TEMPERATURE := {8.0: 31, 13.0: 42, 15.0: 43, 18.0: 37}` (°C). On "Hot Noon" days
  add 4. Progress = (hour − 8) / 10. Shrink the panel to 220 x 72 (at 1280) like the mockup.
- Cost: none.
- Risk: low. The smoke test reads the clock text, so keep `_clock.text` the same format.
- Done when: the HUD test reads the temperature at 08:00, 13:00 and 18:00 and the bar at 0, 50 and
  100%.

**H3. Meters with icons, words and a warning pulse (and colour help)** (Session 69)
- Louis sees: the three meters move to the bottom centre (as in the mockup), each with an icon (stopwatch,
  thermometer or snowflake for cold food, box), a word on the right ("On time / A bit late / Late",
  the Delivered card words) and two tick marks on the bar at 60% and 30%. When a meter drops into a
  worse band, the bar flashes, shakes 4 px for 0.25 s and a soft warning blip plays.
- Why: "no essential information by colour alone" (GAG). The pulse tells you the moment you lose
  half a star, which teaches riding carefully.
- How: `meters_panel.gd` + `ui/meters_panel.tscn`. Icons drawn in code (`_draw`) or as small SVGs made
  by a script in `assets/ui/icons/` (ours). Band colours come from `UiPalette.band_colour(band)`, which
  follows `Settings.colour_assist` (normal: green #4CC98A / orange #F59A2E / red #E5483A. Assist:
  blue #0072B2 / orange #E69F00 / vermilion #D55E00, with diagonal stripes on red). Pulse with
  `UiJuice.shake()` and `UiSounds.play("meter_warn")`.
- Cost: none.
- Risk: low. Keep the node names the smoke test uses (check `tests/smoke_test.gd` for "MetersPanel").
- Done when: the test forces freshness from 70 to 50 and checks one pulse, the word "Okay" and the
  colour. With colour assist on, the colours are the assist set.

**P1. A phone you can read at a glance** (Session 70)
- Louis sees: bigger text (18 px body at 1080p, titles 24 to 28), one clear "what now" line, and less
  clutter. Goals fold into a small "Goals 1/2 ▾" row (press G or tap to open). Insurance becomes a
  small shield icon with ON/OFF. Wallet and stars move to the HUD chips.
- Why: XAG 101 minimum sizes. Driver apps keep the current step big and everything else small. Our
  screenshot shows 13 px text and 10 separate rows.
- How: `phone.gd` + `ui/phone.tscn`. Use `UiPalette.FONT_*` sizes. A `_set_mode()` with 4 modes:
  `waiting` (goals open, "Waiting for orders…" with 3 bouncing dots), `offer` (P2), `to_restaurant`,
  `to_villa` (P3). Hide the header money and stars if `GameConfig.HUD_TOP_CHIPS`. Keep every function
  the tests call (`buzz()`, `event_text()`, the choices box, the hold bar) and the labels the smoke test
  reads.
- Cost: none.
- Risk: medium. Lots of tests read the phone (phone_refresh, replay_ui, reception_panel,
  lifecycle_regression, smoke). Change the look, not the names. Run them all.
- Done when: no phone label is under 16 px at the base size. The phone fits at 1024x768 at 130% text.
  All phone tests pass.

**P2. The offer card: big pay, a route line and a countdown ring** (Session 70)
- Louis sees: a new order slides in from the right with a buzz. Big "15 Dh", "1.2 km · about 3 min",
  a two-dot route line "● Spill the Brew → ● Villa 7, C2", food and special chips, and the Accept key
  "E" inside a ring that runs down over the 30 seconds (it turns red in the last 5). Choosing between
  two orders (rating 4.5+) shows two smaller cards side by side with "1" and "2".
- Why: the driver-app offer-card pattern (grouped information, big targets, a visible timer). The
  timer is only a chip today.
- How: new `scripts/countdown_ring.gd` (a Control that draws an arc with `draw_arc`, 64 points,
  width 6) and `scripts/phone_offer_card.gd`. The time left comes from the DeliveryManager like the
  current "18 s" chip. Slide in: offset x +320 → 0 over 0.3 s, `TRANS_BACK`/`EASE_OUT`. Distance:
  the straight-line distance to the restaurant plus restaurant to villa, rounded to 0.1 km. Time:
  distance ÷ 20 km/h (the PRD's normal pace).
- Cost: none.
- Risk: low to medium (the choices box is tested by replay_ui).
- Done when: the test offers an order and checks that the ring goes from 1.0 to about 0.5 after 15 s
  (paused time doesn't count), the slide-in ends at offset 0, and two-order mode shows 2 cards.

**S1. A Delivered card that feels like a reward** (Session 71)
- Louis sees: the card slides in, then the three tiles flip in one by one (Time, Freshness, Damage,
  0.15 s apart), then the stars pop with a rising "ding" (each star a little higher in pitch), "You
  earned" counts up with soft ticks, a tip drops in like a coin, and on a perfect delivery a big
  "PERFECT!" stamp slams in at −8°, with the PERFECT jingle. The XP bar fills and "Level up!" shows if
  you reached a new level. On the Mac the background behind the card goes softly out of focus. Press
  E at any time to skip to the end.
- Why: research on driver apps (earnings after each trip) and Death Stranding's per-category grades.
  The PRD's "A perfect delivery feels special". The pops exist (Session 31) but all at once.
- How: `delivered_card.gd`: one Tween sequence (`TWEEN_PAUSE_PROCESS`), timings in GameConfig
  (`CARD_TILE_GAP := 0.15`, `CARD_COUNT_TIME := 0.6`, `CARD_STAMP_TIME := 0.25`). Star pitch: 1.0,
  1.06, 1.12, 1.19, 1.26 (semitones). Depth of field: give the camera a `CameraAttributesPractical`
  with `dof_blur_far_enabled`, distance 7 m, transition 5 m, amount 0.06 while the card is up, and
  remove it after (desktop only, because Compatibility has no DOF). Skip: E during the sequence calls
  `tween.custom_step(99)`.
- Cost: none. DOF on Forward+ only (a small blur pass while paused).
- Risk: medium. The card is tested a lot (smoke reads `last_result`, earned, stars). Keep the values
  and the `closed` signal the same.
- Done when: the test runs a delivery and checks the order of events (tiles, stars, count-up end value
  = earned), that E skips to the end, that closing still emits `closed` once, and that the camera has
  no DOF attributes after closing.

**S2. Accessibility settings: text size, colour help, less motion** (Sessions 66 and 71)
- Louis sees: a new "Accessibility" part in Settings with **Text size** (100% / 115% / 130%),
  **Colour help** (on/off: blue-orange-vermilion with patterns instead of green-orange-red), **Less
  motion** (on/off: no camera shake, no speed lines, no FOV kick, no phone shake, shorter pops) and
  **Mini-map** (Turns with you / North up).
- Why: Game Accessibility Guidelines basics, and XAG 101 (scale text). Kids and parents playing on an
  iPad need bigger text. About 1 in 12 boys has some colour blindness.
- How: Session 66 adds the saved values to `settings.gd` (static vars `text_size`, `colour_assist`,
  `reduce_motion`, `minimap_north_up`, in a new `[access]` section of settings.cfg) and applies text size
  with `get_tree().root.content_scale_factor = TEXT_SCALES[text_size]` (1.0, 1.15, 1.3). Session 71
  adds the rows to `settings_panel.gd`. Sessions 69 and 70 read the values. Esc and the pause menu
  still work.
- Cost: none.
- Risk: medium. 130% text can push panels off a small screen, so every UI session tests 130% at
  1024x768.
- Done when: the settings test sets each option, saves, reloads and reads it back, and the
  content scale changes. The UI tests pass at 130%.

### Should (clear improvements, a bit more work)

**L4. A soft vignette** (Session 67)
- Louis sees: the corners of the screen slightly darker, pulling your eye to the middle (your rider).
- Why: the Game Developer article's grading advice. Cheap on every renderer.
- How: `assets/shaders/screen_grade.gdshader` (canvas_item, `hint_screen_texture` not needed: just a
  transparent ColorRect whose alpha = `smoothstep(0.55, 1.0, length(UV-0.5)*1.4) * strength`, colour
  #1B1D22). Added by `scripts/polish/look_extras.gd` as CanvasLayer `layer = -1` (under the HUD,
  over the 3D). `VIGNETTE_STRENGTH := 0.22`. Hidden indoors? No, keep it.
- Cost: one full-screen quad with blending. Fine even on iPad.
- Risk: very low.
- Done when: the layer exists under the HUD layers, strength comes from GameConfig, and 0 = off.

**L5. Warm bounce light on High (and maybe soft shadows on the web)** (Session 67)
- Louis sees (Mac, High): walls next to sunny sand get a warm glow, shade under awnings isn't flat
  grey, and corners have colour.
- Why: "indirect bounce light" from the low-poly article. Godot's SSIL does it on screen, Forward+
  only.
- How: sun_cycle `apply_graphics()`: `env.ssil_enabled = level == 2 and forward_plus`,
  `ssil_radius 5.0`, `ssil_intensity 0.8`, `ssil_sharpness 0.98`, `ssil_normal_rejection 1.0`. Quality
  via `RenderingServer.environment_set_ssil_quality(MEDIUM, half_size true, ...)`. **Could:** SSAO in
  the browser on Medium only (`env.ssao_enabled = level > 0` without the `forward_plus` check, because
  4.6+ has a simpler SSAO on Compatibility). Flag `WEB_SSAO := false` until Louis tests it on the iPad.
- Cost: SSIL is a few ms on a mid GPU at half size, High only. Web SSAO is light but untested.
- Risk: medium (SSIL can make interiors blotchy). Check the interiors render sheet.
- Done when: renders on High show warm bounce, and Medium is unchanged.

**L6. Light shafts through shop windows and Plaza passages** (Session 67)
- Louis sees: soft beams of sunlight with floating dust coming through the big shop glass into the
  interiors, and through the covered passages in the Plaza, strongest in the morning and late
  afternoon when the sun is low.
- Why: very "cosy" and makes rooms look lit by the real sun. CC0 technique (Fake Godrays).
- How: `scripts/light_shafts.gd`, added by look_extras. It finds nodes in the group `interior_glass`
  (it exists) and the Plaza passage roofs (by name or the plaza data), and places a cone or box mesh
  with an additive shader (gradient along the length, noise dust scrolling 0.05 m/s, Fresnel edge
  fade, alpha 0.18) slanted along the sun direction. Opacity by hour: 1 at 8 to 9.5 and 16 to 18, 0.3
  at noon. Shadows off. At most 24 shafts. Medium and High only.
- Cost: additive overdraw. Keep shafts small, only within 40 m (visibility range).
- Risk: medium. Shafts can poke through walls, so keep them inside the room box (the interior
  rectangle is known).
- Done when: interior renders at 9 h show shafts, nothing pokes outside a wall (the test checks each
  shaft's box is inside its room box), and Low has none.

**W3. Road wear, sand drifts and street furniture on the ground** (Session 68)
- Louis sees: dark tyre marks at junctions and car-park entrances, oil spots in car-park bays, round
  manhole covers and drain grates along the ring road, a few cracks and patches, and pale sand blown
  onto the edges of the roads and paths (very Dubai). Faded zebra and "SLOW" paint in Arabic and
  English near the school.
- Why: clean roads look like a toy. Small wear makes it look lived in (a common stylised-city trick),
  and decals are cheap and work on the web (64 per view).
- How: `tools/make_decals.py` (Python, makes PNGs with alpha in `assets/textures/decals/`: tyre_arc,
  oil_spot, manhole, drain, crack, patch, sand_drift, slow_ar_en (with the existing Arabic shaping
  helper, or draw it in Godot with the sign text helper and bake). `scripts/road_decals.gd`, added by
  world_extras, reads the road and car-park rectangles from `data/wahat_al_shams.gd` (read only, no
  generator edits) and places Decal nodes with a fixed random seed: sand drifts every 12 to 20 m on
  road edges, tyre arcs at every junction, oil in 1 of 4 bays, manholes every 40 m on the ring road.
  `Decal.distance_fade_enabled = true`, begin 35 m, length 10 m (Low: 20 m and half as many). Albedo
  only. Keep the decal box thin (size y 0.3 m, centred on the road surface, `upper_fade` 0.3,
  `lower_fade` 0.3) so a passing tyre is touched for a moment at most. If the ground meshes are on
  their own render layer, also set `cull_mask` to that layer only (check first: today most things
  are on layer 1, and moving the ground to another layer would mean editing builders this session
  doesn't own, so don't).
- Cost: Forward+ fine. Compatibility: at most 64 visible at once, so Low places fewer and fades sooner.
- Risk: medium. Decals on the wrong surface (grass, a wall, a car) look bad. Project only down, keep the
  box thin, and keep decals 1 m away from kerbs, walls and parked cars (the car-park bay list says
  where cars are).
- Done when: the test counts decals per level within budget, every decal centre is on a road or car-park
  rectangle, and the layout test passes. Renders of a junction and a car park.

**W4. Life in the air: steam, spray, leaves and sand** (Session 68)
- Louis sees: a wisp of steam from hot food bags at pick-up and from the shawarma and pizza kitchen
  vents on the Plaza roofs, fine spray around the fountain and the falaj (stream) drops, a few leaves
  drifting down in the spine, gardeners' sprinkler arcs, swimmers' splashes, and on Medium and High
  thin sand wisps blowing across the ring road.
- Why: the PRD's "lots of little details", and movement makes a still world feel alive.
- How: `scripts/vfx_ambient.gd` (added by world_extras) finds spots by groups and data: fountain and
  stream (from the data list), Plaza shop roofs (venue rectangles), swimmers (script path
  `swimmer.gd`), gardeners. It also listens to `GameState.order_stage_changed` (steam puff at
  pick-up for hot foods: pizza, shawarma, coffee, manakish). Particle textures: soft dot, wisp, leaf,
  droplet, made by `tools/make_vfx_textures.py` (or Kenney Particle Pack, CC0, credited). Budget:
  `VFX_MAX_PARTICLES := [150, 600, 1200]`. Each emitter has `visibility_aabb` and a visibility range of
  50 m, so far ones don't run.
- Cost: GPU particles work on Compatibility (no trails). Low gets the fountain and pick-up steam only.
- Risk: low to medium (too much stuff looks messy). Start subtle.
- Done when: the test counts live emitters and the particle total per level within budget, and steam
  starts at a pizza pick-up. Renders at the fountain and a Plaza roof.

**W5. Celebration bursts in the world** (Session 68)
- Louis sees: on a 5-star delivery, a small burst of confetti in Snackaroo colours at the door; on a
  tip, a few coins hop out; on a level-up, a ring of light round your rider. This happens in the 3D
  shot behind the Delivered card.
- Why: the PRD's PERFECT moment. Feedback where the action happened.
- How: `scripts/vfx_bursts.gd` (world_extras) listens to `GameState.order_delivered` and
  `stats_changed` and reads `GameState.last_result` (stars, tip). One-shot GPUParticles3D with
  `process_mode = ALWAYS` (the card pauses the game). 40 confetti (quads, 4 colours), 0.9 s.
- Cost: tiny. Web OK.
- Risk: low.
- Done when: the test delivers a 5-star order and finds one confetti emitter that finishes.

**H4. A tidy speed and stamina panel** (Session 69)
- Louis sees: "21 km/h" on one line (big number and small unit on the same baseline), "SHIFT sprint"
  as a small key hint, and the stamina bar in 5 segments that glow cyan while you sprint and pulse
  orange when you're tired. The panel is smaller.
- Why: the empty panel in our screenshot. Segments read faster than a thin bar.
- How: `hud.gd` + `ui/hud.tscn`: an HBox for the number and unit, a custom `_draw` stamina bar with
  `STAMINA_SEGMENTS := 5`. Keep the `ProgressBar` node (the gear_ride test reads `_bar.max_value`;
  hide it and draw over it, or keep it as the segment base).
- Cost: none.
- Risk: low.
- Done when: gear_ride passes (stamina 150/200 shows 75%), and the HUD test checks one baseline.

**H5. A hold ring on screen** (Session 69)
- Louis sees: while you hold E at a door or counter, a round orange ring fills around a small "E" key
  near the middle of the screen (it's on the phone today too), with a pop when it finishes.
- Why: you look at the door, not the phone. A big, central progress ring is the standard "hold"
  pattern.
- How: `scripts/hold_ring.gd` under the HUD layer. It reads the hold progress the phone's bar uses
  (find where the phone gets it, e.g. `DeliveryManager` or `OnFoot`, and read the same value, read
  only). Shows only while progress > 0. 64 px ring, `draw_arc`.
- Cost: none.
- Risk: low.
- Done when: the test starts a hold and sees the ring's value follow the hold progress.

**H6. Less motion respected everywhere in the HUD and camera** (Session 69)
- Louis sees: with "Less motion" on, no camera shake on bumps, no speed lines, no FOV stretch, and the
  meter pulse only flashes (no shake).
- How: `follow_camera.gd` (`_on_bumped`, `_on_speed_bump`, `_sprint_feel`) and `speed_lines.gd` check
  `Settings.reduce_motion`.
- Done when: the test bumps the camera with the setting on and the camera offset stays 0.

**H7. The shift summary as a payout screen** (Session 69)
- Louis sees: "Shift done!", then rows that count up one after another (Deliveries, Stars, Money,
  Tips, Bonuses, Bills), goal stamps ("Goal done +15 Dh") that slam in, gold "New best!" ribbons, and
  a "Tomorrow: Rush Hour" card at the bottom. E skips to the end.
- Why: same reasoning as S1. The end of a shift is the biggest reward moment.
- How: `shift_screen.gd`, a Tween sequence with `UiJuice.count_up`. Timings in GameConfig.
- Risk: medium (replay_ui reads summary rows; keep their text).
- Done when: the replay_ui test passes, and the new test checks the final values equal the summary and
  E skips.

**P3. The job view: the next step, big** (Session 70)
- Louis sees, after accepting: a status pill (TO RESTAURANT / TO CUSTOMER / AT THE DOOR), a two-step
  timeline (pick-up ● ─ ─ ● drop-off, done steps ticked), the place name big, "180 m" live distance,
  the note in a speech bubble, and one orange line saying what to do now ("Park · F to get off · hold
  E").
- Why: driver apps keep "what next and how far" biggest.
- How: `phone.gd` modes `to_restaurant` and `to_villa`. Distance from the bike to `target_door()`
  every 0.25 s, rounded to 10 m.
- Done when: the test steps through the stages and reads the pill and distance text.

**P4. A nicer mini-map** (Session 70)
- Louis sees: a dark ring round the map with N, E, S, W letters that turn with the map (N stays
  bigger), little round logo pins for the restaurants (the made-up logos from assets/logos), the drop-off
  pin with its villa number and, when it's off the map, an arrow on the ring pointing the way with the
  distance under the map ("Villa 7 · 180 m"). The map zooms out a little when you go fast (radius
  60 m at a stop to 90 m at sprint speed) and back in when you slow down. Option: North up.
- Why: the minimap research (offer both rotations). Edge arrows are the standard for off-map targets.
- How: `minimap.gd` + `ui/minimap.tscn`. Zoom: `lerp(MINIMAP_RADIUS_SLOW, MINIMAP_RADIUS_FAST,
  speed / sprint)` smoothed (0.5 s). North-up: skip the bike's yaw in `_world_xform` when
  `Settings.minimap_north_up` is true, and draw the player arrow turned instead. Logo pins:
  load the SVG logos at 20 px (cache textures). Keep `minimap_cache_test` working (the static map
  cache must still be used; zoom changes the draw scale, not the cache).
- Cost: small (the cache stays).
- Risk: medium (the cache test is picky).
- Done when: minimap_cache passes, and the new test checks the edge-arrow position for a far target, the
  zoom radius at 0 and 36 km/h, and north-up keeping north at the top while the bike turns.

**S3. UI sounds and button feel** (Session 71, with the sound player in Session 66)
- Louis sees and hears: buttons grow a little (3%) on hover with a soft tick, press down to 95% with
  a click, panels open with a short whoosh and close with a softer one, money counting has ticks, a
  warning blip when a meter drops, a level-up fanfare, and a stamp "thunk".
- Why: "every action gets an answer" (game feel talks). Today menus are silent.
- How: `UiSounds` autoload (Session 66, plays a key if its file exists, Effects bus, works on menus
  and while paused). Session 71 makes the sounds in `tools/make_sounds.py`: ui_hover, ui_click,
  ui_open, ui_close, tick, meter_warn, level_up, stamp, whoosh (short, 22 kHz mono, each under 40
  KB so the web build stays small). Theme (`ui/theme.tres`): hover is 8% lighter, pressed 8% darker
  with a 2 px offset, a 3 px orange focus ring for keyboard use. Button scaling with `UiJuice.press()` (it sets
  `pivot_offset` to the centre).
- Cost: none.
- Risk: low.
- Done when: every key in `UiSounds.KEYS` has a file, and the settings and start screens play hover and
  click (`UiSounds.play_counts`).

**S4. A living start screen and a fun loading screen** (Session 71)
- Louis sees: behind the title, a small 3D scene at golden hour: a villa corner with palms, a
  parked Snackaroo bike with its orange box and your rider leaning on it (your chosen look), the camera
  drifting slowly. On the Mac it's slightly out of focus behind the phone. The title drops in with a
  bounce, then "Rider to Driver", then the phone slides up. On the loading screen a little rider icon
  pedals along the progress bar, and the tips slide in one by one.
- Why: first impressions. The flat 2D desert in our screenshot hides the game's 3D look. A small
  diorama costs much less than loading the whole map.
- How: new `scripts/menu_diorama.gd` builds a tiny scene in a SubViewport (one villa piece from
  `villa_builder`, 3 palms, the bike scene, the rider with `rider_look`, a sun with the "golden" grade).
  `start_screen.gd` uses it when `GameConfig.START_DIORAMA` is true. Otherwise the old desert. Camera:
  slow orbit ±8° over 20 s. DOF far blur on desktop only. Title tween: y −40 → 0, 0.45 s, TRANS_BACK.
  `loader.gd`: a 2D rider icon (`_draw`, or a small PNG we make) moved along the bar with the progress.
- Cost: the diorama is about 30 meshes. On the web keep the SubViewport at 0.75 scale, no DOF.
- Risk: medium (the loading test checks that the game opens once per click; keep that path).
- Done when: loading_test passes, the start screen builds in both modes in the test, and there are
  renders of the start screen on Medium (Mac) and Low.

**S5. A blurred pause menu, and polish for the clinic and counter panels** (Session 71)
- Louis sees: when you press Esc, the game behind goes soft and blurry with a dark tint, and the
  Paused panel pops in. The clinic bills count up like the Delivered card (in red), and the counter or
  shop side panel slides in from the left.
- How: pause_menu: a ColorRect with a canvas_item shader using
  `hint_screen_texture, filter_linear_mipmap` and `textureLod(screen, SCREEN_UV, 2.5)` plus a 35% ink
  tint (works on all renderers). clinic_screen: `UiJuice.count_up` on the bill rows. side_panel: slide
  x −40 → 0, 0.25 s.
- Risk: low. Keep the clinic test numbers (crash_impact).
- Done when: crash_impact, reception_panel, shop and lifecycle_regression pass, and the pause blur exists
  only while paused.

### Could (nice extras, or waiting for Louis)

**L7. Moving cloud shadows on the ground** (Session 67)
- Louis sees: big soft shadows of the clouds sliding slowly over the community.
- How: one huge Decal (1000 x 600 m, projecting down) with a soft noise texture (made by script),
  `modulate` dark at 12% alpha, `upper_fade` and `lower_fade` set, its texture offset moving with the
  wind (1.5 m/s). Must match the sky clouds' direction. Medium and High only (Compatibility counts it
  against the 64 decals per view).
- Risk: medium (decal over the whole map is a big screen coverage. Measure).
- Done when: Louis likes it on the Mac and the frame time is unchanged within 1 ms.

**L8. Outlines (Louis decides; off by default)** (Session 67)
- Louis sees: thin, dark-teal lines round the edges of buildings, props and people, like a comic.
- Why: some cosy games use them. Schedule I is mostly known for flat shapes, not outlines, so this is
  a taste choice.
- How: our own depth-only post-process (a full-screen quad, a child of the current camera, added by
  look_extras): compare 4 neighbouring depth samples, line where the depth jump is more than 3% of the
  distance, colour #1B3A40 at 40%, 1 px, fading out from 40 to 80 m. Depth only, so it works on
  Compatibility (no normal buffer). `GameConfig.OUTLINES` and the "outlines" setting (Session 66
  makes the saved value; Session 71 adds the row only if Louis says yes). Turn it off when TAA is on
  (High) or accept a slight shimmer.
- Risk: medium (thin lines can shimmer on grass).
- Done when: Louis has seen on/off screenshots and chosen.

**W6. Skid marks and better tyre dust** (Session 68)
- Louis sees: when you brake hard, two short dark skid lines on the road that fade after 20 s. Dust
  puffs are softer and lit by the sun.
- How: `tyre_dust.gd`: on hard braking (the existing `_brake_left`), drop Decals (or a thin quad
  strip) every 0.3 m, at most 30 alive, fading with `modulate.a` over 20 s. Dust material: lit, soft
  circle, size 0.22 → 0.6 m.
- Done when: the test brakes hard and finds skid marks that are gone after 20 s.

**P5. Key icons instead of letters** (Session 70)
- Louis sees: "E" and "Q" drawn as little rounded keycaps (on touch: the button icons), not "E accept".
- How: a tiny `keycap.gd` Control used by the phone and the hold ring (H5 can copy the same drawing).

**S6. Bigger touch buttons** (Session 71, only if time)
- Louis sees on the iPad: round, see-through buttons with icons (pedal, brake, bell, F, E), at least 72
  px (44 pt) with spacing, and a press flash.
- How: touch_controls.gd styles only (keep the layout the touch test checks, 4 viewport sizes).

## 4. The sessions, and who owns which files

The polish pass is **one small groundwork session (66) first**, then **five sessions (67 to 71) built at the
same time by separate agents**, then **a play-test (72)**. The groundwork exists so that the five
don't all need to edit the same files: it adds the shared helpers and empty hooks they need.

### Shared-file rules (all sessions)
- `scripts/game_config.gd`: only add a new section at the **end**, headed
  `# --- Session NN: <name> ---`. (Merge: keep both sections.)
- `tools/build-web.sh`: add your suite name to the `for suite in (...)` list. (Merge: keep both names.)
- `tests/smoke_test.gd`: add **one** check function at the end of the file plus one call. (Merge: keep both.)
- `CREDITS.md`: add lines only. Nothing in this plan needs downloads except optionally the Kenney
  Particle Pack (CC0).
- **Don't edit** PRD.md, BUILD_PLAN.md, PROGRESS.md. Write `docs/session_notes/sNN.md`.
- **No map data changes.** Nothing here touches `tools/build_wahat_data.py` or the data files (W3 and W4
  only read them).
- **Adding things to the game world:** don't edit `wahat_al_shams.tscn` or `wahat_builder.gd`. Put a
  file in `scripts/polish/` with the name Session 66 reserved for you. The `PolishHooks` autoload
  calls its `static func attach(world: Node)` once when the world opens (in the game and in tests).
- **Settings:** only Session 71 edits `settings_panel.gd`. Everyone reads `Settings.text_size`,
  `Settings.colour_assist`, `Settings.reduce_motion`, `Settings.minimap_north_up`, `Settings.outlines`
  (made in 66).
- **Colours, sizes, motion:** use `UiPalette` and `UiJuice` (made in 66). Don't copy the TEAL/ORANGE
  constants into new files.
- **Sounds:** call `UiSounds.play("key")`. If the sound file doesn't exist yet (Session 71 makes them),
  it does nothing.

### Session 66: Polish groundwork (built first, by the lead or one agent, about 1 hour)
Owns (new): `scripts/polish_hooks.gd` (autoload `PolishHooks`), `scripts/polish/` (folder with a
README line), `ui/palette.gd` (`class_name UiPalette`), `scripts/ui_juice.gd` (`class_name UiJuice`),
`scripts/ui_sounds.gd` (autoload `UiSounds`), `tests/polish_groundwork_test.gd`.
Edits: `project.godot` (2 autoload lines), `scripts/settings.gd` (5 new saved values and text size),
`scripts/game_config.gd` (section "Session 66: polish groundwork" with all the polish flags).
Exact code: Appendix C.
Tests: new `polish_groundwork_test` (hooks call a test part, palette colours match the PRD hex codes,
UiJuice tweens finish while paused, settings round-trip, UiSounds ignores missing keys) + smoke.

### Session 67: Sky, light and colour (L1, L2, L3, L4, L5, L6, L7, L8)
Owns: `scripts/sun_cycle.gd`, new `scripts/sky_look.gd`, new `scripts/light_shafts.gd`, new
`scripts/polish/look_extras.gd`, new `assets/shaders/sky_stylized.gdshader`,
`screen_grade.gdshader`, `light_shaft.gdshader`, `outline_post.gdshader`, new `assets/luts/*`, new
`tools/make_luts.py`, new `tests/look_polish_test.gd`.
Doesn't touch: any UI file, water, particles.
Existing tests to run: smoke, grass, detail_world, static_batch, interior, layout.
New test `look_polish_test`: the aniso level per Graphics setting, the sky material and clouds per level,
the LUT set (and none with "neutral"), the vignette layer below the HUD, SSIL only on High, the shafts
count ≤ 24 and none on Low, every shaft inside its room box, flags off = old look.
Renders: Plaza and spine at 8.5, 12 and 17.5 h, before and after; one interior at 9 h; both LUTs.

### Session 68: Water, beam, road wear and particles (W1, W2, W3, W4, W5, W6)
Owns: `assets/shaders/water.gdshader` (+ keeps `water_v1.gdshader`), `scripts/pool.gd` (**one line**:
the `kind` uniform), `scripts/ambient_motion.gd` (**only** the fountain's water material line, if
needed), `scripts/delivery_manager.gd` (**only** `_make_marker()` and the two marker calls in
`_on_stage_changed`), new `scripts/arrival_marker.gd`, `assets/shaders/beam.gdshader`,
`scripts/tyre_dust.gd`, new `scripts/road_decals.gd`, `scripts/vfx_ambient.gd`,
`scripts/vfx_bursts.gd`, `scripts/polish/world_extras.gd`, new `tools/make_decals.py`,
`tools/make_vfx_textures.py`, new `assets/textures/decals/*`, `assets/textures/vfx/*`, new
`tests/world_polish_test.gd`.
Existing tests to run: smoke, pool, spine, layout, coplanar, lifecycle_regression, replay,
navigation.
New test `world_polish_test`: marker colours and burst per stage, the old marker with MARKER_V2 off;
water material `kind` on pools; decals per level within budget and each on a road or car-park rectangle;
particle totals per level within `VFX_MAX_PARTICLES`; steam at a hot-food pick-up; confetti on a 5-star
delivery; skid marks fade.
Renders: a junction with wear, a car park, the stream at 10 h, the community pool at 12 h, the fountain at 17 h,
the beam at a villa (pick-up orange and drop-off teal).

### Session 69: HUD, meters, clock and shift summary (H1, H2, H3, H4, H5, H6, H7)
Owns: `scripts/hud.gd`, `ui/hud.tscn`, `scripts/meters_panel.gd`, `ui/meters_panel.tscn`,
`scripts/shift_screen.gd`, `scripts/speed_lines.gd`, `scripts/follow_camera.gd` (**only** the shake,
FOV and speed-line parts), new `scripts/hud_chips.gd`, `scripts/hold_ring.gd`,
`scripts/polish/hud_extras.gd` (if needed), new `assets/ui/icons/*` (made by a script), new
`tests/hud_polish_test.gd`.
Existing tests to run: smoke, gear_ride, replay_ui, lifecycle_regression, housing_camera,
touch_controls, crash_impact.
New test `hud_polish_test`: no overlapping HUD rectangles at 4 window sizes × text 100% and 130%;
count-up ends on the right number; "+N" float made; temperature and progress at 3 hours; meter band
change gives one pulse and the right word; colour-assist colours; reduce-motion stops shake; hold
ring follows the hold; summary count-up ends on the summary values; E skips.
Screenshots: gameplay HUD with an order at 1280x720 and 1024x768 (Low).

### Session 70: Phone app and mini-map (P1, P2, P3, P4, P5)
Owns: `scripts/phone.gd`, `ui/phone.tscn`, `scripts/minimap.gd`, `ui/minimap.tscn`,
`scripts/profile_page.gd`, `scripts/gps_route.gd`, new `scripts/countdown_ring.gd`,
`scripts/phone_offer_card.gd`, `scripts/keycap.gd`, `scripts/polish/phone_extras.gd` (if needed),
new `tests/phone_polish_test.gd`.
Existing tests to run: smoke, phone_refresh, minimap_cache, replay_ui, reception_panel,
lifecycle_regression, touch_controls.
New test `phone_polish_test`: no label under 16 px; the 4 modes; the ring value over time
(paused time doesn't count); slide-in ends at 0; two-card choice mode; live distance text; mini-map
zoom at 0 and 36 km/h; edge arrow for a far target; north-up keeps north up; header money hidden
when HUD_TOP_CHIPS.
Screenshots: offer card, the to-villa view, two-order choice, mini-map heading-up and north-up.

### Session 71: Screens, menus, sounds and accessibility (S1, S2, S3, S4, S5, S6)
Owns: `scripts/delivered_card.gd`, `scripts/start_screen.gd`, `scripts/loader.gd`,
`scripts/clinic_screen.gd`, `scripts/pause_menu.gd`, `ui/pause_menu.tscn`, `scripts/settings_panel.gd`,
`ui/side_panel.gd`, `scripts/counter_panel.gd`, `ui/theme.tres`, `scripts/touch_controls.gd` (styles
only), `tools/make_sounds.py` and the new wav files, new `scripts/menu_diorama.gd`,
`assets/shaders/pause_blur.gdshader`, new `tests/screens_polish_test.gd`.
Existing tests to run: smoke, loading, replay_ui, reception_panel, lifecycle_regression,
touch_controls, shop, crash_impact.
New test `screens_polish_test`: Delivered card sequence order and E skip, `closed` once, no DOF left
after; settings rows set/save/reload each option; content scale changes; start screen builds with
and without the diorama; every UiSounds key has a file; pause blur only while paused; clinic count-up
ends on the bill.
Screenshots: start screen (both modes), loading screen, Delivered card (perfect and 3 stars),
pause menu, Settings → Accessibility, clinic.

### Session 72: Play-test the polish pass (one agent, after merging 67 to 71)
Merge order: 66 (already in), then 67, 68, 69, 70, 71 (the UI ones last because they share the most
tests). After each merge: regenerate nothing (no data changes), re-run the smoke and that session's
suites. Then: all suites, the play-test bot careful and careless, a frame-rate check on Louis's Mac
(Low, Medium, High at 1920x1080), the browser build on the iPad, screenshots of everything above,
and Louis's choices (section 6).

### Merge-risk table

| Shared file | Who touches it | How to merge |
| --- | --- | --- |
| scripts/game_config.gd | all | each adds its own end section: keep all |
| tools/build-web.sh | 66 to 71 | one suite name each: keep all |
| tests/smoke_test.gd | 66 to 71 | one check function each at the end: keep all |
| CREDITS.md | 68 (maybe), 71 (sounds are ours: one line) | keep all lines |
| scripts/follow_camera.gd | 69 (shake/FOV); 71 only reads `get_viewport().get_camera_3d()` to set DOF attributes at runtime, no file edit | no conflict |
| scripts/delivery_manager.gd | 68 only (`_make_marker`) | no conflict |
| ui/theme.tres | 71 only | others style in code with UiPalette |
| scripts/settings.gd | 66 only | 71 edits settings_panel.gd, not settings.gd |

### Release-run time
The browser release run must finish in 15 minutes. Each new focused suite must run in under 60 s
(build only what it checks: e.g. HUD tests use the flat test area or bare UI nodes, not the whole map,
where possible). If the run gets too long, Session 72 merges the 5 new suites into 2.

## 5. Cost summary for Low (iPad, browser), Medium and High

| Item | Low (Compatibility) | Medium (Mac) | High (Mac) |
| --- | --- | --- | --- |
| L1 aniso / debanding | 4x / no | 16x / yes | 16x / yes |
| L2 sky | gradient + sun | + clouds | + clouds |
| L3 LUT | yes | yes | yes |
| L4 vignette | yes | yes | yes |
| L5 SSIL / web SSAO | no / maybe (flag) | no | SSIL |
| L6 light shafts | no | yes (≤ 24) | yes |
| L7 cloud shadows | no | yes | yes |
| L8 outlines | off | off (Louis) | off (Louis) |
| W1 beam | yes | yes | yes |
| W2 water | foam, no caustics | full | full |
| W3 decals | half, fade 20 m | full, 35 m | full, 35 m |
| W4 particles | 150 max | 600 | 1200 |
| W5 bursts | yes | yes | yes |
| W6 skid marks | 10 | 30 | 30 |
| UI items | all | all | all |
| S1/S4 depth of field | no (Compatibility has none) | yes | yes |

Web size: LUTs about 50 KB each, decals about 300 KB, VFX textures about 100 KB, new sounds under 400 KB.
The web build must stay under 25 MB.

## 6. Choices for Louis

1. **Colour grade:** "Golden" (warm, sunset-y all day) or "Fresh" (cleaner, bright)? Session 67
   makes before/after pictures of both.
2. **Outlines** (L8): try thin comic outlines on the Mac, yes or no? Default: no.
3. **Wallet, rating and level** at the top left like the mockup (H1), and a lighter phone? Default:
   yes (it's the mockup).
4. **Mini-map:** keep "turns with you" as the default (with a North-up option)? Default: yes.
5. **Start screen:** the 3D bike-and-villa scene (S4), or keep the desert? Default: the 3D scene.
6. **Temperature** on the clock ("41°C"), just for fun? Default: yes.
7. **Moving cloud shadows** (L7) and **light shafts** (L6): keep them if they look good on his Mac.

## Appendix A: Draft PRD section (paste into PRD.md after "Looks pass")

```markdown
## Polish pass (Sessions 66 to 72)

After the Looks pass, Louis asked for better graphics and a better UI everywhere. Research (Nov 2026)
on Schedule I, cosy and delivery games, driver apps, game-feel talks, accessibility guidelines and
Godot 4's own docs is in docs/polish_plan.md. Everything new can be switched off with a GameConfig
setting, and nothing old is deleted.

**Light and colour**
- A cartoon sky with soft, slow clouds and a glowing sun. Clouds are peach in the morning, white at
  noon and gold and pink at sunset. (Low: no clouds.)
- A colour grade: sunny parts warm, shade a little teal, like a film. Louis picks "Golden" or "Fresh".
- Sharper ground into the distance (16x texture filtering on Medium and High), no stripes in the sky.
- Soft dark corners on the screen (vignette).
- On High: warm light bouncing off the sand onto walls.
- Soft sunbeams with dust through shop windows and Plaza passages, strongest in the morning and late
  afternoon (not on Low).
- Maybe: cloud shadows sliding over the ground; thin comic outlines (off unless Louis wants them).

**Details in the world**
- The delivery beam: a soft light column with rising sparkles and a pulsing ring on the ground.
  Orange for pick-up, teal for drop-off. It bursts when you arrive.
- Water: foam where it meets the edges, deeper colour in the middle, sun sparkles, and moving light
  patterns on the pool tiles.
- Road wear: tyre marks at junctions, oil spots in car parks, manholes and drains, a few cracks, sand
  blown onto road edges, "SLOW / ببطء" painted near the school.
- Little life in the air: steam from hot food and kitchen vents, fountain spray, falling leaves,
  sprinklers, splashes, and sand blowing across the ring road (fewer on Low).
- A confetti burst at the door for a 5-star delivery, coins for a tip, a ring of light on level-up.
- Skid marks when you brake hard.

**HUD (copies the mockup)**
- Top left: three chips, Wallet, Rating and Level (with an XP bar and your 5-star streak). Money counts
  up with a green "+15".
- Top middle: the clock with "Shift 3 · 41°C · today's special" and a shift progress bar.
- Bottom middle: the three meters with icons, words (On time / A bit late / Late...) and tick marks.
  When one drops into a worse colour it flashes and blips.
- Bottom right: speed and a stamina bar in 5 segments.
- A round "hold E" ring in the middle of the screen while you hold E.
- The shift summary counts up row by row with goal stamps and "New best!" ribbons.

**Phone and mini-map**
- Bigger text (at least 18 px at 1080p for normal text) and one clear "what now" line. Goals fold into a
  small "Goals 1/2" row. Wallet and stars moved to the HUD chips.
- New orders slide in as a card: big pay, distance and minutes, a pick-up → drop-off line, and a ring
  round the E key that runs down over the 30 seconds.
- After you accept: TO RESTAURANT / TO CUSTOMER, the place name big and the live distance.
- Mini-map: a compass ring, restaurant logo pins, an arrow on the edge when the stop is off the map,
  zooms out a little when you go fast. Option: North up.

**Screens, sounds and accessibility**
- Delivered card: tiles flip in one by one, stars pop with rising dings, the pay counts up, a
  "PERFECT!" stamp, the XP bar fills. E skips. On the Mac the background goes softly out of focus.
- Start screen: a small 3D scene (a villa corner, palms, your rider by the Snackaroo bike) at golden
  hour behind the title. The title bounces in. The loading screen has a little rider pedalling
  along the bar.
- Pause: the game behind goes blurry. Clinic bills count up. Shop and counter panels slide in.
- Soft UI sounds: hover, click, open, close, money ticks, a warning blip, a level-up fanfare. All made
  by our own script.
- Settings → Accessibility: Text size (100 / 115 / 130%), Colour help (blue, orange and vermilion plus
  patterns, never colour alone), Less motion (no shaking, speed lines or zoom), Mini-map (turns with
  you / North up).
```

## Appendix B: Decisions-log line (paste into PRD.md "Decisions log")

```markdown
| 4 Nov 2026 | Polish pass planned (Sessions 66 to 72) after the Looks pass: a groundwork session, then 5 sessions built in parallel (sky, light and colour grade; water, beam, road wear and particles; HUD like the mockup with top-left chips, a temperature clock, meters with icons and words; a clearer phone with an offer card and countdown ring, and a nicer mini-map; screens, UI sounds and accessibility settings), then a play-test. Louis picks the colour grade (Golden or Fresh) and whether to try outlines. All new things are behind GameConfig settings; nothing old is deleted |
```

## Appendix C: Session 66 groundwork code (exact)

`project.godot` `[autoload]`, add after Loader:
```
PolishHooks="*res://scripts/polish_hooks.gd"
UiSounds="*res://scripts/ui_sounds.gd"
```

`scripts/polish_hooks.gd`:
```gdscript
extends Node
## Session 66: lets each polish session add its extras to the game world without editing the
## same files. When the world scene opens (in the game or in a test), every file in PARTS that
## exists is loaded and its `static func attach(world: Node) -> void` is called once.
## The names are fixed here so parallel sessions never edit this list.

const WORLD_SCENE := "res://scenes/wahat_al_shams.tscn"
const PARTS := [
	"res://scripts/polish/look_extras.gd",   # Session 67
	"res://scripts/polish/world_extras.gd",  # Session 68
	"res://scripts/polish/hud_extras.gd",    # Session 69
	"res://scripts/polish/phone_extras.gd",  # Session 70
	"res://scripts/polish/screen_extras.gd", # Session 71
]

## Which parts ran for the last world (tests read it).
var attached: Array[String] = []


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node.scene_file_path == WORLD_SCENE:
		_attach.call_deferred(node)


func _attach(world: Node) -> void:
	if not is_instance_valid(world) or not world.is_inside_tree():
		return
	attached.clear()
	if not GameConfig.POLISH_HOOKS_ON:
		return
	for path in PARTS:
		if not ResourceLoader.exists(path):
			continue
		var part: Script = load(path)
		part.call("attach", world)  # the part's static func attach(world)
		attached.append(path)
```
(Check in the test that `ResourceLoader.exists` finds `.gd` files in an exported build. Godot remaps
them, so it does. The release run proves it in the browser.)

`ui/palette.gd`:
```gdscript
class_name UiPalette
extends RefCounted
## Session 66: the game's UI colours, text sizes and timings in one place (PRD "Screens").

const TEAL := Color("0F4C5C")
const ORANGE := Color("F28C28")
const SUN := Color("F2B230")
const SAND := Color("F3E3C3")
const INK := Color("1B1D22")
const PANEL := Color(0.0588, 0.1255, 0.149, 0.86)   # #0F2026 at 86%
const SOFT_TEXT := Color("C9E4EA")
const CYAN := Color("7FD3E0")
# Meter bands: normal and colour help (Okabe-Ito).
const BAND := [Color("4CC98A"), Color("F59A2E"), Color("E5483A")]
const BAND_ASSIST := [Color("0072B2"), Color("E69F00"), Color("D55E00")]
# Text sizes at the 1920x1080 base (XAG 101: PC body text at least 18 px at 1080p).
const FONT_SMALL := 16   # only for tags and captions
const FONT_BODY := 18
const FONT_LABEL := 20
const FONT_TITLE := 28
const FONT_BIG := 48
# Motion (Material 3 durations): button feedback, panels, big reveals.
const FAST := 0.12
const PANEL_TIME := 0.3
const REVEAL := 0.6

## 0 = good (green), 1 = okay (orange), 2 = bad (red), following the Colour help setting.
static func band_colour(band: int) -> Color:
	var colours: Array = BAND_ASSIST if Settings.colour_assist else BAND
	return colours[clampi(band, 0, 2)]
```

`scripts/ui_juice.gd` (static helpers; every tween keeps running while paused):
```gdscript
class_name UiJuice
extends RefCounted
## Session 66: small UI animations used by every screen. They all run while the game is paused,
## and "Less motion" (Settings.reduce_motion) turns shakes off and makes pops quicker.

static func _tween(node: Node) -> Tween:
	return node.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

## Grows from 80% with a little overshoot.
static func pop_in(c: Control, time := UiPalette.PANEL_TIME) -> Tween:
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2.ONE * 0.8
	var t := _tween(c)
	t.tween_property(c, "scale", Vector2.ONE, time * (0.5 if Settings.reduce_motion else 1.0)) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t

## Squash on click: 95% then back.
static func press(c: Control) -> Tween:
	c.pivot_offset = c.size * 0.5
	var t := _tween(c)
	t.tween_property(c, "scale", Vector2.ONE * 0.95, UiPalette.FAST * 0.5)
	t.tween_property(c, "scale", Vector2.ONE, UiPalette.FAST).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t

## Counts a number up on a label: fmt like "%d Dh".
static func count_up(label: Label, from: float, to: float, time := UiPalette.REVEAL, fmt := "%d") -> Tween:
	var t := _tween(label)
	t.tween_method(func(v: float): label.text = fmt % roundi(v), from, to, time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return t

## Shakes sideways (does nothing with Less motion).
static func shake(c: Control, pixels := 4.0, time := 0.25) -> Tween:
	var t := _tween(c)
	if Settings.reduce_motion:
		return t
	var start := c.position
	for i in 5:
		t.tween_property(c, "position:x", start.x + (pixels if i % 2 == 0 else -pixels) * (1.0 - i / 5.0), time / 6.0)
	t.tween_property(c, "position", start, time / 6.0)
	return t

## Slides in from an offset (e.g. Vector2(320, 0) = from the right).
static func slide_in(c: Control, offset: Vector2, time := UiPalette.PANEL_TIME) -> Tween:
	var end := c.position
	c.position = end + offset
	var t := _tween(c)
	t.tween_property(c, "position", end, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t
```

`scripts/ui_sounds.gd` (autoload `UiSounds`):
```gdscript
extends Node
## Session 66: UI sounds for menus and the HUD (works on the start screen and while paused).
## Session 71 makes the files with tools/make_sounds.py. A missing file just stays quiet.

const KEYS := ["ui_hover", "ui_click", "ui_open", "ui_close", "tick", "meter_warn",
		"level_up", "stamp", "whoosh"]
var play_counts: Dictionary = {}
var _players: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.load_once()
	for key in KEYS:
		var path := "res://assets/audio/%s.wav" % key
		if not ResourceLoader.exists(path):
			continue
		var p := AudioStreamPlayer.new()
		p.stream = load(path)
		p.bus = "Effects"
		add_child(p)
		_players[key] = p

func play(key: String, pitch := 1.0) -> void:
	play_counts[key] = play_counts.get(key, 0) + 1
	if _players.has(key) and Settings.can_play_audio():
		_players[key].pitch_scale = pitch
		_players[key].play()
```

`scripts/settings.gd`: add
```gdscript
const TEXT_SCALES := [1.0, 1.15, 1.3]
static var text_size := 0            # 0 = 100%, 1 = 115%, 2 = 130%
static var colour_assist := false
static var reduce_motion := false
static var minimap_north_up := false
static var outlines := false
```
load them in `load_once()` from section `"access"` (clamped), save them in `save()`, and in
`apply()` (not headless) set `tree.root.content_scale_factor = TEXT_SCALES[text_size]`.

`scripts/game_config.gd`, new section at the end:
```gdscript
# --- Session 66: polish groundwork ---
# Every polish-pass extra can be switched off here (false = the old look). Sessions 67 to 71
# add their own numbers in their own sections below.
const POLISH_HOOKS_ON := true
const HUD_TOP_CHIPS := true      # Session 69 chips at the top left; the phone hides its money and stars
const SKY_STYLIZED := true       # Session 67
const LOOK_LUT := "golden"       # Session 67: "golden", "fresh" or "neutral" (= off)
const VIGNETTE_STRENGTH := 0.22  # Session 67: 0 = off
const MARKER_V2 := true          # Session 68
const WATER_V2 := true           # Session 68
const ROAD_DECALS := true        # Session 68
const VFX_AMBIENT := true        # Session 68
const PHONE_V2 := true           # Session 70
const MINIMAP_V2 := true         # Session 70
const CARD_V2 := true            # Session 71
const START_DIORAMA := true      # Session 71
```

## Appendix D: BUILD_PLAN.md text (paste after Session 65)

```markdown
## Polish pass (Sessions 66 to 72)

Louis asked for better graphics and a better UI everywhere. Everything is in PRD.md, "Polish pass",
and the full plan with research, numbers, file ownership and tests is in
[docs/polish_plan.md](docs/polish_plan.md). Session 66 is small and goes first. Sessions 67 to 71
can be built at the same time by separate agents (each owns its own files, see the plan's section 4),
then Session 72 merges and play-tests. Same rules as always: headless checks, smoke test, focused tests,
a new test per session, screenshots, session notes, commit. Nothing old is deleted: every new thing
has a GameConfig switch.
```

### Session 66: Polish groundwork

```text
Session 66. Read docs/polish_plan.md sections 4 and Appendix C. Add exactly
the groundwork in Appendix C: the PolishHooks and UiSounds autoloads, the
scripts/polish/ folder, ui/palette.gd (UiPalette), scripts/ui_juice.gd
(UiJuice), the new saved settings (text size, colour help, less motion,
mini-map north up, outlines) with text size applied as the window's content
scale, and the "Session 66: polish groundwork" section in game_config.gd.
Don't change how anything looks yet. Add tests/polish_groundwork_test.gd.
Smoke test, then commit, before Sessions 67 to 71 start.
```

Done when:

- [ ] The game looks and plays exactly as before
- [ ] polish_groundwork_test and the smoke test pass
- [ ] Settings saved with the new values load again after a restart

### Session 67: Sky, light and colour

```text
Session 67. Read PRD.md "Polish pass" (Light and colour) and docs/polish_plan.md
items L1 to L8 and Session 67's file list (only edit those files). 1) 16x
texture filtering on Medium/High and debanding on the Mac. 2) Our own
stylised sky shader with soft cartoon clouds and a sun disc, coloured from
LIGHT_KEYS, no clouds on Low, clouds skipped in the lighting pass. 3) Make
"golden" and "fresh" 3D LUTs with tools/make_luts.py and use one as the
colour grade. 4) A soft vignette under the HUD. 5) SSIL on High. 6) Light
shafts through shop glass and Plaza passages (Medium/High). 7) Try cloud
shadows and depth-only outlines, both off by default. Renders before and
after at 8:30, 12:00 and 17:30, both LUTs, outlines on/off.
```

Done when:

- [ ] The sky has soft clouds that change colour through the day (none on Low)
- [ ] Ground stays sharp far ahead on the Mac
- [ ] Louis has picked Golden or Fresh, and said yes or no to outlines
- [ ] 60 fps on Medium on Louis's Mac; the browser still smooth on the iPad

### Session 68: Water, beam, road wear and particles

```text
Session 68. Read PRD.md "Polish pass" (Details in the world) and
docs/polish_plan.md items W1 to W6 and Session 68's file list. 1) The new
delivery beam (soft column, sparkles, pulsing ring, orange pick-up / teal
drop-off, burst on arrival). 2) Water with edge foam, depth colour, sun
glints and pool caustics. 3) Road wear decals and sand drifts, placed from
the map data (read only), fewer on Low. 4) Ambient particles (steam, spray,
leaves, sprinklers, splashes, sand wisps) within the particle budget.
5) Confetti, coins and a level-up ring in the world. 6) Skid marks.
Renders of a junction, a car park, the stream, the pool, the fountain and
the beam.
```

Done when:

- [ ] The beam is easy to see and shows orange for pick-up, teal for drop-off
- [ ] Water has foam at the edges and pools shimmer
- [ ] Roads look used (marks, sand) but nothing floats or shows on grass or walls
- [ ] Particle numbers stay in budget on Low, Medium and High

### Session 69: HUD, meters, clock and shift summary

```text
Session 69. Read PRD.md "Polish pass" (HUD) and docs/polish_plan.md items
H1 to H7 and Session 69's file list. Copy the mockup: wallet, rating and
level chips at the top left (money counts up, "+15" floats), the clock with
temperature, today's special and a shift progress bar, the meters at the
bottom middle with icons, words and tick marks that flash and blip when they
drop a band, a tidy speed and segmented stamina panel, a hold-E ring in the
middle of the screen, Less motion respected by the camera and speed lines,
and the shift summary counting up with stamps. Use UiPalette, UiJuice and
UiSounds. Check no panels overlap at 1280x720, 1920x1080, 1024x768 and
2732x2048 at text sizes 100% and 130%.
```

Done when:

- [ ] The HUD looks like the mockup: chips top left, clock top middle, meters bottom middle
- [ ] A meter turning orange is easy to notice, even with Colour help on
- [ ] Nothing overlaps on the iPad at 130% text

### Session 70: Phone app and mini-map

```text
Session 70. Read PRD.md "Polish pass" (Phone and mini-map) and
docs/polish_plan.md items P1 to P5 and Session 70's file list. Make the phone
readable (18 px body text, one clear "what now" line, goals folded, money
and stars moved to the HUD chips when HUD_TOP_CHIPS is on), the offer card
(big pay, distance and minutes, a pick-up to drop-off line, a countdown ring
round E, slide-in), the job view with live distance, and the mini-map
(compass ring, logo pins, edge arrow with distance, zoom with speed,
North-up option). Keep every name the existing phone and mini-map tests use.
```

Done when:

- [ ] You can read the phone at a glance while riding
- [ ] The countdown ring runs down over 30 seconds and the offer slides in
- [ ] The mini-map shows where to go even when the stop is far away; North up works

### Session 71: Screens, menus, sounds and accessibility

```text
Session 71. Read PRD.md "Polish pass" (Screens, sounds and accessibility) and
docs/polish_plan.md items S1 to S6 and Session 71's file list. The Delivered
card reveal (tiles, rising star dings, count-up, PERFECT stamp, XP bar, E to
skip, background blur on the Mac), Settings → Accessibility (text size,
colour help, less motion, mini-map), UI sounds made by tools/make_sounds.py
and button hover/press feel in the theme, the 3D start-screen scene with the
bouncing title, the loading-screen rider, the blurred pause menu, the clinic
count-up and sliding side panels. Keep the old start screen behind
START_DIORAMA.
```

Done when:

- [ ] A perfect delivery feels like a reward (stamp, dings, count-up) and E skips it
- [ ] Settings has Text size, Colour help, Less motion and Mini-map, and they're saved
- [ ] Menus click and whoosh; the start screen shows the 3D scene

### Session 72: Play-test the polish pass

```text
Session 72. Merge 67 to 71 in order (see docs/polish_plan.md section 4),
re-running the smoke test and each session's suites after each merge. Then
run everything, the play-test bot careful and careless, the frame-rate check
on Low, Medium and High at 1920x1080, and the browser build on the iPad.
Screenshots of the gameplay HUD, phone states, Delivered card, shift summary,
start and loading screens, Settings, and the world at 8:30, 12:00 and 17:30.
Ask Louis the choices in section 6 and set the GameConfig switches. Then
I'll play it myself; here's what felt off: [write it here].
```

Done when:

- [ ] All tests pass and the release run stays under 15 minutes
- [ ] 60 fps on Medium on Louis's Mac; the browser smooth on the iPad
- [ ] Louis has played a full shift and is happy with the look and the screens

## Appendix E: Sources

- Godot docs: [Renderers and feature comparison](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html),
  [Environment and post-processing](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html),
  [Using decals](https://docs.godotengine.org/en/stable/tutorials/3d/using_decals.html),
  [3D antialiasing](https://docs.godotengine.org/en/stable/tutorials/3d/3d_antialiasing.html),
  [Advanced post-processing](https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html),
  [Viewport](https://docs.godotengine.org/en/stable/classes/class_viewport.html),
  [Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html),
  [Particles](https://docs.godotengine.org/en/stable/tutorials/3d/particles/index.html)
- Look: [How To Make Low Poly Look Good (Game Developer)](https://www.gamedeveloper.com/design/how-to-make-low-poly-look-good),
  [How we made Butter Royale look good enough to eat (Mighty Bear)](https://medium.com/mighty-bear-games/how-we-made-butter-royale-look-good-enough-to-eat-do-not-lick-your-screen-d56840fe4070)
- Schedule I reviews: [Notebookcheck](https://www.notebookcheck.net/Steam-This-game-looks-like-trash-but-gets-Overwhelmingly-Positive-reviews.977584.0.html),
  [PC Gamer](https://www.pcgamer.com/games/sim/you-may-act-like-walter-white-and-look-like-rick-and-morty-but-this-drug-dealer-sim-blowing-up-on-steam-isnt-just-a-goofy-meme-game)
- Shaders: [Simplest outline (CC0)](https://godotshaders.com/shader/the-simplest-outline-shader-via-material/),
  [Fake Godrays (CC0)](https://godotshaders.com/shader/fake-godrays-godot-4-2/),
  not used (MIT): [post-process outline](https://godotshaders.com/shader/high-quality-post-process-outline-fixed-for-4-3),
  [Stylized Sky](https://godotshaders.com/shader/stylized-sky/),
  [Stylized Water](https://godotshaders.com/shader/stylized-water-for-godot-4-x)
- Assets: [Kenney Particle Pack (CC0), Godot Asset Library](https://godotengine.org/asset-library/asset/784)
- UI motion: [Material 3 motion tokens](https://github.com/material-components/material-web/blob/main/tokens/versions/v0_192/_md-sys-motion.scss),
  ["Juice it or lose it" (Jonasson and Purho)](https://www.youtube.com/watch?v=Fy0aCDmgnxg),
  ["The art of screenshake" (Nijman)](https://www.youtube.com/watch?v=AJdEqssNZ-U)
- Driver apps: [Offer card redesign case study](https://contra.com/p/eUcrB3Ao-uber-driver-offer-card-experience-redesign),
  [New driver app (earnings after each trip)](https://www.uber.com/blog/introducing-the-new-driver-app/)
- Delivery grading: [Death Stranding delivery score (Twinfinite)](https://twinfinite.net/guides/death-stranding-delivery-score-how-to-improve-what-it-is/)
- Mini-maps: [Minimap rotation (Game Developer)](https://www.gamedeveloper.com/design/minimap-rotation)
- Accessibility: [Game Accessibility Guidelines, basic](https://gameaccessibilityguidelines.com/basic/),
  [Xbox Accessibility Guideline 101: text display](https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-101-text-display.md)
