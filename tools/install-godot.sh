#!/usr/bin/env bash
# Install the exact Linux engine and Web templates used for browser releases.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="4.7.2"
SDK="$ROOT/.cache/godot/$VERSION"
BINARY="$SDK/Godot_v${VERSION}-stable_linux.x86_64"
TEMPLATES="$SDK/editor_data/export_templates/${VERSION}.stable"
BASE_URL="https://github.com/godotengine/godot-builds/releases/download/${VERSION}-stable"
ENGINE_SHA="cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4"
TEMPLATES_SHA="f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011"

if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "x86_64" ]]; then
  echo "This installer targets Linux x86_64 CI. On a Mac, set GODOT_BIN to Godot 4.7.2 and run tools/build-web.sh." >&2
  exit 1
fi

mkdir -p "$SDK"
if [[ ! -x "$BINARY" || ! -f "$TEMPLATES/web_nothreads_release.zip" || ! -f "$TEMPLATES/web_nothreads_debug.zip" || ! -f "$SDK/.verified-downloads" ]]; then
  DOWNLOADS="$(mktemp -d "$SDK/downloads.XXXXXX")"
  trap 'rm -rf "$DOWNLOADS"' EXIT
  curl --fail --location --retry 3 --connect-timeout 30 --max-time 600 \
    "$BASE_URL/Godot_v${VERSION}-stable_linux.x86_64.zip" -o "$DOWNLOADS/engine.zip"
  curl --fail --location --retry 3 --connect-timeout 30 --max-time 1200 \
    "$BASE_URL/Godot_v${VERSION}-stable_export_templates.tpz" -o "$DOWNLOADS/templates.tpz"

  python3 - "$DOWNLOADS" "$SDK" "$VERSION" "$ENGINE_SHA" "$TEMPLATES_SHA" <<'PY'
import hashlib
import pathlib
import sys
import zipfile

downloads, sdk = map(pathlib.Path, sys.argv[1:3])
version, engine_sha, templates_sha = sys.argv[3:]
for name, expected in (("engine.zip", engine_sha), ("templates.tpz", templates_sha)):
    with (downloads / name).open("rb") as source:
        checksum = hashlib.sha256()
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            checksum.update(chunk)
        digest = checksum.hexdigest()
    if digest != expected:
        raise SystemExit(f"SHA-256 mismatch for {name}: refusing to install")
    print(f"Verified {name}: {digest}")

# Extract only known names, avoiding both unused platforms and archive path traversal.
binary_name = f"Godot_v{version}-stable_linux.x86_64"
with zipfile.ZipFile(downloads / "engine.zip") as archive:
    binary = sdk / binary_name
    binary.write_bytes(archive.read(binary_name))
    binary.chmod(0o755)

templates = sdk / "editor_data" / "export_templates" / f"{version}.stable"
templates.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(downloads / "templates.tpz") as archive:
    for name in ("version.txt", "web_nothreads_debug.zip", "web_nothreads_release.zip"):
        (templates / name).write_bytes(archive.read(f"templates/{name}"))
(sdk / "_sc_").touch()  # Godot self-contained mode keeps templates inside this SDK.
(sdk / ".verified-downloads").write_text(engine_sha + "\n" + templates_sha + "\n")
PY
fi

"$BINARY" --version
if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'GODOT_BIN=%s\n' "$BINARY" >> "$GITHUB_ENV"
fi
printf 'Godot ready: %s\n' "$BINARY"
