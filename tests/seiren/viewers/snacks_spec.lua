describe("seiren.viewers.snacks", function()
  it("opens an unfocused overlay and places the image without Snacks.image.hover", function()
    package.loaded["seiren.viewers.snacks"] = nil

    local placement
    local supports_path
    local hover_called = false
    local source_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(source_bufnr)
    local source_win = vim.api.nvim_get_current_win()

    _G.Snacks = {
      image = {
        supports = function(path)
          supports_path = path
          return true
        end,
        hover = function()
          hover_called = true
        end,
        placement = {
          new = function(bufnr, path, opts)
            placement = {
              bufnr = bufnr,
              path = path,
              opts = opts,
            }
            return {
              update = function() end,
              close = function() end,
            }
          end,
        },
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
      image_overlay = {
        placement = function(block, winid, layout)
          assert_equal(block.start_line, 8)
          assert_equal(winid, source_win)
          assert_equal(layout.preview.width, 42)
          return {
            preview = {
              focus = false,
              width = 42,
              height = 12,
              float = {
                relative = "win",
                win = source_win,
                anchor = "SW",
                row = 3,
                col = 4,
              },
            },
          }
        end,
      },
      block = {
        start_line = 8,
      },
      source_win = source_win,
      source_cursor = { 1, 0 },
    })

    assert_equal(result.ok, true)
    assert_equal(supports_path, "/tmp/seiren-image.png")
    assert_equal(hover_called, false)
    assert_equal(vim.api.nvim_get_current_win(), source_win)

    local preview = require("seiren.preview")
    assert_equal(placement.bufnr, preview.get_bufnr())
    assert_equal(placement.path, "/tmp/seiren-image.png")
    assert_deep_equal(placement.opts.pos, { 1, 0 })
    assert_equal(placement.opts.width, 42)
    assert_equal(placement.opts.height, 12)
    assert_equal(vim.bo[preview.get_bufnr()].filetype, "image")

    local config = vim.api.nvim_win_get_config(preview.get_winid())
    assert_equal(config.relative, "win")
    assert_equal(config.win, source_win)
    assert_equal(config.row, 3)
    assert_equal(config.col, 4)
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
