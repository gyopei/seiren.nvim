#!/usr/bin/env sh
set -u

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FIXTURE_DIR="$ROOT_DIR/fixtures/mermaid"
OUT_DIR="$ROOT_DIR/docs/research/renderer-eval"

mkdir -p "$OUT_DIR/mermaid-ascii" "$OUT_DIR/beautiful-mermaid"

normalize_stderr() {
  file=$1

  if [ -s "$file" ]; then
    sed 's/^time="[^"]*" level=/level=/' "$file" > "$file.tmp" &&
      mv "$file.tmp" "$file"
  fi
}

for fixture in "$FIXTURE_DIR"/*.mmd; do
  name=$(basename "$fixture" .mmd)

  "$ROOT_DIR/.tools/bin/mermaid-ascii" --file "$fixture" \
    > "$OUT_DIR/mermaid-ascii/$name.stdout.txt" \
    2> "$OUT_DIR/mermaid-ascii/$name.stderr.txt"
  printf "%s\n" "$?" > "$OUT_DIR/mermaid-ascii/$name.exitcode"
  normalize_stderr "$OUT_DIR/mermaid-ascii/$name.stderr.txt"

  node "$ROOT_DIR/scripts/render-beautiful-mermaid.mjs" "$fixture" \
    > "$OUT_DIR/beautiful-mermaid/$name.stdout.txt" \
    2> "$OUT_DIR/beautiful-mermaid/$name.stderr.txt"
  printf "%s\n" "$?" > "$OUT_DIR/beautiful-mermaid/$name.exitcode"
done
