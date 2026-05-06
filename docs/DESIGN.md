# Mermaid-first Markdown Preview Design

## 背景

このプロジェクトの主目的は、Neovim内でMarkdownを書きながら、Mermaid diagramをブラウザへ逃がさず確認できる preview 体験を作ることです。設計上はMarkdown preview pluginですが、技術検証と実装優先度はMermaid描画を先行します。

プロジェクト名は `seiren.nvim` とします。Mermaidにちなむ比喩的な名前を使い、説明文でMermaid-first Markdown previewであることを明示します。

## ゴール

- Markdown内の ```mermaid fence を検出し、float previewで表示する。
- MermaidをまずASCII/Unicodeで表示する。
- Mermaid周辺の見出しや前後文を短く整形し、diagram contextとして表示する。
- Lua製Neovim pluginとして提供し、外部rendererは差し替え可能にする。
- 依存が不足している環境でも、ソース表示やエラーメッセージで破綻しない。
- 個人利用を前提に、tmux + Ghosttyで動くことを初期ターゲットにする。

## 非ゴール

- Mermaid rendererをLuaでフル実装すること。
- ブラウザpreviewを主経路にすること。
- Node.js runtimeへの依存を避けること。
- 初期段階でGitHub MarkdownやObsidian記法を完全互換にすること。
- 初期段階で画像表示backendを実装すること。
- 初期段階でMarkdown全文を通常previewとして読むこと。
- すべてのターミナルで同じ表示品質を保証すること。

## 想定アーキテクチャ

```text
Markdown buffer
  -> parser
    -> diagram context
    -> mermaid blocks
  -> preview controller
    -> float window
  -> context formatter
  -> render backends
    -> ascii backend
    -> source fallback
```

### Parser

Markdown bufferからMermaid fenceと周辺contextを抽出します。MVPではTree-sitter markdownでMermaid fenceを検出し、直前の見出し、直前/直後の短い本文、diagram type、開始行を構造化して返します。将来的に `tree-sitter-mermaid` を使ってMermaid構文エラーやdiagram type判定を強化します。

### Context Formatter

parserが返したcontextをpreview用の短いテキストに整形します。preview bufferはMermaid図を壊さないため `wrap=false` を標準にするので、本文contextは `context_max_width` で切り詰めます。Markdown全文previewを追加する場合も、このformatterを差し替えるだけで済むようにします。

### Preview Controller

preview用buffer/windowの生成、更新、debounceを管理します。初期実装はfloatを標準にします。splitは後から設定で追加できるよう、window生成処理は分離します。

MVPではフォーカスありfloatを使います。初期UIは中央配置、画面の約80%幅/80%高、rounded border、`q` で閉じる形にします。ライブ更新はMVPの対象外です。明示的なコマンド実行時だけrenderし、将来split/pane modeを追加する場合に保存時再renderを検討します。

### Mermaid Backends

- `beautiful_mermaid`: Node.js runnerから `beautiful-mermaid` を呼び出し、Unicode box drawingをpreview bufferへ挿入する。MVPの第一backendとする。
- `mermaid_ascii`: `.tools/bin/mermaid-ascii` またはユーザー指定CLIを呼び出す比較/fallback用backend。
- `source`: rendererがない場合にMermaidソースを整形して表示する。

画像backendは第2段階以降で検討します。初期段階では `beautiful-mermaid` のASCII/Unicode出力、tmux + Ghosttyでの可読性、Node runner統合を優先して検証します。

renderer選定の評価基準は [TECH_SELECTION.md](./TECH_SELECTION.md) にまとめます。MVPでは `flowchart` と `sequenceDiagram` を必達とし、日本語幅がtmux + Ghosttyで破綻しないことを必須条件にします。

## MVP

1. `:SeirenPreview` で現在bufferのMermaid fenceを抽出する。
2. float preview bufferを開く。
3. plugin-local `beautiful-mermaid` runnerでASCII/Unicode描画する。
4. renderer失敗時はエラーと元ソースを表示する。
5. Markdown本文は全文previewせず、見出し、diagram type、開始行、前後contextだけ表示する。

Preview対象はcursor-basedです。カーソルがMermaid fence内にある場合はそのdiagramを対象にし、fence外にある場合は直前のMermaid fenceを対象にします。

MVP commands:

- `:SeirenPreview`: cursor対象のdiagramをrenderしてfloatを開く。既に開いている場合は更新する。
- `:SeirenClose`: preview floatを閉じる。
- `:SeirenToggle`: preview floatを開閉する。

## 設定案

```lua
require("seiren").setup({
  preview = {
    window = "float", -- "float" | "split"
    mode = "diagram_context",
    wrap = false,
    update = "manual", -- future: "save"
    context_lines = 1,
    context_max_width = 80,
  },
  mermaid = {
    backend = "beautiful_mermaid", -- "beautiful_mermaid" | "mermaid_ascii" | "source"
    node_command = "node",
    runner_path = nil,
    prefer_unicode = true,
    japanese_label_mode = "auto", -- "auto" | "inline" | "legend"
  },
  debounce_ms = 200,
})
```

## Runtime Dependencies

Node.js is required. `beautiful-mermaid` is installed as a plugin-local npm dependency through the plugin manager build step, for example `build = "npm install"`. Users do not need to install `beautiful-mermaid` globally. The renderer command path remains configurable for local experiments and fallback backends.

Tree-sitter markdown support is also expected. The MVP should use Tree-sitter from the beginning rather than a temporary line-based parser, because Mermaid fence selection and later parser extension are central to the plugin.

The README should use lazy.nvim as the primary installation example.

## Health Check Plan

`:checkhealth seiren` should verify that the plugin can actually render, not only that commands exist.

Required checks:

- Neovim version is supported.
- `node_command` is executable.
- Node.js version can be read.
- `scripts/render-beautiful-mermaid.mjs` exists.
- `beautiful-mermaid` can be imported by the runner.
- A small `flowchart` sample renders with non-empty output.
- A small `sequenceDiagram` sample renders with non-empty output.

Warnings:

- plugin-local `node_modules/beautiful-mermaid` is missing; suggest the plugin manager build step, such as `npm install`.
- `preview.wrap` is true, because soft wrapping can break diagram structure.
- configured backend, preview mode, window type, or Japanese label mode is unknown.

Info:

- tmux/Ghostty environment detection result.
- optional `mermaid-ascii` backend availability.
- resolved runner path and node command.

## 明確にしたい点

- READMEで `seiren.nvim` の説明をどの程度Markdown寄りにするか。
- 後続でMarkdown全文previewを入れる場合、diagram context modeとdocument modeをどう切り替えるか。

## 設計原則

- Mermaid rendering、Markdown parsing、context formatting、window managementを分ける。
- renderer backendは同じinterfaceで差し替えられるようにする。
- preview modeは `diagram_context` をMVPにし、将来 `document` を追加できる形にする。
- Mermaid図の構造保護を優先し、preview windowはMVPでは `wrap=false` を標準にする。
- 外部依存は自動でグローバルinstallせず、plugin-local dependency、設定override、health checkで扱う。
