describe("seiren.preview", function()
  it("opens and closes a focused float", function()
    local preview = require("seiren.preview")

    preview.open({ "hello", "world" }, {
      preview = {
        wrap = false,
      },
    })

    assert_equal(preview.is_open(), true)
    local bufnr = preview.get_bufnr()
    local winid = preview.get_winid()

    assert_equal(vim.api.nvim_get_current_win(), winid)
    assert_equal(vim.wo[winid].wrap, false)
    assert_deep_equal(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), { "hello", "world" })

    preview.close()
    assert_equal(preview.is_open(), false)
  end)

  it("normalizes accidental newline-containing line items", function()
    local preview = require("seiren.preview")

    preview.open({ "one\ntwo", "three" }, {
      preview = {
        wrap = false,
      },
    })

    assert_deep_equal(vim.api.nvim_buf_get_lines(preview.get_bufnr(), 0, -1, false), {
      "one",
      "two",
      "three",
    })

    preview.close()
  end)

  it("disables diagnostics in the preview buffer", function()
    local preview = require("seiren.preview")

    preview.open({ "# Preview" }, {
      preview = {
        wrap = false,
      },
    })

    assert_equal(vim.diagnostic.is_enabled({ bufnr = preview.get_bufnr() }), false)

    preview.close()
  end)

  it("uses explicit preview dimensions when provided", function()
    local preview = require("seiren.preview")

    preview.open({ "sized" }, {
      preview = {
        wrap = false,
        width = 32,
        height = 9,
      },
    })

    local config = vim.api.nvim_win_get_config(preview.get_winid())
    assert_equal(config.width, 32)
    assert_equal(config.height, 9)

    preview.close()
  end)

  it("can open an unfocused float with explicit placement", function()
    local preview = require("seiren.preview")
    local source_win = vim.api.nvim_get_current_win()

    preview.open({ "hover" }, {
      preview = {
        wrap = false,
        focus = false,
        width = 18,
        height = 4,
        float = {
          relative = "win",
          row = -5,
          col = 0,
          anchor = "NW",
        },
      },
    })

    assert_equal(vim.api.nvim_get_current_win(), source_win)
    local config = vim.api.nvim_win_get_config(preview.get_winid())
    assert_equal(config.relative, "win")
    assert_equal(config.row, -5)
    assert_equal(config.col, 0)
    assert_equal(config.anchor, "NW")
    assert_equal(config.width, 18)
    assert_equal(config.height, 4)

    preview.close()
  end)
end)
