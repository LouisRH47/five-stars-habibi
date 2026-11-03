"""Run with: python3 -m unittest discover -s tests -p 'test_prepare_web.py'."""

import gzip
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


MODULE_PATH = Path(__file__).resolve().parents[1] / "tools" / "prepare_web.py"
SPEC = importlib.util.spec_from_file_location("prepare_web", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
SHA = "a" * 40


class PrepareWebTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.source = self.root / "web"
        self.site = self.root / "site"
        self.source.mkdir()
        self.wasm = b"\x00asm\x01\x00\x00\x00" + b"example engine data" * 100
        self.html = '<script>const config = {fileSizes: {"index.wasm": 1908}}</script>'
        (self.source / "index.wasm").write_bytes(self.wasm)
        (self.source / "index.html").write_text(self.html)
        (self.source / "index.js").write_text("// Godot loader")
        (self.source / "index.pck").write_bytes(b"packed game")

    def prepare(self, **kwargs):
        return MODULE.prepare_web(self.source, self.site, build_sha=SHA, **kwargs)

    def test_gzip_asset_preserves_decoded_wasm_bytes_and_loader(self):
        self.prepare(build_version="v0.1.0")
        compressed = (self.site / "index.wasm.gz").read_bytes()
        self.assertEqual(gzip.decompress(compressed), self.wasm)
        self.assertEqual(gzip.decompress(compressed)[:4], b"\x00asm")
        self.assertLess(len(compressed), len(self.wasm))
        self.assertEqual((self.source / "index.wasm").read_bytes(), self.wasm)
        self.assertEqual((self.site / "index.html").read_text(), self.html)
        self.assertFalse((self.site / "index.wasm").exists())
        self.assertEqual((self.site / "index.pck").read_bytes(), b"packed game")
        self.assertEqual(json.loads((self.site / "version.json").read_text()),
                         {"sha": SHA, "version": "v0.1.0"})
        self.prepare()
        self.assertEqual((self.site / "index.wasm.gz").read_bytes(), compressed)
        self.assertEqual(json.loads((self.site / "version.json").read_text())["version"], SHA)

    def test_proxy_and_headers_preserve_original_url_without_recompression(self):
        self.prepare()
        headers = (self.site / "_headers").read_text()
        self.assertTrue(headers.startswith("/*\n  Cache-Control: no-cache, no-transform\n"))
        self.assertIn("  X-Content-Type-Options: nosniff\n", headers)
        self.assertIn("  Referrer-Policy: strict-origin-when-cross-origin\n", headers)
        self.assertIn("/index.wasm\n  Content-Encoding: gzip\n  Content-Type: application/wasm\n", headers)
        self.assertIn("/index.wasm.gz\n  Content-Encoding: gzip\n  Content-Type: application/wasm\n", headers)
        self.assertEqual((self.site / "_redirects").read_text(), "/index.wasm /index.wasm.gz 200\n")

    def test_rejects_preexisting_compressed_sibling(self):
        (self.source / "index.wasm.gz").write_bytes(b"would overwrite prepared bytes")
        with self.assertRaisesRegex(ValueError, "compressed sibling"):
            self.prepare()

    def test_limit_failure_preserves_previous_site(self):
        self.site.mkdir()
        (self.site / "previous.txt").write_text("previous release")
        with (self.source / "index.pck").open("wb") as file:
            file.truncate(MODULE.MAX_FILE_SIZE)
        with self.assertRaisesRegex(ValueError, r"index.pck.*smaller"):
            self.prepare()
        self.assertEqual((self.site / "previous.txt").read_text(), "previous release")
        self.assertFalse((self.site / "index.html").exists())

    def test_success_cleans_stale_output(self):
        self.site.mkdir()
        (self.site / "old-service-worker.js").write_text("stale")
        self.prepare()
        self.assertFalse((self.site / "old-service-worker.js").exists())

    def test_rejects_overlap_and_symlinks(self):
        with self.assertRaisesRegex(ValueError, "must not overlap"):
            MODULE.prepare_web(self.source, self.source, build_sha=SHA)
        (self.source / "outside.txt").symlink_to(self.root / "private.txt")
        with self.assertRaisesRegex(ValueError, "symlinks"):
            self.prepare()

    def test_missing_or_precompressed_wasm_fails(self):
        (self.source / "index.wasm").write_bytes(gzip.compress(self.wasm))
        with self.assertRaisesRegex(ValueError, "uncompressed WebAssembly"):
            self.prepare()
        (self.source / "index.wasm").unlink()
        with self.assertRaisesRegex(ValueError, "Missing Godot export"):
            self.prepare()


if __name__ == "__main__":
    unittest.main()
