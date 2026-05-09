describe("seiren.image_window", function()
  it("reads PNG dimensions from the IHDR header", function()
    local image_window = require("seiren.image_window")
    local png_header = table.concat({
      string.char(137, 80, 78, 71, 13, 10, 26, 10),
      string.char(0, 0, 0, 13),
      "IHDR",
      string.char(0, 0, 1, 144),
      string.char(0, 0, 0, 240),
    })

    assert_deep_equal(image_window.png_dimensions("/tmp/image.png", {
      read = function(path, length)
        assert_equal(path, "/tmp/image.png")
        assert_equal(length, 24)
        return png_header
      end,
    }), {
      width = 400,
      height = 240,
    })
  end)

  it("returns nil when the file is not a PNG", function()
    local image_window = require("seiren.image_window")

    assert_equal(image_window.png_dimensions("/tmp/image.txt", {
      read = function()
        return "not a png"
      end,
    }), nil)
  end)

  it("fits image dimensions into editor cells", function()
    local image_window = require("seiren.image_window")

    assert_deep_equal(image_window.fit({
      width = 320,
      height = 120,
    }, {
      image = {
        window = {
          pixels_per_cell_width = 10,
          pixels_per_cell_height = 20,
          padding = 0,
          min_width = 20,
          min_height = 8,
          max_width_ratio = 0.8,
          max_height_ratio = 0.8,
        },
      },
    }, {
      columns = 100,
      lines = 40,
    }), {
      width = 32,
      height = 8,
    })
  end)

  it("clamps oversized images to the configured editor ratios", function()
    local image_window = require("seiren.image_window")

    assert_deep_equal(image_window.fit({
      width = 4000,
      height = 3000,
    }, {
      image = {
        window = {
          pixels_per_cell_width = 10,
          pixels_per_cell_height = 20,
          padding = 0,
          min_width = 20,
          min_height = 8,
          max_width_ratio = 0.8,
          max_height_ratio = 0.8,
        },
      },
    }, {
      columns = 100,
      lines = 40,
    }), {
      width = 80,
      height = 32,
    })
  end)

  it("calculates centered content padding for the fitted window", function()
    local image_window = require("seiren.image_window")

    assert_deep_equal(image_window.layout({
      width = 320,
      height = 120,
    }, {
      image = {
        window = {
          pixels_per_cell_width = 10,
          pixels_per_cell_height = 20,
          padding = 0,
          min_width = 20,
          min_height = 8,
          max_width_ratio = 0.8,
          max_height_ratio = 0.8,
        },
      },
    }, {
      columns = 100,
      lines = 40,
    }), {
      preview = {
        width = 32,
        height = 8,
      },
      image = {
        column = 0,
        row = 1,
      },
    })
  end)

  it("centers small images inside the minimum window size", function()
    local image_window = require("seiren.image_window")

    assert_deep_equal(image_window.layout({
      width = 80,
      height = 40,
    }, {
      image = {
        window = {
          pixels_per_cell_width = 10,
          pixels_per_cell_height = 20,
          padding = 0,
          min_width = 20,
          min_height = 8,
          max_width_ratio = 0.8,
          max_height_ratio = 0.8,
        },
      },
    }, {
      columns = 100,
      lines = 40,
    }), {
      preview = {
        width = 20,
        height = 8,
      },
      image = {
        column = 6,
        row = 3,
      },
    })
  end)
end)
