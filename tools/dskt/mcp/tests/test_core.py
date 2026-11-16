"""Unit tests for the shared Dskt MCP helpers."""

from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from dskt_mcp_server import core


class CoreTest(unittest.TestCase):
    def test_repo_root_uses_environment(self):
        with patch.dict(os.environ, {"DSKT_REPO_ROOT": "/tmp/example-root"}):
            self.assertEqual(core.repo_root(), Path("/tmp/example-root").resolve())

    def test_trace_log_relative_to_repo_root(self):
        with patch.dict(
            os.environ,
            {"DSKT_REPO_ROOT": "/tmp/example-root", "DSKT_TRACE_LOG": "tmp/trace.jsonl"},
        ):
            self.assertEqual(
                core.trace_log(),
                Path("/tmp/example-root/tmp/trace.jsonl").resolve(),
            )

    def test_service_url(self):
        with patch.dict(os.environ, {"DSKT_HOST": "127.0.0.1", "DSKT_PORT": "9999"}):
            self.assertEqual(core.service_url("/health"), "http://127.0.0.1:9999/health")

    def test_resolve_image_path_inside_root(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            image = root / "image.png"
            image.write_bytes(b"png")
            with patch.dict(os.environ, {"DSKT_REPO_ROOT": str(root)}):
                absolute, relative = core.resolve_image_path("image.png")
            self.assertEqual(absolute, str(image.resolve()))
            self.assertEqual(relative, "image.png")

    def test_resolve_image_path_outside_root(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "root"
            root.mkdir()
            outside = Path(directory) / "outside.png"
            outside.write_bytes(b"png")
            with patch.dict(os.environ, {"DSKT_REPO_ROOT": str(root)}):
                with self.assertRaises(core.ShimError) as context:
                    core.resolve_image_path(str(outside))
            self.assertEqual(context.exception.code, "path_outside_repo")

    def test_envelope_success(self):
        envelope = core.envelope_success({"ok": True})
        self.assertTrue(envelope["success"])
        self.assertEqual(envelope["result"], {"ok": True})

    def test_envelope_error(self):
        envelope = core.envelope_error(core.ShimError("invalid_request", "bad"))
        self.assertFalse(envelope["success"])
        self.assertEqual(envelope["error"]["code"], "invalid_request")


if __name__ == "__main__":
    unittest.main()
