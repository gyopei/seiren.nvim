import { readFileSync } from "node:fs";
import { renderMermaidASCII } from "beautiful-mermaid";

const inputPath = process.argv[2];

if (!inputPath) {
  console.error("Usage: node scripts/render-beautiful-mermaid.mjs <file.mmd>");
  process.exit(2);
}

try {
  const source = readFileSync(inputPath, "utf8");
  const output = renderMermaidASCII(source, { useAscii: false });
  process.stdout.write(output.endsWith("\n") ? output : `${output}\n`);
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
