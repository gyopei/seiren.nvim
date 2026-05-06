# Mermaid Renderer Technical Selection

## Purpose

This document defines how to choose the first Mermaid renderer backend for `seiren.nvim`. The decision should be based on reproducible output in the target terminal environment, not on implementation preference.

## Hard Requirements

- Supports `flowchart`.
- Supports `sequenceDiagram`.
- Renders mixed Japanese and ASCII labels without breaking layout in Ghostty + tmux.
- Provides terminal-friendly ASCII or Unicode output.
- Can be called from Neovim Lua through Node.js runner or a CLI.
- Fails safely: invalid Mermaid input must return a usable error and preserve the source as fallback content.

## Preferred Diagram Support

Support for these diagram types should increase a candidate's priority, but is not required for the first MVP:

- `classDiagram`
- `stateDiagram` or `stateDiagram-v2`
- `erDiagram`

Other Mermaid syntax support is useful but should not dominate the decision.

## Candidate Renderers

- `beautiful-mermaid`: JavaScript/TypeScript renderer with ASCII/Unicode output. First-choice backend because it passed all current fixtures and Node.js is acceptable as a runtime requirement.
- `mermaid-ascii`: Go CLI. Useful comparison/fallback backend, but current evaluation failed class, state, and ER fixtures.
- `mermaid_text`: Rust crate. Potentially lightweight, but must be checked for CLI availability and syntax coverage.

## Evaluation Criteria

### Functional Coverage

- Required diagram support: `flowchart`, `sequenceDiagram`.
- Preferred diagram support: class, state, ER.
- Direction support: `TD`, `LR`, branching, joins, and nested paths.
- Label support: long labels, punctuation, spaces, Markdown-like emphasis, and Japanese text.

### Layout Quality

- No overlap between nodes, arrows, and labels.
- Stable alignment with full-width Japanese characters.
- Readable output in both narrow and wide float windows.
- Reasonable wrapping or truncation behavior for long labels.

### Terminal Compatibility

- Output remains aligned in Ghostty.
- Output remains aligned inside tmux.
- Unicode box drawing can be disabled or replaced with ASCII if needed.
- No dependency on terminal image protocols for MVP.

### Integration Quality

- Simple install path for personal use.
- CLI accepts stdin or temporary files.
- Exit code and stderr are reliable.
- Runtime performance is acceptable for preview updates.
- Output is deterministic enough for snapshot tests.

### Maintenance Risk

- Active enough project or small enough dependency surface.
- Clear license.
- Minimal platform-specific assumptions.
- Easy fallback path when the renderer is missing or fails.

## Fixture Plan

Create Mermaid fixtures under `fixtures/mermaid/`:

- `flowchart_basic.mmd`
- `flowchart_branching.mmd`
- `flowchart_japanese.mmd`
- `flowchart_long_labels.mmd`
- `sequence_basic.mmd`
- `sequence_japanese.mmd`
- `class_basic.mmd`
- `state_basic.mmd`
- `er_basic.mmd`
- `invalid_syntax.mmd`

Each candidate should render every fixture. Store observed output and notes under `docs/research/renderer-eval/` or equivalent when evaluation begins.

## Initial Recommendation

Use `beautiful-mermaid` as the MVP backend through a plugin-local Node.js runner. Keep `mermaid-ascii` available as a comparison or fallback backend, but do not optimize the first implementation around it.
