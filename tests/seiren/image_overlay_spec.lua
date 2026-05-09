describe("seiren.image_overlay", function()
  it("places image floats above the Mermaid block inside the text area", function()
    local image_overlay = require("seiren.image_overlay")

    assert_deep_equal(image_overlay.placement({
      start_line = 10,
    }, 42, {
      preview = {
        width = 100,
        height = 8,
      },
    }, {
      topline = function(winid)
        assert_equal(winid, 42)
        return 3
      end,
      textoff = function(winid)
        assert_equal(winid, 42)
        return 6
      end,
      winwidth = function(winid)
        assert_equal(winid, 42)
        return 80
      end,
    }), {
      preview = {
        focus = false,
        width = 74,
        height = 8,
        float = {
          relative = "win",
          win = 42,
          anchor = "SW",
          row = 7,
          col = 6,
        },
      },
    })
  end)

  it("closes the overlay when the source cursor moves", function()
    local image_overlay = require("seiren.image_overlay")

    local source_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(source_bufnr)
    vim.api.nvim_buf_set_lines(source_bufnr, 0, -1, false, {
      "one",
      "two",
    })
    local source_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(source_win, { 1, 0 })

    local close_count = 0
    image_overlay.attach_lifecycle(source_win, { 1, 0 }, {
      close = function()
        close_count = close_count + 1
      end,
    })

    vim.api.nvim_win_set_cursor(source_win, { 2, 0 })
    vim.api.nvim_exec_autocmds("CursorMoved", {
      buffer = source_bufnr,
      modeline = false,
    })

    assert_equal(close_count, 1)
  end)
end)
