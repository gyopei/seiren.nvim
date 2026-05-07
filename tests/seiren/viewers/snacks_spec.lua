describe("seiren.viewers.snacks", function()
  it("opens a markdown image reference and calls Snacks.image.hover", function()
    package.loaded["seiren.viewers.snacks"] = nil

    local hover_called = false
    local supports_path
    _G.Snacks = {
      image = {
        supports = function(path)
          supports_path = path
          return true
        end,
        hover = function()
          hover_called = true
        end,
      },
    }

    local viewer = require("seiren.viewers.snacks")
    local result = viewer.show("/tmp/seiren-image.png")

    assert_equal(result.ok, true)
    assert_equal(supports_path, "/tmp/seiren-image.png")
    assert_equal(hover_called, true)
    assert_equal(vim.bo[vim.api.nvim_get_current_buf()].filetype, "markdown")
    assert_equal(vim.b[vim.api.nvim_get_current_buf()].snacks_image_attached, true)
    assert_deep_equal(vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, -1, false), {
      "![Mermaid diagram](/tmp/seiren-image.png)",
    })

    _G.Snacks = nil
  end)

  it("reports missing snacks image support", function()
    package.loaded["seiren.viewers.snacks"] = nil
    _G.Snacks = nil

    local viewer = require("seiren.viewers.snacks")
    local result = viewer.show("/tmp/seiren-image.png")

    assert_equal(result.ok, false)
    assert_truthy(result.error:find("snacks.nvim image", 1, true))
  end)
end)
