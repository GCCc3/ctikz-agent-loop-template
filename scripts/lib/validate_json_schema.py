#!/usr/bin/env python3
"""Validate JSON using jsonschema when available, otherwise a strict subset.

The fallback supports the schema features used by this project: type,
properties, required, additionalProperties, items, enum, and minimum.
"""
import json
import sys
from pathlib import Path


def fail(message):
    raise ValueError(message)


def type_matches(value, expected):
    mapping = {
        "object": lambda v: isinstance(v, dict),
        "array": lambda v: isinstance(v, list),
        "string": lambda v: isinstance(v, str),
        "integer": lambda v: isinstance(v, int) and not isinstance(v, bool),
        "number": lambda v: isinstance(v, (int, float)) and not isinstance(v, bool),
        "boolean": lambda v: isinstance(v, bool),
        "null": lambda v: v is None,
    }
    return expected in mapping and mapping[expected](value)


def validate(value, schema, path="$", is_root=True):
    expected = schema.get("type")
    if expected is not None:
        expected_types = expected if isinstance(expected, list) else [expected]
        if not any(type_matches(value, t) for t in expected_types):
            fail(f"{path}: expected type {expected_types}, found {type(value).__name__}")

    if "enum" in schema and value not in schema["enum"]:
        fail(f"{path}: value {value!r} is not in enum {schema['enum']!r}")

    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            fail(f"{path}: value is below minimum {schema['minimum']}")

    if isinstance(value, dict):
        properties = schema.get("properties", {})
        for required in schema.get("required", []):
            if required not in value:
                fail(f"{path}: missing required property {required!r}")
        if schema.get("additionalProperties") is False:
            unknown = sorted(set(value) - set(properties))
            if unknown:
                fail(f"{path}: unexpected properties {unknown!r}")
        for key, child in value.items():
            if key in properties:
                validate(child, properties[key], f"{path}.{key}", False)

    if isinstance(value, list) and "items" in schema:
        for index, item in enumerate(value):
            validate(item, schema["items"], f"{path}[{index}]", False)


def main():
    if len(sys.argv) != 3:
        print("usage: validate_json_schema.py DATA.json SCHEMA.json", file=sys.stderr)
        return 2
    data_path, schema_path = map(Path, sys.argv[1:])
    try:
        data = json.loads(data_path.read_text(encoding="utf-8"))
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
        try:
            import jsonschema
        except ImportError:
            validate(data, schema)
        else:
            jsonschema.Draft202012Validator(schema).validate(data)
    except Exception as exc:
        print(f"validation failed: {exc}", file=sys.stderr)
        return 1
    print(f"valid: {data_path} conforms to {schema_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
