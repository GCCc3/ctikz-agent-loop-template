# PNG measurement domain

The PNG domain registers `/png/*` routes on the shared `DsktServer`. It is loaded
into the same Pharo image as the CircuitTikZ domain; there is no separate server
or port.

## Environment

| Variable | Default | Purpose |
|---|---|---|
| `DSKT_PORT` | `8087` | Shared server port |
| `DSKT_HOST` | `127.0.0.1` | Shared bind address |
| `DSKT_REPO_ROOT` | current directory | Repository boundary |
| `DSKT_TRACE_LOG` | `tmp/dskt/tool-trace.jsonl` | Shared trace log |
| `PNG_OUTPUT_ROOT` | `tmp/png-measure` | Mask output root |
| `PNG_MAX_PIXELS` | `50000000` | Decoded image pixel limit |

## Routes

- `GET /png/health`
- `GET /png/trace`
- `POST /png/inspect_image`
- `POST /png/make_ink_mask`
- `POST /png/measure_bounds`
- `POST /png/measure_regions`
- `POST /png/normalize_geometry`

All routes use the shared success/error envelope. Paths are resolved under
`DSKT_REPO_ROOT`; symlinks and sibling-prefix escapes are rejected.

## Install and run

```bash
export PHARO=/path/to/pharo
export DSKT_BASE_IMAGE=/path/to/base.image
scripts/dskt-install.sh
scripts/dskt-start.sh
scripts/png-measure-smoke.sh
```
