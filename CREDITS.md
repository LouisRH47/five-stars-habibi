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

**World polish pass road and track textures** (Sessions 61 to 63), made by
`tools/make_road_textures.py`:
- `assets/textures/asphalt_road_1k.jpg`: cut from Poly Haven's Asphalt 02 (CC0 1.0, above),
  keeping the part without long cracks and mirroring it so it tiles.
- `assets/textures/red_track_1k.jpg` and `assets/textures/bike_track_1k.jpg`: made for this
  game from random noise, CC0 (public domain).

The riding wind loop (assets/audio/wind_loop.wav) is original generated CC0 audio; reproduce it with tools/make_wind.py.

The PERFECT and tip jingles (assets/audio/perfect.wav and tip.wav) are original generated CC0 audio, reproduced by tools/make_sounds.py.
