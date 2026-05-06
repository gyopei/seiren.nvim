# MVP Implementation Plan

## Scope

`seiren.nvim` starts as a Mermaid-first Markdown preview plugin for Neovim. The MVP renders the Mermaid diagram nearest to the cursor in a focused floating window. It does not attempt full Markdown document preview.

## Runtime Assumptions

- Neovim 0.10+.
- Node.js is required.
- `beautiful-mermaid` is installed as a plugin-local npm dependency through the plugin manager build step, for example `build = "npm install"`.
- Tree-sitter markdown support is required from the beginning.
- Initial target environment is Ghostty inside tmux.

## MVP Behavior

- `:SeirenPreview` renders the cursor-selected diagram and opens/updates the float.
- `:SeirenClose` closes the preview float.
- `:SeirenToggle` toggles the preview float.
- Diagram selection is cursor-based:
  - if the cursor is inside a Mermaid fence, use that fence;
  - otherwise use the previous Mermaid fence.
- Preview uses a focused centered float, about 80% editor width and height, rounded border, `wrap=false`, and `q` to close.
- Render updates are manual only. Live preview is not part of MVP. Save-triggered rerender can be considered later for split/pane mode.
- Markdown text is displayed only as diagram context: heading, diagram type, start line, and short before/after snippets.

## Module Layout

```text
plugin/seiren.lua
lua/seiren/init.lua
lua/seiren/config.lua
lua/seiren/parser.lua
lua/seiren/context.lua
lua/seiren/preview.lua
lua/seiren/backends/beautiful_mermaid.lua
lua/seiren/backends/mermaid_ascii.lua
lua/seiren/health.lua
scripts/render-beautiful-mermaid.mjs
tests/minimal_init.lua
tests/seiren/
```

## Module Responsibilities

- `init.lua`: public API, setup, command wiring.
- `config.lua`: defaults, user option merge, validation helpers.
- `parser.lua`: Tree-sitter markdown parsing, Mermaid fence extraction, cursor target selection.
- `context.lua`: diagram context formatting and width trimming.
- `preview.lua`: float buffer/window lifecycle and keymaps.
- `backends/beautiful_mermaid.lua`: Node runner invocation and result normalization.
- `backends/mermaid_ascii.lua`: optional comparison/fallback CLI backend.
- `health.lua`: `:checkhealth seiren` diagnostics.
- `scripts/render-beautiful-mermaid.mjs`: Node bridge to `beautiful-mermaid`.

## Default Configuration

```lua
require("seiren").setup({
  preview = {
    window = "float",
    mode = "diagram_context",
    wrap = false,
    update = "manual",
    context_lines = 1,
    context_max_width = 80,
  },
  mermaid = {
    backend = "beautiful_mermaid",
    node_command = "node",
    runner_path = nil,
    prefer_unicode = true,
    japanese_label_mode = "auto",
  },
})
```

## Testing Strategy

Use Plenary-style headless tests. Prioritize unit tests before UI details:

- `context_spec.lua`: context formatting, trimming, Japanese text handling.
- `parser_spec.lua`: Mermaid fence extraction, cursor selection, previous-fence fallback.
- `beautiful_mermaid_spec.lua`: command construction and result normalization, with process execution mockable.
- `preview_spec.lua`: buffer/window creation, `wrap=false`, close behavior.
- `health_spec.lua`: dependency checks where practical.

Renderer output snapshots remain under `docs/research/renderer-eval/` and are separate from unit tests.

## Implementation Order

1. Scaffold Lua modules and command registration.
2. Add config defaults and validation.
3. Implement context formatter with tests.
4. Implement Tree-sitter parser with tests.
5. Implement `beautiful_mermaid` backend and Node runner integration.
6. Implement focused float preview.
7. Wire `:SeirenPreview`, `:SeirenClose`, and `:SeirenToggle`.
8. Add health check.
9. Write README with lazy.nvim install instructions.

## Deferred Work

- Image backend.
- Full Markdown document preview mode.
- Split/pane preview mode.
- Save-triggered rerender.
- Live preview.
- Stronger Mermaid syntax validation.
- Japanese legend fallback beyond the initial `japanese_label_mode` option.
