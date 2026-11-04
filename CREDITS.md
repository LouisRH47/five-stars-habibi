# Credits

Everything in the game that was made by someone else, and the licence that lets us use it.

## Fonts

**Noto Sans Arabic** (used for every sign: Arabic and English)
- Copyright 2022 The Noto Project Authors
- Licence: SIL Open Font License 1.1 (free to use, also in games)
- File: `assets/fonts/NotoSansArabic.ttf`
- Licence text: `assets/fonts/OFL.txt`
- Source: https://github.com/notofonts/arabic

**Baloo 2** (titles and big numbers, Session 20)
- Copyright 2019 The Baloo 2 Project Authors
- Licence: SIL Open Font License 1.1
- File: `assets/fonts/Baloo2.ttf`, licence text: `assets/fonts/OFL-Baloo2.txt`
- Source: https://github.com/google/fonts/tree/main/ofl/baloo2

**Nunito** (all other text, Session 20)
- Copyright 2014 The Nunito Project Authors
- Licence: SIL Open Font License 1.1
- File: `assets/fonts/Nunito.ttf`, licence text: `assets/fonts/OFL-Nunito.txt`
- Source: https://github.com/google/fonts/tree/main/ofl/nunito

## Music and sounds

**All music and sound effects were made for this game** by the script
`tools/make_sounds.py` (Session 16): sine waves, noise and a plucked-string recipe
(Karplus-Strong), nothing sampled or copied. Free to use: CC0 (public domain).
- `assets/audio/music_loop.wav`: a chill loop in maqam Hijaz (oud-like pluck, darbuka
  maqsum rhythm, low drone)
- `assets/audio/ambience_loop.wav`: birds and distant traffic
- `assets/audio/bell.wav`, `cash.wav`, `crash.wav`, `ping.wav`, `bump.wav`, `roll_loop.wav`
- `assets/audio/ring.wav`: the bike bell you ring with B (Session 29)
- `assets/audio/buzz.wav`, `pop.wav`, `coins.wav`: the phone buzz and the Delivered card's
  star and coin pops (Session 31)
- `assets/audio/ui_hover.wav`, `ui_click.wav`, `ui_open.wav`, `ui_close.wav`, `tick.wav`,
  `meter_warn.wav`, `level_up.wav`, `stamp.wav`, `whoosh.wav`: the menu and HUD sounds
  (Session 71, original generated CC0 audio; remake only these with `python3 tools/make_sounds.py ui`)

To remake them: `python3 tools/make_sounds.py`.

## People and cars (Session 29)

**Animated Human** by Quaternius (every person: the rider, customers, teachers, kids,
riders and grooms)
- Licence: CC0 1.0 (public domain), licence text: `assets/characters/quaternius_human/License.txt`
- File: `assets/characters/quaternius_human/human.fbx` (only the FBX: the clothes are
  painted in code, so the original textures are not included)
- Source: https://opengameart.org/content/animated-human-low-poly (author: https://quaternius.com)

**Car Kit** (version 3.1) by Kenney (the parked cars in the car parks)
- Licence: CC0 1.0 (public domain), licence text: `assets/cars/kenney_car_kit/License.txt`
- Files: `assets/cars/kenney_car_kit/` (sedan, suv, suv-luxury, hatchback-sports, van and
  the shared `Textures/colormap.png`)
- Source: https://opengameart.org/content/car-kit (author: https://kenney.nl/assets/car-kit)

The bicycle, the hats, helmets, scarves, bags and shoes were built in code for this game
(CC0).


## Detail-pass terrain textures

Poly Haven, CC0 1.0, downloaded at 1K resolution on 3 November 2026.
Shared albedo textures tile in world metres. License: https://polyhaven.com/license

- Aerial Grass Rock: https://polyhaven.com/a/aerial_grass_rock
- Sand 01: https://polyhaven.com/a/sand_01
- Asphalt 02: https://polyhaven.com/a/asphalt_02
- Pavement 02: https://polyhaven.com/a/pavement_02

Exact download URLs and SHA-256 checksums: assets/textures/sources.json.

These photo textures are kept but no longer used (GameConfig.STYLIZED_TEXTURES = false brings
them back).

## The Schedule I look (Session 55)

- The painted ground textures in assets/textures/stylized/ (grass, sand, asphalt, paving and
  the red rubber track) were made for this game by tools/make_textures.py (CC0). Nothing was
  downloaded.
- The grass blades and their wind shader (assets/shaders/grass.gdshader, scripts/grass_field.gd)
  were written for this game (CC0), after the idea of the CC0 "Stylized Multimesh Grass" shader
  on godotshaders.com (tufts in a MultiMesh, swayed in the vertex shader). No code was copied.

The riding wind loop (assets/audio/wind_loop.wav) is original generated CC0 audio; reproduce it with tools/make_wind.py.

The PERFECT and tip jingles (assets/audio/perfect.wav and tip.wav) are original generated CC0 audio, reproduced by tools/make_sounds.py.

## Free model packs (Session 56)

All in `assets/kits/`, all **CC0 1.0** (public domain: free for anything, no credit needed, but
we say thank you anyway). Each folder keeps the pack's licence file. The exact downloads (git
repository, commit, folder) and the SHA-256 of every file are in `assets/kits/sources.json`
(remake it with `python3 tools/kit_sources.py`). Only the glTF/GLB models and the textures they
need were kept (no FBX, OBJ, Blender files or preview images).

**KayKit** by Kay Lousberg (https://www.kaylousberg.com), from the official GitHub repositories
(https://github.com/KayKit-Game-Assets)
- Restaurant Bits 1.0 (`kaykit_restaurant/`): https://kaylousberg.itch.io/restaurant-bits
- Furniture Bits 1.0 (`kaykit_furniture/`): https://kaylousberg.itch.io/furniture-bits
- City Builder Bits 1.0 (`kaykit_city/`): https://kaylousberg.itch.io/city-builder-bits

**Kenney** (https://kenney.nl), from the CC0 mirror https://github.com/shorepine/kenney
- Food Kit (`kenney_food/`): https://kenney.nl/assets/food-kit
- Furniture Kit (`kenney_furniture/`): https://kenney.nl/assets/furniture-kit
- Nature Kit (`kenney_nature/`): https://kenney.nl/assets/nature-kit
- City Kit (Roads) (`kenney_city_roads/`): https://kenney.nl/assets/city-kit-roads
- City Kit (Commercial) (`kenney_city_commercial/`): https://kenney.nl/assets/city-kit-commercial
- Mini Market (`kenney_mini_market/`): https://kenney.nl/assets/mini-market

**Quaternius** (https://quaternius.com). Only packs whose own page still says CC0 (Quaternius
uses a different licence for some new packs; none of those are here).
- Ultimate Nature Pack (`quaternius_nature/`, only the desert-friendly models):
  https://quaternius.com/packs/ultimatenature.html
- Ultimate Crops Pack (`quaternius_crops/`): https://quaternius.com/packs/ultimatecrops.html
- Ultimate Animated Animal Pack (`quaternius_animals/`):
  https://quaternius.com/packs/ultimateanimatedanimals.html
- Ultimate Modular Men and Women (`quaternius_men/`, `quaternius_women/`):
  https://quaternius.com/packs/ultimatemodularcharacters.html and
  https://quaternius.com/packs/ultimatemodularwomen.html
  (these four from the mirror https://github.com/trebeljahr/quaternius-showcase)
- Universal Animation Library 1, free Standard part (`quaternius_ual/`):
  https://quaternius.com/packs/universalanimationlibrary.html
  (glTF from the mirror https://github.com/J-Ponzo/gltf-universal-animation-library)
