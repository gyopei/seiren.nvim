describe("seiren.config", function()
  it("returns default configuration", function()
    local config = require("seiren.config")

    config.reset()

    assert_deep_equal(config.get(), {
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
  end)

  it("deep merges user configuration without mutating defaults", function()
    local config = require("seiren.config")

    config.reset()
    config.setup({
      preview = {
        wrap = true,
        context_lines = 3,
      },
      mermaid = {
        backend = "source",
      },
      image = {
        enabled = true,
        viewer = "snacks",
      },
    })

    local options = config.get()
    assert_equal(options.preview.window, "float")
    assert_equal(options.preview.wrap, true)
    assert_equal(options.preview.context_lines, 3)
    assert_equal(options.mermaid.backend, "source")
    assert_equal(options.mermaid.node_command, "node")
    assert_equal(options.image.enabled, true)
    assert_equal(options.image.renderer, "mermaid_cli")
    assert_equal(options.image.viewer, "snacks")

    config.reset()
    assert_equal(config.get().preview.wrap, false)
    assert_equal(config.get().image.enabled, false)
  end)
end)
