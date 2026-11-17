# PNG measurement — operational steps

Status: complete. No remaining operational steps.

The baseline feature has been removed. The shared Dskt setup is current:

- Service image: `tmp/dskt/DsktService.image`
- Service: `127.0.0.1:8087`, `/png/*`
- MCP shim: `tools/dskt/mcp`, server name `dskt`
- Trace log: `tmp/dskt/tool-trace.jsonl`
- Domain README: `tools/png-measure/README.md`
- Environment: `DSKT_*` and `PNG_*`; do not use `PDMT_*`

## Completed: PNG tools in agent allowlists and prompts

`.omp/agents/diagram-generator.md` and
`.omp/agents/diagram-reviewer.md` now list:

- `png_inspect_image`
- `png_measure_bounds`
- `png_measure_regions`
- `png_normalize_geometry`
- `png_health`

The prompts require measurement of both `reference/target.png` and
`current/reconstruction.png` before geometry claims, require the citation of
tool, raw box or point, basis, mask threshold and background, and warning codes,
and keep the reviewer read-only. The write tool `png_make_ink_mask` and the
diagnostic `png_trace` are not exposed to either role.

## Verification

- `scripts/png-measure-smoke.sh` passes against the running service.
- `png_measure_bounds`, `png_measure_regions`, and `png_normalize_geometry`
  return the shared envelope.
- The agent front matter parses and contains the five `png_*` tools in both
  roles.
- `/png/create_baseline` returns 404 and `png_create_baseline` is absent from
  the MCP tool list.
