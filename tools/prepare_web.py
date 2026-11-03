#!/usr/bin/env python3
"""Prepare a Godot Web export for Cloudflare Pages without changing the export.

Usage: python3 tools/prepare_web.py build/web build/site
BUILD_SHA defaults to this checkout's HEAD; BUILD_VERSION defaults to that SHA.
Store compressed modules as .wasm.gz and internally route their original .wasm
URLs to them. Godot's generated loader and uncompressed fileSizes stay unchanged.
"""

from __future__ import annotations

import argparse
import gzip
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


MAX_FILE_SIZE = 25 * 1024 * 1024
REQUIRED_FILES = ("index.html", "index.js", "index.wasm", "index.pck")


def prepare_web(
    source: Path,
    destination: Path,
    *,
    build_sha: str,
    build_version: str | None = None,
    max_file_size: int = MAX_FILE_SIZE,
) -> dict[str, str]:
    """Create a clean site only after all its files have passed the size limit."""
    source = source.resolve()
    destination = destination.resolve()
    if source == destination or source in destination.parents or destination in source.parents:
        raise ValueError("The export and site directories must not overlap.")
    if not re.fullmatch(r"[0-9a-fA-F]{40}", build_sha):
        raise ValueError("BUILD_SHA must be a full 40-character Git commit SHA.")
    for name in REQUIRED_FILES:
        if not (source / name).is_file():
            raise ValueError(f"Missing Godot export file: {name}")

    metadata = {"sha": build_sha.lower(), "version": build_version or build_sha.lower()}
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".habibi-site-", dir=destination.parent) as temporary:
        site = Path(temporary) / "site"
        site.mkdir()
        wasm_paths = []
        for path in sorted(source.rglob("*")):
            if path.is_symlink():
                raise ValueError(f"Export must not contain symlinks: {path.relative_to(source)}")
            if not path.is_file():
                continue
            relative = path.relative_to(source)
            if relative.as_posix() in ("_headers", "_redirects", "version.json"):
                continue  # These are regenerated for every deployment.
            target = site / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            if path.suffix == ".wasm":
                raw = path.read_bytes()
                if not raw.startswith(b"\x00asm"):
                    raise ValueError(f"Not an uncompressed WebAssembly module: {relative}")
                # Pages can compress .wasm origin assets before applying _headers.
                # A .gz asset is recognized as already compressed; the original
                # URL is preserved by an internal 200 proxy rule below.
                target = target.with_suffix(".wasm.gz")
                if path.with_suffix(".wasm.gz").exists():
                    raise ValueError(f"Export already contains a compressed sibling: {relative}.gz")
                target.write_bytes(gzip.compress(raw, compresslevel=9, mtime=0))
                wasm_paths.append("/" + relative.as_posix())
            else:
                shutil.copyfile(path, target)

        headers = [
            "/*",
            "  Cache-Control: no-cache, no-transform",
            "  X-Content-Type-Options: nosniff",
            "  Referrer-Policy: strict-origin-when-cross-origin",
        ]
        redirects = []
        for path in wasm_paths:
            redirects.append(f"{path} {path}.gz 200")
            for url in (path, path + ".gz"):
                headers.extend(("", url, "  Content-Encoding: gzip", "  Content-Type: application/wasm"))
        (site / "_headers").write_text("\n".join(headers) + "\n", encoding="utf-8")
        (site / "_redirects").write_text("\n".join(redirects) + "\n", encoding="utf-8")
        (site / "version.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")

        for path in sorted(site.rglob("*")):
            if path.is_file() and path.stat().st_size >= max_file_size:
                raise ValueError(
                    f"{path.relative_to(site)} is {path.stat().st_size:,} bytes; "
                    f"each Pages file must be smaller than {max_file_size:,} bytes."
                )
        # A failed build leaves the previous prepared site intact. On success,
        # replacing the whole directory also prevents stale exported files.
        if destination.exists():
            shutil.rmtree(destination)
        site.rename(destination)
    return metadata


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    try:
        sha = os.environ.get("BUILD_SHA") or subprocess.check_output(
            ["git", "rev-parse", "HEAD"],
            cwd=Path(__file__).resolve().parents[1],
            text=True,
        ).strip()
        metadata = prepare_web(
            args.source,
            args.destination,
            build_sha=sha,
            build_version=os.environ.get("BUILD_VERSION"),
        )
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Web preparation failed: {error}\n")
    print(f"Prepared {args.destination}: {metadata['version']} ({metadata['sha']})")


if __name__ == "__main__":
    main()
