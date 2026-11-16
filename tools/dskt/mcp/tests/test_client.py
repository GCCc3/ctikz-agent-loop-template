"""Unit tests for the Dskt MCP HTTP client helpers."""

from __future__ import annotations

import os
import tempfile
import unittest
from unittest.mock import patch

import httpx

from dskt_mcp_server import core


class FakeResponse:
    def __init__(self, body, status_code=200):
        self._body = body
        self.status_code = status_code

    def json(self):
        if isinstance(self._body, Exception):
            raise self._body
        return self._body


class ClientTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.env = patch.dict(
            os.environ,
            {
                "DSKT_REPO_ROOT": self.directory.name,
                "DSKT_TRACE_LOG": "trace.jsonl",
            },
        )
        self.env.start()
        self.addCleanup(self.env.stop)

    def test_get_json_success(self):
        with patch.object(core.httpx, "get", return_value=FakeResponse({"success": True})):
            self.assertEqual(core.get_json("/health"), {"success": True})

    def test_get_json_non_json(self):
        with patch.object(core.httpx, "get", return_value=FakeResponse(ValueError("bad"))):
            result = core.get_json("/health")
        self.assertFalse(result["success"])
        self.assertEqual(result["error"]["code"], "internal_error")

    def test_get_json_transport_error(self):
        with patch.object(core.httpx, "get", side_effect=httpx.ConnectError("down")):
            result = core.get_json("/health")
        self.assertFalse(result["success"])
        self.assertEqual(result["error"]["code"], "transport_error")

    def test_post_json_success(self):
        with patch.object(core.httpx, "post", return_value=FakeResponse({"success": True})):
            self.assertEqual(core.post_json("/ctikz/lint", {}), {"success": True})

    def test_post_json_transport_error(self):
        with patch.object(core.httpx, "post", side_effect=httpx.ConnectError("down")):
            result = core.post_json("/ctikz/lint", {})
        self.assertFalse(result["success"])
        self.assertEqual(result["error"]["code"], "transport_error")


if __name__ == "__main__":
    unittest.main()
