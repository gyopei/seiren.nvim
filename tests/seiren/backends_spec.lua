describe("seiren.backends", function()
  it("renders source fallback", function()
    local backends = require("seiren.backends")

    local result = backends.render({
      source = "flowchart TD\n  A --> B",
      type = "flowchart",
      start_line = 12,
    }, {
      mermaid = {
        backend = "source",
      },
    })

    assert_equal(result.ok, true)
    assert_deep_equal(result.lines, {
      "```mermaid",
      "flowchart TD",
      "  A --> B",
      "```",
    })
  end)

  it("falls back to source for unknown backends", function()
    local backends = require("seiren.backends")

    local result = backends.render({
      source = "sequenceDiagram\n  A->>B: hello",
    }, {
      mermaid = {
        backend = "missing_backend",
      },
    })

    assert_equal(result.ok, false)
    assert_equal(result.backend, "source")
    assert_truthy(result.error:find("unknown backend", 1, true))
    assert_deep_equal(result.lines, {
      "```mermaid",
      "sequenceDiagram",
      "  A->>B: hello",
      "```",
    })
  end)
end)

