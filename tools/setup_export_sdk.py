"""Session 85: make the portable Godot copy that tools/build_desktop.py builds with.

Copies Godot.app into /private/tmp/habibi-export-sdk, marks it self-contained (so it never
touches your normal Godot settings) and puts the Mac, Windows and Linux export templates
inside it. The templates come from Godot's official file
Godot_v4.7.2-stable_export_templates.tpz (about 1.2 GB), checked against its known SHA-256.

    python3 tools/setup_export_sdk.py --templates ~/Downloads/Godot_v4.7.2-stable_export_templates.tpz
    python3 tools/setup_export_sdk.py --download   # fetches the .tpz from github.com/godotengine/godot-builds

This only prepares files on this Mac. It never uploads or publishes anything.
"""
from pathlib import Path
import argparse
import hashlib
import shutil
import subprocess
import sys
import zipfile

VERSION = '4.7.2'
# Same file and checksum as tools/install-godot.sh (the GitHub build).
TEMPLATES_SHA = 'f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011'
TEMPLATES_URL = (f'https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable/'
                 f'Godot_v{VERSION}-stable_export_templates.tpz')
NEEDED = ['version.txt', 'macos.zip', 'windows_release_x86_64.exe', 'linux_release.x86_64', 'icudt_godot.dat']
SDK = Path('/private/tmp/habibi-export-sdk')


def sha256(path):
    value = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            value.update(chunk)
    return value.hexdigest()


def find_godot():
    for place in [Path('/Applications/Godot.app'), Path.home() / 'Downloads/Godot.app']:
        if (place / 'Contents/MacOS/Godot').is_file():
            return place
    raise SystemExit('Godot.app not found in /Applications or ~/Downloads; pass --godot-app')


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--godot-app', type=Path, help='Godot.app to copy (default: /Applications or ~/Downloads)')
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument('--templates', type=Path, help='an already downloaded export_templates.tpz')
    source.add_argument('--download', action='store_true', help='download the official .tpz first')
    args = parser.parse_args()

    app = (args.godot_app or find_godot()).expanduser().resolve()
    version = subprocess.check_output([app / 'Contents/MacOS/Godot', '--version'], text=True).strip()
    if not version.startswith(VERSION + '.'):
        raise SystemExit(f'Expected Godot {VERSION}, found {version}')

    SDK.mkdir(parents=True, exist_ok=True)
    tpz = SDK / f'Godot_v{VERSION}-stable_export_templates.tpz'
    if args.download:
        if not tpz.is_file() or sha256(tpz) != TEMPLATES_SHA:
            subprocess.run(['curl', '--fail', '--location', '--retry', '3', '--connect-timeout', '30',
                            '--max-time', '3600', TEMPLATES_URL, '-o', tpz], check=True)
    else:
        tpz = args.templates.expanduser().resolve()
    digest = sha256(tpz)
    if digest != TEMPLATES_SHA:
        raise SystemExit(f'SHA-256 mismatch for {tpz.name} ({digest}): refusing to use it')
    print('Verified', tpz.name)

    copy = SDK / 'Godot.app'
    if copy.exists():
        shutil.rmtree(copy)
    # ditto keeps the app's signature and permissions.
    subprocess.run(['ditto', app, copy], check=True)
    (SDK / '_sc_').touch()  # self-contained: settings and templates live in SDK/editor_data
    templates = SDK / 'editor_data' / 'export_templates' / f'{VERSION}.stable'
    templates.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(tpz) as archive:
        names = set(archive.namelist())
        for name in NEEDED:
            member = f'templates/{name}'
            if member not in names:
                raise SystemExit(f'{member} is missing from {tpz.name}')
            target = templates / name
            target.write_bytes(archive.read(member))
            if name.endswith(('.x86_64', '.exe')):
                target.chmod(0o755)
    print('Ready:', copy / 'Contents/MacOS/Godot')


if __name__ == '__main__':
    sys.exit(main())
