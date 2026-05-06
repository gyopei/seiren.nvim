# seiren.nvim

Mermaid-first Markdown preview for Neovim. The MVP renders the Mermaid diagram
nearest to the cursor in a focused floating window without opening a browser.

## Requirements

- Neovim 0.10+
- Node.js
- Tree-sitter markdown parser

## Installation

Example with lazy.nvim:

```lua
{
  "amag/seiren.nvim",
  build = "npm install",
  ft = "markdown",
  config = function()
    require("seiren").setup()
  end,
}
```

For local development:

```lua
{
  dir = "/home/amag/work/sandbox/seiren",
  build = "npm install",
  ft = "markdown",
  config = function()
    require("seiren").setup()
  end,
}
```

## Usage

- `:SeirenPreview`: render the Mermaid fence under the cursor, or the previous
  Mermaid fence when the cursor is outside a diagram.
- `:SeirenClose`: close the preview float.
- `:SeirenToggle`: open or close the preview float.
- `:checkhealth seiren`: check Node.js, the renderer runner, and package import.

## Configuration

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
  debounce_ms = 200,
})
```

## Development

Run the Lua test suite:

```sh
nvim --headless -u tests/minimal_init.lua -c "lua dofile('tests/run.lua')" -c qa
```

Re-run renderer evaluation snapshots:

```sh
npm run eval:renderers
```

Renderer evaluation output under `docs/research/renderer-eval/` is research
evidence for the initial backend choice. It can be replaced by automated tests
or removed after the decision is captured elsewhere.

