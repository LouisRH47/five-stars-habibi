"""Keeps the browser build small: only the free-pack models the game really uses go in.

Session 56 left every pack (assets/kits/) out of the Web export, because the browser's
index.pck must stay under 25 MiB (Cloudflare Pages refuses bigger files). Session 58
started using some models inside the restaurants, so the Web build needs those.

This script looks through the game's scripts and data (scripts/*.gd, data/*.gd, but not
the catalogue data/kit_catalogue.gd, which lists every model) for model names like
"kenney_food/pizza", and writes the Web preset's exclude filter in export_presets.cfg:
- packs with no model in use are left out whole ("assets/kits/kenney_nature/*"),
- in packs that are used, every model nobody uses is left out by name.
Textures and .bin files of used packs stay in (the used models need them).

Run it again after using a new model (or after merging other sessions):
    python3 tools/web_kit_filter.py
Then measure the Web pack (see docs/session_notes/s58.md) and keep it under 25 MiB.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
KITS = ROOT / "assets" / "kits"
PRESETS = ROOT / "export_presets.cfg"
BASE = ["tests/*", "web/*", "docs/*", "build/*", ".cache/*", "tools/*", "scenes/kit_preview.tscn"]
MODEL_EXTS = (".glb", ".gltf")


def used_models():
    packs = {p.name for p in KITS.iterdir() if p.is_dir()}
    pattern = re.compile(r'"(%s)/([A-Za-z0-9_\-]+)"' % "|".join(sorted(packs)))
    found = set()
    files = list((ROOT / "scripts").glob("*.gd")) + [f for f in (ROOT / "data").glob("*.gd") if f.name != "kit_catalogue.gd"]
    for path in files:
        for pack, name in pattern.findall(path.read_text(encoding="utf-8")):
            found.add((pack, name))
    return found


def exclude_list(used):
    out = list(BASE)
    for pack in sorted(p for p in KITS.iterdir() if p.is_dir()):
        names = {name for p, name in used if p == pack.name}
        if not names:
            out.append("assets/kits/%s/*" % pack.name)
            continue
        for model in sorted(pack.iterdir()):
            if model.suffix in MODEL_EXTS and model.stem not in names:
                out.append("assets/kits/%s/%s" % (pack.name, model.name))
    return out


def main():
    used = used_models()
    missing = [f"{p}/{n}" for p, n in sorted(used) if not any((KITS / p / (n + e)).exists() for e in MODEL_EXTS)]
    text = PRESETS.read_text(encoding="utf-8")
    start = text.index('name="Web"')
    line = re.compile(r'^exclude_filter=".*"$', re.M)
    match = line.search(text, start)
    new = 'exclude_filter="%s"' % ",".join(exclude_list(used))
    text = text[:match.start()] + new + text[match.end():]
    PRESETS.write_text(text, encoding="utf-8")
    print("Web build keeps %d models from %d packs" % (len(used), len({p for p, _ in used})))
    for name in missing:
        print("  warning: no file for", name)


if __name__ == "__main__":
    main()
