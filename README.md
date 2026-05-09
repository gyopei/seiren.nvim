# seiren.nvim

Neovim 内で Mermaid を確認するための、Mermaid-first な Markdown preview
plugin です。

`seiren.nvim` は、カーソル位置にある Mermaid diagram、またはカーソルより前の
直近の Mermaid diagram を floating window に表示します。ブラウザを開かず、
Markdown を書いている Neovim の中で diagram の見た目を確認できます。

## モチベーション

Mermaid diagram は Markdown の中に自然に書けますが、日本語ラベルを含む図を
ターミナル上で崩さず確認するのは意外と面倒です。一般的な Markdown preview
plugin は Mermaid をブラウザ上のドキュメント preview として扱うことが多く、
Neovim、tmux、terminal を中心にした編集ループでは少し大きすぎます。

`seiren.nvim` が重視しているのは、Markdown 全体の preview ではなく、
「いま編集している Mermaid 図が、日本語を含んでも読める形で表示されること」
です。

- Mermaid support を中心機能として扱います。
- preview は Neovim の floating window に表示します。
- Node.js と `beautiful-mermaid` を使い、terminal-friendly な Unicode 出力を
  生成します。
- renderer が失敗した場合や依存が足りない場合でも、Mermaid source を fallback
  として表示します。
- 日本語ラベルを含む diagram を、Ghostty + tmux のような terminal 環境で確認
  することを初期ターゲットにしています。

## Requirements

- Neovim 0.10+
- Node.js
- Tree-sitter markdown parser
- Unicode box drawing characters を自然に表示できる terminal

## Installation

[lazy.nvim](https://github.com/folke/lazy.nvim) の設定例です。

```lua
{
  "gyopei/seiren.nvim",
  build = "npm install",
  ft = "markdown",
  config = function()
    require("seiren").setup()

    vim.keymap.set("n", "<leader>mp", "<cmd>SeirenPreview<cr>", {
      desc = "Preview Mermaid diagram",
    })

    vim.keymap.set("n", "<leader>mP", "<cmd>SeirenPreviewImage<cr>", {
      desc = "Preview Mermaid diagram as image",
    })
  end,
}
```

ローカル開発中の設定例です。

```lua
{
  dir = "/home/amag/work/sandbox/seiren",
  build = "npm install",
  ft = "markdown",
  config = function()
    require("seiren").setup()

    vim.keymap.set("n", "<leader>mp", "<cmd>SeirenPreview<cr>", {
      desc = "Preview Mermaid diagram",
    })

    vim.keymap.set("n", "<leader>mP", "<cmd>SeirenPreviewImage<cr>", {
      desc = "Preview Mermaid diagram as image",
    })
  end,
}
```

## Usage

- `:SeirenPreview`: カーソル位置の Mermaid fence を preview します。カーソルが
  diagram 外にある場合は、カーソルより前の直近の Mermaid fence を使います。
- `:SeirenPreviewImage`: experimental。Mermaid diagram を PNG に変換し、
  `snacks.nvim` の image viewer に渡します。
- `:SeirenClose`: preview floating window を閉じます。
- `:SeirenToggle`: preview floating window を開閉します。
- `:checkhealth seiren`: Node.js、renderer runner、package import、sample render を確認します。

normal mode で `<leader>mp` から preview を開く例です。

```lua
vim.keymap.set("n", "<leader>mp", "<cmd>SeirenPreview<cr>", {
  desc = "Preview Mermaid diagram",
})
```

image preview も試す場合:

```lua
vim.keymap.set("n", "<leader>mP", "<cmd>SeirenPreviewImage<cr>", {
  desc = "Preview Mermaid diagram as image",
})
```

## Current limitations

- `seiren.nvim` is not a full Markdown document preview. The current default is
  diagram context preview: heading, diagram type, line number, short surrounding
  text, and the selected Mermaid diagram.
- Japanese Legend fallback is not implemented yet. Japanese labels are rendered
  by the configured Mermaid backend as-is.
- When a renderer fails or required runtime dependencies are missing,
  `seiren.nvim` falls back to showing the original Mermaid source.

image preview は experimental です。表示には `snacks.nvim` の image 機能が必要です。
Mermaid から PNG への変換には `@mermaid-js/mermaid-cli` を使います。

```lua
{
  "folke/snacks.nvim",
  opts = {
    image = {},
  },
}
```

Ghostty + tmux で使う場合、tmux の passthrough 設定が必要になることがあります。
Linux 環境で Chromium sandbox の問題を避けるため、既定では plugin-local の
`scripts/puppeteer-config.json` を `mmdc` に渡します。

### Image preview limitations

Image preview is experimental and is intended for checking the rendered diagram
when the text preview is not enough. For regular editing, `:SeirenPreview` is
the lighter default path.

Image preview depends on `@mermaid-js/mermaid-cli`, Chromium/Puppeteer,
`snacks.nvim` image support, and terminal image protocol support. If image
preview fails, check `:checkhealth seiren`, confirm that the Mermaid source is
valid for official Mermaid syntax, and fall back to `:SeirenPreview`.

Set `image.debug_timing = true` to inspect cache hit/miss, render time, viewer
time, and total image preview time in your environment.

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
  image = {
    enabled = false,
    renderer = "mermaid_cli",
    viewer = "snacks",
    format = "png",
    background = "white",
    mmdc_command = nil,
    puppeteer_config_path = nil,
    debug_timing = false,
    window = {
      fit = true,
      max_width_ratio = 0.8,
      max_height_ratio = 0.8,
      min_width = 20,
      min_height = 8,
      padding = 0,
      pixels_per_cell_width = 10,
      pixels_per_cell_height = 20,
    },
  },
  debounce_ms = 200,
})
```

## Development

Lua test suite を実行します。

```sh
nvim --headless -u tests/minimal_init.lua -c "lua dofile('tests/run.lua')" -c qa
```

renderer evaluation snapshot を再生成します。

```sh
npm run eval:renderers
```

`docs/research/renderer-eval/` 以下の出力は、初期 renderer 選定のための調査
snapshot です。MVP 実装後は、必要に応じて自動テストに置き換えるか、判断根拠を
別の場所に残したうえで削除できます。
