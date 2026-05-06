describe("seiren.parser", function()
  local function buffer(lines)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
    return bufnr
  end

  it("extracts Mermaid fences with surrounding context", function()
    local parser = require("seiren.parser")
    local bufnr = buffer({
      "# Architecture",
      "",
      "before diagram",
      "```mermaid",
      "flowchart TD",
      "  A --> B",
      "```",
      "after diagram",
    })

    local blocks = parser.extract(bufnr, {
      preview = {
        context_lines = 1,
      },
    })

    assert_equal(#blocks, 1)
    assert_equal(blocks[1].start_line, 4)
    assert_equal(blocks[1].end_line, 7)
    assert_equal(blocks[1].type, "flowchart")
    assert_equal(blocks[1].heading, "Architecture")
    assert_equal(blocks[1].source, "flowchart TD\n  A --> B")
    assert_deep_equal(blocks[1].before_lines, { "before diagram" })
    assert_deep_equal(blocks[1].after_lines, { "after diagram" })
  end)

  it("selects the block under cursor or the previous block", function()
    local parser = require("seiren.parser")
    local bufnr = buffer({
      "```mermaid",
      "flowchart TD",
      "  A --> B",
      "```",
      "",
      "text",
      "",
      "```mermaid",
      "sequenceDiagram",
      "  A->>B: hello",
      "```",
    })

    local first = parser.select(bufnr, 2, {})
    assert_equal(first.start_line, 1)
    assert_equal(first.type, "flowchart")

    local previous = parser.select(bufnr, 7, {})
    assert_equal(previous.start_line, 1)

    local second = parser.select(bufnr, 10, {})
    assert_equal(second.start_line, 8)
    assert_equal(second.type, "sequenceDiagram")
  end)

  it("ignores non-Mermaid fences", function()
    local parser = require("seiren.parser")
    local bufnr = buffer({
      "```lua",
      "print('hello')",
      "```",
    })

    assert_equal(#parser.extract(bufnr, {}), 0)
  end)
end)

