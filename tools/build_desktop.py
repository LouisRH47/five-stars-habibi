"""Build the desktop games (Windows, Mac and Linux / Steam Deck) with one command, using a
portable Godot 4.7.2 SDK (make one with tools/setup_export_sdk.py).

Examples:
    python3 tools/build_desktop.py --godot /private/tmp/habibi-export-sdk/Godot.app/Contents/MacOS/Godot --output /private/tmp/habibi-desktop-review --verify-mac
    python3 tools/build_desktop.py --godot /private/tmp/habibi-export-sdk/Godot.app/Contents/MacOS/Godot --output /private/tmp/habibi-desktop --mode distribution

The default review mode redirects all user:// paths into output/userdata, so the
exported Mac app can be tested without reading or replacing the player's real save.
Those packages are deliberately marked REVIEW and are not distribution builds.
Use --mode distribution for portable saves; do not launch those on a real profile
as part of automated checks. This command never uploads or publishes anything.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import struct
import tarfile
import subprocess
import sys
import zipfile

SOURCE = Path(__file__).resolve().parents[1]
VERSION = '4.7.2'


def digest(path):
    value = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            value.update(chunk)
    return value.hexdigest()


def source_fingerprint(source):
    value = hashlib.sha256()
    for path in sorted(source.rglob('*')):
        if not path.is_file():
            continue
        relative = path.relative_to(source)
        if relative.parts[0] not in {'assets', 'data', 'scenes', 'scripts', 'ui'} and relative.name not in {'project.godot', 'export_presets.cfg', 'CREDITS.md'}:
            continue
        if path.suffix == '.import':
            continue
        value.update(str(relative).encode() + b'\0' + digest(path).encode())
    return value.hexdigest()


def run(command, log, timeout=600, strict=True):
    print('Running:', ' '.join(map(str, command)), flush=True)
    with log.open('w') as output:
        result = subprocess.run(list(map(str, command)), stdout=output, stderr=subprocess.STDOUT, timeout=timeout)
    text = log.read_text(errors='replace')
    if result.returncode or (strict and 'SCRIPT ERROR:' in text):
        print(text[-16000:], file=sys.stderr)
        raise SystemExit(f'Build check failed; see {log}')
    return text


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--source', type=Path, default=SOURCE)
    parser.add_argument('--mode', choices=['review', 'distribution'], default='review')
    parser.add_argument('--verify-mac', action='store_true', help='Launch the review export headlessly; never allowed for distribution mode')
    args = parser.parse_args()
    output = args.output.resolve()
    source = args.source.resolve()
    godot = args.godot.resolve()
    if not output.is_relative_to(Path('/private/tmp')) or output == Path('/private/tmp'):
        raise SystemExit('Use a dedicated /private/tmp output directory for these preview packages')
    if output == source or output.is_relative_to(source):
        raise SystemExit('Build output must be outside the source worktree')
    if args.verify_mac and args.mode != 'review':
        raise SystemExit('Mac launch checks require review mode to protect real player saves')
    if not godot.is_file():
        raise SystemExit('Godot executable not found')
    if not godot.is_relative_to(Path('/private/tmp')):
        raise SystemExit('Use a portable Godot SDK copy under /private/tmp')
    version = subprocess.check_output([godot, '--version'], text=True).strip()
    if not version.startswith(VERSION + '.'):
        raise SystemExit(f'Expected Godot {VERSION}, received {version}')
    # Godot 4.7.2 checks outside a macOS .app, then stores editor_data there.
    portable_root = godot.parents[3] if godot.parent.name == 'MacOS' else godot.parent
    if not any((portable_root / name).exists() for name in ['_sc_', '._sc_']):
        raise SystemExit('Use a self-contained SDK copy in /private/tmp; do not change the installed editor settings')
    templates = portable_root / 'editor_data' / 'export_templates' / (VERSION + '.stable')
    for template in ['macos.zip', 'windows_release_x86_64.exe', 'linux_release.x86_64', 'icudt_godot.dat']:
        if not (templates / template).is_file():
            raise SystemExit(f'Missing SDK export template: {templates / template}')
    output.mkdir(parents=True, exist_ok=True)
    userdata = output / 'userdata'
    userdata.mkdir(exist_ok=True)
    project = output / 'project'
    if project.exists():
        raise SystemExit('Output already contains a project snapshot; choose a fresh directory')
    shutil.copytree(source, project, ignore=shutil.ignore_patterns('.git', '.godot', '.claude', '__pycache__', 'build'))
    original_hash = source_fingerprint(project)
    if args.mode == 'review':
        for script in project.rglob('*.gd'):
            script.write_text(script.read_text().replace('user://', str(userdata) + '/'))
    # Only the private QA build embeds a temporary log path. Distribution builds
    # retain Godot's portable user:// default; CLI flags isolate the editor logs.
    if args.mode == 'review':
        settings = project / 'project.godot'
        settings.write_text(settings.read_text() + '\n[debug]\n\nfile_logging/log_path="' + str(output / 'game.log') + '"\n')
    prefix = [godot, '--headless', '--path', project, '--log-file', output / 'engine.log']
    # A fresh snapshot needs a class scan before autoloads and dynamic resources resolve.
    run(prefix + ['--import'], output / 'import.log', strict=False)
    run(prefix + ['--import'], output / 'import-verify.log')
    artifacts = output / 'artifacts'
    artifacts.mkdir(exist_ok=True)
    label = 'FiveStarsHabibi-REVIEW' if args.mode == 'review' else 'FiveStarsHabibi'
    mac_zip = artifacts / (label + '-macOS-universal.zip')
    run(prefix + ['--export-release', 'macOS', mac_zip], output / 'export-macos.log')
    windows = artifacts / (label + '-windows-x64')
    windows.mkdir(exist_ok=True)
    windows_exe = windows / 'Five Stars Habibi.exe'
    run(prefix + ['--export-release', 'Windows Desktop', windows_exe], output / 'export-windows.log')
    # Session 85: Linux (and the Steam Deck, which runs Linux).
    linux = artifacts / (label + '-linux-x64')
    linux.mkdir(exist_ok=True)
    linux_bin = linux / 'FiveStarsHabibi.x86_64'
    run(prefix + ['--export-release', 'Linux', linux_bin], output / 'export-linux.log')
    readme = ('PRIVATE REVIEW BUILD: user data is redirected to ' + str(userdata) + '\nNot for distribution.\n') if args.mode == 'review' else 'Desktop preview; release acceptance is tracked in docs/implementation-status.md.\n'
    with zipfile.ZipFile(mac_zip, 'a', compression=zipfile.ZIP_DEFLATED) as archive:
        archive.writestr('BUILD-NOTES.txt', readme)
        archive.write(source / 'CREDITS.md', 'CREDITS.md')
    (windows / 'BUILD-NOTES.txt').write_text(readme)
    shutil.copy2(source / 'CREDITS.md', windows / 'CREDITS.md')
    windows_zip = Path(shutil.make_archive(str(artifacts / (label + '-windows-x64')), 'zip', windows))
    (linux / 'BUILD-NOTES.txt').write_text(readme)
    shutil.copy2(source / 'CREDITS.md', linux / 'CREDITS.md')
    with linux_bin.open('rb') as stream:
        header = stream.read(20)
    # ELF, 64-bit, little-endian, machine x86_64 (62).
    if header[:4] != b'\x7fELF' or header[4] != 2 or header[5] != 1 or struct.unpack('<H', header[18:20])[0] != 62:
        raise SystemExit('Linux artifact is not an x86_64 ELF executable')
    linux_bin.chmod(0o755)
    # A tar keeps the "can run" flag that Linux needs (a zip would lose it).
    linux_tar = artifacts / (label + '-linux-x64.tar.gz')
    with tarfile.open(linux_tar, 'w:gz') as archive:
        archive.add(linux, arcname=linux.name)
    with windows_exe.open('rb') as stream:
        if stream.read(2) != b'MZ':
            raise SystemExit('Windows artifact is not a PE executable')
        stream.seek(0x3c)
        pe_offset = struct.unpack('<I', stream.read(4))[0]
        stream.seek(pe_offset)
        if stream.read(4) != b'PE\0\0' or struct.unpack('<H', stream.read(2))[0] != 0x8664:
            raise SystemExit('Windows artifact does not have the expected x86_64 PE header')
    mac_check = 'not run'
    if args.verify_mac:
        app_folder = output / 'mac-launch'
        app_folder.mkdir(exist_ok=True)
        # ditto preserves the executable flags and bundle layout in Godot's ZIP.
        subprocess.run(['ditto', '-x', '-k', mac_zip, app_folder], check=True)
        apps = list(app_folder.glob('*.app'))
        if len(apps) != 1:
            raise SystemExit('Expected one Mac application bundle')
        executables = [path for path in (apps[0] / 'Contents/MacOS').iterdir() if os.access(path, os.X_OK)]
        if len(executables) != 1:
            raise SystemExit('Expected one executable in the Mac application bundle')
        # Session 85: the game's own self-test plays one delivery and saves (scripts/build_check.gd).
        text = run([executables[0], '--headless', '--log-file', output / 'mac-runtime.log', '--', '--build-check'],
                   output / 'mac-launch.log', 300)
        if 'BUILD CHECK: PASS' not in text:
            print(text[-4000:], file=sys.stderr)
            raise SystemExit('The Mac build did not pass its build check (one delivery and a save)')
        mac_check = 'PASS: isolated review export plays a delivery and saves'
    manifest = {'engine': version, 'engine_sha256': digest(godot), 'mode': args.mode, 'source_sha256': original_hash,
                'mac_launch': mac_check, 'windows_runtime': 'not verified: no Windows host',
                'linux_runtime': 'not verified: no Linux host',
                'published': False, 'artifacts': []}
    template_source = portable_root / 'template-source.json'
    if template_source.is_file():
        manifest['template_source'] = json.loads(template_source.read_text())
    for path in [mac_zip, windows_zip, linux_tar]:
        manifest['artifacts'].append({'name': path.name, 'bytes': path.stat().st_size, 'sha256': digest(path)})
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(manifest, indent=2))


if __name__ == '__main__':
    main()
