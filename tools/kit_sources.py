#!/usr/bin/env python3
"""Writes assets/kits/sources.json: where every free model pack came from (Session 56).

Usage: python3 tools/kit_sources.py
For each folder in assets/kits/ it records the pack, the maker, the licence (CC0 only),
the official page that says CC0, the exact download (git repository + commit + folder)
and the SHA-256 of every file we kept. Run it again after adding or removing files.
"""

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "assets" / "kits"
CHECKED = "2026-11-04"

KAYKIT = "https://github.com/KayKit-Game-Assets/"
KENNEY = {"repo": "https://github.com/shorepine/kenney", "commit": "3694c6879e487c108f55677be7dd2ca75b07cc3b",
          "note": "Mirror of Kenney's all-in-one CC0 library (glTF-binary models with their textures). "
                  "Its LICENSE.txt is Kenney's CC0 licence (copied here as License_kenney_cc0.txt)."}
KENNEY_OLD = ("Pack's own License.txt (older version of the same pack) from "
              "https://github.com/ETdoFresh/kenney.nl at 45df48c4d45f8716216b1a9e22df0b69cd9f5932")
QUAT = {"repo": "https://github.com/trebeljahr/quaternius-showcase", "commit": "c664c6f231d3dd522b38ba52fc39ec33028624e2",
        "note": "Mirror of the CC0 Quaternius packs as single .glb files (public/glb/). Its LICENSES.md "
                "(copied here as LICENSES_showcase.md) lists each pack's upstream page and CC0-1.0."}

PACKS = [
    {"folder": "kaykit_restaurant", "pack": "KayKit Restaurant Bits 1.0", "maker": "Kay Lousberg",
     "page": "https://kaylousberg.itch.io/restaurant-bits",
     "repo": KAYKIT + "KayKit-Restaurant-Bits-1.0", "commit": "153c8a7535b48237854cb54ff6890679f8c574d1",
     "path": "addons/kaykit_restaurant_bits/Assets/gltf", "licence_proof": "LICENSE.txt in the official repository says CC0"},
    {"folder": "kaykit_furniture", "pack": "KayKit Furniture Bits 1.0", "maker": "Kay Lousberg",
     "page": "https://kaylousberg.itch.io/furniture-bits",
     "repo": KAYKIT + "KayKit-Furniture-Bits-1.0", "commit": "96d5930a8dbdb363409bbc2d3341718b00e17c9c",
     "path": "addons/kaykit_furniture_bits/Assets/gltf", "licence_proof": "LICENSE.txt in the official repository says CC0"},
    {"folder": "kaykit_city", "pack": "KayKit City Builder Bits 1.0", "maker": "Kay Lousberg",
     "page": "https://kaylousberg.itch.io/city-builder-bits",
     "repo": KAYKIT + "KayKit-City-Builder-Bits-1.0", "commit": "63976910ca04d16f0fc531b9c614244be8128713",
     "path": "addons/kaykit_city_builder_bits/Assets/gltf", "licence_proof": "LICENSE.txt in the official repository says CC0"},
    {"folder": "kenney_food", "pack": "Kenney Food Kit", "maker": "Kenney", "page": "https://kenney.nl/assets/food-kit",
     **KENNEY, "path": "3d/food", "licence_proof": "kenney.nl page says 'Creative Commons CC0'; " + KENNEY_OLD},
    {"folder": "kenney_furniture", "pack": "Kenney Furniture Kit", "maker": "Kenney", "page": "https://kenney.nl/assets/furniture-kit",
     **KENNEY, "path": "3d/furniture", "licence_proof": "kenney.nl page says 'Creative Commons CC0'; " + KENNEY_OLD},
    {"folder": "kenney_nature", "pack": "Kenney Nature Kit", "maker": "Kenney", "page": "https://kenney.nl/assets/nature-kit",
     **KENNEY, "path": "3d/nature", "licence_proof": "kenney.nl page says 'Creative Commons CC0'; " + KENNEY_OLD},
    {"folder": "kenney_city_roads", "pack": "Kenney City Kit (Roads)", "maker": "Kenney", "page": "https://kenney.nl/assets/city-kit-roads",
     **KENNEY, "path": "3d/city-roads", "licence_proof": "kenney.nl page says 'Creative Commons CC0'"},
    {"folder": "kenney_city_commercial", "pack": "Kenney City Kit (Commercial)", "maker": "Kenney",
     "page": "https://kenney.nl/assets/city-kit-commercial",
     **KENNEY, "path": "3d/city-commercial", "licence_proof": "kenney.nl page says 'Creative Commons CC0'"},
    {"folder": "kenney_mini_market", "pack": "Kenney Mini Market", "maker": "Kenney", "page": "https://kenney.nl/assets/mini-market",
     **KENNEY, "path": "3d/mini-market", "licence_proof": "kenney.nl page says 'Creative Commons CC0'"},
    {"folder": "quaternius_nature", "pack": "Quaternius Ultimate Nature Pack (desert-friendly part: no snow, autumn, "
     "dead, birch, pine, willow or moss models)", "maker": "Quaternius",
     "page": "https://quaternius.com/packs/ultimatenature.html", **QUAT, "path": "public/glb/nature_pack",
     "licence_proof": "pack page says CC0"},
    {"folder": "quaternius_crops", "pack": "Quaternius Ultimate Crops Pack", "maker": "Quaternius",
     "page": "https://quaternius.com/packs/ultimatecrops.html", **QUAT, "path": "public/glb/crops_pack",
     "licence_proof": "pack page says CC0"},
    {"folder": "quaternius_animals", "pack": "Quaternius Ultimate Animated Animal Pack", "maker": "Quaternius",
     "page": "https://quaternius.com/packs/ultimateanimatedanimals.html", **QUAT, "path": "public/glb/animals_pack",
     "licence_proof": "pack page says CC0"},
    {"folder": "quaternius_men", "pack": "Quaternius Ultimate Modular Men Pack", "maker": "Quaternius",
     "page": "https://quaternius.com/packs/ultimatemodularcharacters.html", **QUAT, "path": "public/glb/modular_men",
     "licence_proof": "pack page says CC0"},
    {"folder": "quaternius_women", "pack": "Quaternius Ultimate Modular Women Pack", "maker": "Quaternius",
     "page": "https://quaternius.com/packs/ultimatemodularwomen.html", **QUAT, "path": "public/glb/modular_women",
     "licence_proof": "pack page says CC0"},
    {"folder": "quaternius_ual", "pack": "Quaternius Universal Animation Library 1 (Standard, free part, glTF for Godot)",
     "maker": "Quaternius", "page": "https://quaternius.com/packs/universalanimationlibrary.html",
     "repo": "https://github.com/J-Ponzo/gltf-universal-animation-library", "commit": "e24c23cf2a1323488a3faa226ea7ea21f644b73e",
     "path": "glTF", "note": "Mirror of the itch.io download (2025-06-10), glTF only, with the pack's CC0 LICENSE.",
     "licence_proof": "pack page says CC0; LICENSE in the mirror is the CC0 1.0 legal code"},
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    out = []
    for pack in PACKS:
        folder = ROOT / pack["folder"]
        files = {}
        for path in sorted(folder.rglob("*")):
            if path.is_file() and path.suffix != ".import":
                files[path.relative_to(folder).as_posix()] = sha256(path)
        out.append({**pack, "license": "CC0-1.0", "checked": CHECKED, "file_count": len(files), "files": files})
    (ROOT / "sources.json").write_text(json.dumps(out, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {ROOT / 'sources.json'}: {len(out)} packs, {sum(p['file_count'] for p in out)} files")


if __name__ == "__main__":
    main()
