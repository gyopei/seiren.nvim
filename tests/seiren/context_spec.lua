describe("seiren.context", function()
  it("formats diagram context and rendered lines", function()
    local context = require("seiren.context")

    local lines = context.format({
      heading = "Architecture",
      type = "flowchart",
      start_line = 4,
      before_lines = { "before diagram" },
      after_lines = { "after diagram" },
    }, {
      "A --> B",
    }, {
      preview = {
        context_max_width = 80,
      },
    })

    assert_deep_equal(lines, {
      "# Architecture",
      "Mermaid: flowchart at line 4",
      "",
      "before diagram",
      "",
      "A --> B",
      "",
      "after diagram",
    })
  end)

  it("trims context lines to configured width", function()
    local context = require("seiren.context")

    local lines = context.format({
      start_line = 1,
      before_lines = { "1234567890" },
      after_lines = {},
    }, {}, {
      preview = {
        context_max_width = 5,
      },
    })

    assert_equal(lines[3], "1234…")
  end)
end)

