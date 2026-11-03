#!/usr/bin/env bash
# Validate the game, export a single-thread Web build, then prepare Cloudflare assets.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -z "${GODOT_BIN:-}" ]]; then
  GODOT_BIN="$ROOT/.cache/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64"
  if [[ ! -x "$GODOT_BIN" ]]; then
    if command -v godot >/dev/null 2>&1; then
      GODOT_BIN="$(command -v godot)"
    elif [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
      GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
    else
      echo "Run tools/install-godot.sh on Linux, or set GODOT_BIN to your Godot 4.7.2 executable." >&2
      exit 1
    fi
  fi
fi
export GODOT_BIN

python3 - <<'PY'
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

root = Path.cwd()
godot = str(Path(os.environ["GODOT_BIN"]).expanduser().resolve())
version = subprocess.check_output([godot, "--version"], text=True, timeout=30).strip()
if not version.startswith("4.7.2.stable."):
    raise SystemExit(f"Expected Godot 4.7.2 stable, got {version!r}")
print(f"Building with Godot {version}", flush=True)
logs = root / "build" / "logs"
logs.mkdir(parents=True, exist_ok=True)
(root / "build" / ".gdignore").touch()
ansi = re.compile(r"\x1b\[[0-9;]*m")

def run(name, args, timeout=180, require_pass=False):
    print(f"\nRunning {name} (timeout {timeout}s)", flush=True)
    command = [godot, "--headless", "--path", str(root),
               "--log-file", str(logs / f"{name}-engine.log"), *args]
    try:
        completed = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   text=True, timeout=timeout)
        output = ansi.sub("", completed.stdout)
    except subprocess.TimeoutExpired as error:
        output = error.stdout or b""
        if isinstance(output, bytes):
            output = output.decode(errors="replace")
        (logs / f"{name}.log").write_text(output)
        raise SystemExit(f"{name} timed out; see build/logs/{name}.log") from error
    (logs / f"{name}.log").write_text(output)
    print(output, end="", flush=True)
    lines = output.splitlines()
    errors = []
    for index, line in enumerate(lines):
        if not line.startswith(("ERROR:", "SCRIPT ERROR:")):
            continue
        # macOS sandbox certificate-store access is unrelated to game validation.
        # Match the exact diagnostic and its function; don't suppress other errors.
        known_mac_certificate_error = (
            sys.platform == "darwin"
            and line == 'ERROR: Condition "ret != noErr" is true. Returning: ""'
            and index + 1 < len(lines)
            and "at: get_system_ca_certificates (platform/macos/os_macos.mm:" in lines[index + 1]
        )
        if not known_mac_certificate_error:
            errors.append(line)
    if completed.returncode or errors or (require_pass and "RESULT: PASS" not in output):
        raise SystemExit(f"{name} failed (exit {completed.returncode}); see build/logs/{name}.log")

run("import", ["--import"], timeout=300)
# Initial GameState._ready loads before wiring autosave signals; this reads existing
# player progress but does not modify it. All logs are redirected into build/logs.
run("startup", ["--quit"])
with tempfile.TemporaryDirectory(prefix="habibi-web-check-") as temporary:
    temporary = Path(temporary)
    original = (root / "tests" / "smoke_test.gd").read_text()
    marker = 'const TEST_SAVE := "user://smoke_test_save.json"'
    if original.count(marker) != 1:
        raise SystemExit("Smoke test save setup changed; update build-web.sh before running tests")
    test = temporary / "smoke_test.gd"
    # Same test logic, isolated save: local builds cannot overwrite player progress
    # and work even when macOS's user data directory isn't writable by the sandbox.
    save_path = json.dumps((temporary / "save.json").as_posix())
    test.write_text(original.replace(marker, f"const TEST_SAVE := {save_path}"))
    run("smoke", ["--fixed-fps", "60", "-s", str(test)], timeout=900, require_pass=True)
run("touch", ["-s", "tests/touch_controls_test.gd"], require_pass=True)

web = root / "build" / "web"
if web.exists():
    shutil.rmtree(web)
web.mkdir(parents=True)
run("export", ["--export-release", "Web", str(web / "index.html")], timeout=300)
subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", "tests",
                "-p", "test_prepare_web.py"], check=True, timeout=120)
subprocess.run([sys.executable, "tools/prepare_web.py", "build/web", "build/site"],
               check=True, timeout=180)
print("\nBrowser build ready: build/site", flush=True)
PY
