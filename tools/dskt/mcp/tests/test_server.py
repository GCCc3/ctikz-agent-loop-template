"""Unit tests for the Dskt MCP shim tool registry."""

from __future__ import annotations

import os
import unittest
from unittest.mock import patch

from dskt_mcp_server import server
from dskt_mcp_server.server import TOOLS, _allowed


class FakeMCP:
    def __init__(self):
        self.calls = []

    def tool(self, function, name=None, annotations=None):
        self.calls.append((name, annotations))


class ToolRegistryTest(unittest.TestCase):
    def test_expected_tools_are_registered(self):
        names = {name for _, name, _, _ in TOOLS}
        for expected in {
            "png_inspect_image",
            "png_measure_bounds",
            "ctikz_list_snippets",
            "ctikz_get_snippet",
            "ctikz_render_snippet",
            "ctikz_lookup_component",
            "ctikz_lint_source",
            "dskt_health",
            "dskt_trace",
        }:
            self.assertIn(expected, names)

    def test_module_filter_keeps_only_lint(self):
        selected = [
            name
            for module, name, _, _ in TOOLS
            if _allowed(module, name, {"ctikz_lint"}, set())
        ]
        self.assertEqual(selected, ["ctikz_lint_source"])

    def test_explicit_tool_filter(self):
        selected = [
            name
            for module, name, _, _ in TOOLS
            if _allowed(module, name, set(), {"ctikz_render_snippet"})
        ]
        self.assertEqual(selected, ["ctikz_render_snippet"])

    def test_register_tools_module_filter(self):
        fake = FakeMCP()
        with patch.object(server, "mcp", fake), patch.dict(
            os.environ, {"DSKT_MODULES": "ctikz_lint", "DSKT_TOOLS": ""}
        ):
            server.register_tools()
        self.assertEqual([name for name, _ in fake.calls], ["ctikz_lint_source"])

    def test_register_tools_explicit_filter(self):
        fake = FakeMCP()
        with patch.object(server, "mcp", fake), patch.dict(
            os.environ, {"DSKT_MODULES": "", "DSKT_TOOLS": "ctikz_render_snippet"}
        ):
            server.register_tools()
        self.assertEqual([name for name, _ in fake.calls], ["ctikz_render_snippet"])

    def test_lint_defaults_to_reconstruction_path(self):
        with patch.object(server, "post_json", return_value={}) as post:
            server.ctikz_lint_source()
        payload = post.call_args.args[1]
        self.assertEqual(payload["path"], "current/reconstruction.tex")
        self.assertNotIn("source_text", payload)
