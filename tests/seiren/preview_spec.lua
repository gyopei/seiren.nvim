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
end)
