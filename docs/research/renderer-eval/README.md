# Renderer Evaluation Snapshot

Captured on 2026-05-05 with the fixtures in `fixtures/mermaid/`.

This directory is a research snapshot for the initial renderer choice. It is
kept as implementation evidence, not as permanent user-facing documentation.
After the MVP is implemented, these artifacts can be replaced by automated
tests or removed if the decision is documented elsewhere.

## Commands

```sh
./.tools/bin/mermaid-ascii --file fixtures/mermaid/<name>.mmd
node scripts/render-beautiful-mermaid.mjs fixtures/mermaid/<name>.mmd
```

The reusable command is:

```sh
sh scripts/eval-renderers.sh
```

Each run stores:

- `docs/research/renderer-eval/<renderer>/<fixture>.stdout.txt`
- `docs/research/renderer-eval/<renderer>/<fixture>.stderr.txt`
- `docs/research/renderer-eval/<renderer>/<fixture>.exitcode`

## Exit Code Summary

| Fixture | mermaid-ascii | beautiful-mermaid |
| --- | ---: | ---: |
| `class_basic` | 1 | 0 |
| `er_basic` | 1 | 0 |
| `flowchart_basic` | 0 | 0 |
| `flowchart_branching` | 0 | 0 |
| `flowchart_japanese` | 0 | 0 |
| `flowchart_long_labels` | 0 | 0 |
| `invalid_syntax` | 0 | 0 |
| `sequence_basic` | 0 | 0 |
| `sequence_japanese` | 0 | 0 |
| `state_basic` | 1 | 0 |

## Initial Observations

- `mermaid-ascii` handles the required `flowchart` and `sequenceDiagram` fixtures, including Japanese labels.
- `mermaid-ascii` fails for preferred non-MVP diagrams: `classDiagram`, `stateDiagram-v2`, and `erDiagram`.
- `beautiful-mermaid` exits successfully for all current fixtures, including class, state, and ER diagrams.
- Both renderers accept `invalid_syntax.mmd` with exit code 0, so syntax validation cannot rely on exit code alone.
- Japanese output needs manual inspection in the real target environment: Ghostty inside tmux.

## Next Checks

- Inspect `flowchart_japanese.stdout.txt` and `sequence_japanese.stdout.txt` in Ghostty + tmux.
- Add stricter invalid syntax fixtures if parser failure behavior matters for fallback handling.
- Compare line width and readability in the planned float size.
