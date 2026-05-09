describe("seiren.viewers.snacks", function()
  it("opens a markdown image reference, locks horizontal movement, and calls Snacks.image.hover", function()
    package.loaded["seiren.viewers.snacks"] = nil

    local hover_cursor
    local supports_path
    _G.Snacks = {
      image = {
        supports = function(path)
          supports_path = path
          return true
        end,
        hover = function()
          hover_cursor = vim.api.nvim_win_get_cursor(0)
        end,
      },
    }

    local viewer = require("seiren.viewers.snacks")
    local result = viewer.show("/tmp/seiren-image.png", nil, {
      image_window = {
        layout = function(path)
          assert_equal(path, "/tmp/seiren-image.png")
          return {
            preview = {
              width = 42,
              height = 12,
            },
            image = {
              row = 3,
              column = 5,
            },
          }
        end,
      },
    })

    assert_equal(result.ok, true)
    assert_equal(supports_path, "/tmp/seiren-image.png")
    assert_deep_equal(hover_cursor, { 4, 5 })
    assert_equal(vim.bo[vim.api.nvim_get_current_buf()].filetype, "markdown")
    assert_deep_equal(vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, -1, false), {
      "",
      "",
      "",
      "     ![Mermaid diagram](/tmp/seiren-image.png)",
    })
    assert_equal(vim.fn.maparg("l", "n", false, true).buffer, 1)
    assert_equal(vim.fn.maparg("h", "n", false, true).buffer, 1)
    assert_equal(vim.fn.maparg("<Right>", "n", false, true).buffer, 1)
    assert_equal(vim.fn.maparg("<Left>", "n", false, true).buffer, 1)
    local config = vim.api.nvim_win_get_config(require("seiren.preview").get_winid())
    assert_equal(config.width, 42)
    assert_equal(config.height, 12)

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
