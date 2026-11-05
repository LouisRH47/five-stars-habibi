# Blender scripts

Every model and texture made in Blender is built by a script here, so you can change a
number and rebuild it. They write into `assets/models/` (the .glb models) and
`assets/textures/` (the ground pictures).

Run them on your Mac (Blender installed):

    blender --background --python tools/blender/make_horse.py

or with plain Python, if the Blender module is installed (`pip install bpy`):

    python3 tools/blender/make_horse.py

After rebuilding, open the project in Godot once (or run
`Godot --path . --headless --import`) so it picks up the new files.

| Script | Makes |
| --- | --- |
| make_horse.py | horse_bay, horse_chestnut, horse_grey, horse_black, horse_palomino (.glb) |
| make_donkey.py | donkey_grey, donkey_brown (.glb) |
| make_playground.py | play_slide, play_climber, play_swings, play_spinner, play_springer (.glb) |
| make_textures.py | blue_track, red_track, horse_sand, pavers, play_surface, net (.png) |

`kit.py` and `equine.py` are shared helpers (shapes, materials, the horse/donkey body).
`out/` holds the coat pictures that go inside the horse files; it's not part of the game.

## The ground textures (assets/textures/)

All are 512 x 512 and tile with no seams. Use them with world-size UVs (triplanar), like
scripts/terrain_materials.gd does:

| File | What it's for | One picture covers |
| --- | --- | --- |
| blue_track.png | the blue cycle track | about 2 m |
| red_track.png | the red walking / running track | about 2 m |
| horse_sand.png | the horse track and the jumping arena sand | about 4 m |
| pavers.png | paved paths and plazas (20 x 10 cm blocks) | 1.6 m |
| play_surface.png | soft rubber playground floor | about 2 m |
| net.png | see-through sports netting (goal nets, the pitch fence) | 0.5 m |

All original work (made by these scripts), free to use.
