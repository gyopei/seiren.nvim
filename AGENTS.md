# Repository Guidelines

## Project Structure & Module Organization

This repository is for `seiren.nvim`, a Mermaid-first Markdown preview plugin for Neovim. The goal is to render Markdown context inside Neovim, with Mermaid diagrams previewed in a floating window without opening a browser. Node.js is an expected runtime dependency for the primary renderer. Use this layout as the implementation grows:

- `lua/seiren/` for plugin modules.
- `plugin/` for Neovim startup entrypoints.
- `autoload/` only when Vimscript compatibility is required.
- `doc/` for `:help` documentation.
- `tests/` for automated tests and fixtures.
- `README.md` for user-facing setup and usage notes.

## Build, Test, and Development Commands

No build or test commands are defined yet. When tooling is added, document it here and in `README.md`.

Expected commands once tooling is added:

- `nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init='tests/minimal_init.lua'}"`: run Plenary tests.
- `stylua lua tests`: format Lua sources and tests.
- `luacheck lua tests`: lint Lua code when a `.luacheckrc` is present.

## Coding Style & Naming Conventions

Use Lua unless a module clearly needs Vimscript integration. Prefer 2-space indentation, `snake_case` for local variables and functions, and module files named by feature, such as `lua/seiren/renderer.lua`, `parser.lua`, or `mermaid.lua`. Keep modules small and expose only needed functions.

Format with `stylua` once configured. Avoid global state except for explicit plugin setup, and keep user configuration tables validated at the boundary.

## Testing Guidelines

Place tests under `tests/` and name files after the module or behavior under test, for example `tests/renderer_spec.lua`. Cover Markdown parsing, table layout, Mermaid block detection, rendering, configuration, commands, and preview windows. Add regression tests for every bug fix.

## Commit & Pull Request Guidelines

Git metadata is not available in this checkout, so no existing commit convention can be inferred. Use concise imperative commits, optionally scoped: `Add renderer option validation` or `Fix preview buffer cleanup`.

Pull requests should include a summary, testing performed, linked issues when applicable, and screenshots or terminal output for user-visible behavior. Keep refactors separate from feature or bug-fix work.

## Agent-Specific Instructions

Before editing, inspect the current tree because this repository may be bootstrapped incrementally. Do not assume tooling exists until a manifest or config file is present.

Treat Mermaid support as a core requirement, not an optional enhancement. Initial implementation should prioritize `beautiful-mermaid` via Node.js, ASCII/Unicode rendering, float preview, and tmux + Ghostty behavior before image backends.
