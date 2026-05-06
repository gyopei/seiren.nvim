describe("seiren init", function()
  it("setup registers user commands", function()
    package.loaded["seiren"] = nil
    package.loaded["seiren.config"] = nil

    require("seiren").setup()

    assert_truthy(vim.api.nvim_get_commands({})["SeirenPreview"])
    assert_truthy(vim.api.nvim_get_commands({})["SeirenPreviewImage"])
    assert_truthy(vim.api.nvim_get_commands({})["SeirenClose"])
    assert_truthy(vim.api.nvim_get_commands({})["SeirenToggle"])
  end)

  it("previews the cursor-selected Mermaid block", function()
    package.loaded["seiren"] = nil
    package.loaded["seiren.config"] = nil

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      "# Example",
      "",
      "```mermaid",
      "flowchart TD",
      "  A --> B",
      "```",
    })
    vim.api.nvim_win_set_cursor(0, { 4, 0 })

    local seiren = require("seiren")
    seiren.setup({
      mermaid = {
        backend = "source",
      },
    })
    seiren.preview()

    local preview = require("seiren.preview")
    local preview_bufnr = preview.get_bufnr()
    local lines = vim.api.nvim_buf_get_lines(preview_bufnr, 0, -1, false)

    assert_deep_equal(lines, {
      "# Example",
      "Mermaid: flowchart at line 3",
      "",
      "```mermaid",
      "flowchart TD",
      "  A --> B",
      "```",
    })

    seiren.close()
  end)

  it("previews the cursor-selected Mermaid block as an image", function()
    package.loaded["seiren"] = nil
    package.loaded["seiren.config"] = nil

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      "# Example",
      "",
      "```mermaid",
      "flowchart TD",
      "  A --> B",
      "```",
    })
    vim.api.nvim_win_set_cursor(0, { 4, 0 })

    local viewed_path
    local seiren = require("seiren")
    seiren.setup()
    seiren.preview_image({
      image_backend = {
        render = function(block)
          assert_equal(block.source, "flowchart TD\n  A --> B")
          return {
            ok = true,
            image_path = "/tmp/seiren-image.png",
          }
        end,
      },
      viewer = {
        show = function(image_path)
          viewed_path = image_path
          return {
            ok = true,
          }
        end,
      },
    })

    assert_equal(viewed_path, "/tmp/seiren-image.png")
  end)

  it("falls back to text preview when image rendering fails", function()
    package.loaded["seiren"] = nil
    package.loaded["seiren.config"] = nil

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      "```mermaid",
      "flowchart TD",
      "  A --> B",
      "```",
    })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })

    local seiren = require("seiren")
    seiren.setup()
    seiren.preview_image({
      image_backend = {
        render = function()
          return {
            ok = false,
            lines = {
              "Image renderer error: failed",
              "",
              "```mermaid",
              "flowchart TD",
              "  A --> B",
              "```",
            },
          }
        end,
      },
    })

    local preview = require("seiren.preview")
    assert_deep_equal(vim.api.nvim_buf_get_lines(preview.get_bufnr(), 0, -1, false), {
      "Mermaid: flowchart at line 1",
      "",
      "Image renderer error: failed",
      "",
      "```mermaid",
      "flowchart TD",
      "  A --> B",
      "```",
    })

    seiren.close()
  end)
end)
