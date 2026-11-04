"""Copy a snapshot into temporary storage and redirect every Godot user:// path.

This preserves real player progress and settings while the game, tests, and exports run.
Pass a separate empty temporary folder for each concurrent validation process.
"""
from pathlib import Path
import shutil
import sys
import tempfile

source = Path(__file__).resolve().parents[1]
destination = Path(sys.argv[1]).resolve()
temporary_roots = {Path('/private/tmp').resolve(), Path(tempfile.gettempdir()).resolve()}
if not any(destination != base and destination.is_relative_to(base) for base in temporary_roots):
    raise SystemExit('Validation snapshots must live in a dedicated temporary folder')
if destination == source or destination.is_relative_to(source):
    raise SystemExit('The validation snapshot must be outside the source worktree')
project = destination / 'project'
userdata = destination / 'userdata'
userdata.mkdir(parents=True, exist_ok=True)
shutil.copytree(source, project, dirs_exist_ok=True,
                ignore=shutil.ignore_patterns('.git', '.godot', '.claude', '.cache', 'build', '__pycache__'))
for script in project.rglob('*.gd'):
    script.write_text(script.read_text().replace('user://', str(userdata) + '/'))
print(project)

config = project / 'project.godot'
settings = config.read_text()
settings += '\n[debug]\n\nfile_logging/log_path="' + str(destination / 'engine.log') + '"\n'
config.write_text(settings)
