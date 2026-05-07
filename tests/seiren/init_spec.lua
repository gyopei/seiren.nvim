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
    package.loaded["seiren.image_cache"] = nil

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
    package.loaded["seiren.image_cache"] = nil

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

  it("reuses a cached image for the same Mermaid source during the session", function()
    package.loaded["seiren"] = nil
    package.loaded["seiren.config"] = nil
    package.loaded["seiren.image_cache"] = nil

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      "```mermaid",
      "flowchart TD",
      "  A --> B",
      "```",
    })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })

    local render_count = 0
    local viewed_paths = {}
    local seiren = require("seiren")
    seiren.setup()

    local deps = {
      image_backend = {
        render = function()
          render_count = render_count + 1
          return {
            ok = true,
            image_path = "/tmp/seiren-image-" .. render_count .. ".png",
          }
        end,
      },
      viewer = {
        show = function(image_path)
          table.insert(viewed_paths, image_path)
          return {
            ok = true,
          }
        end,
      },
    }

    seiren.preview_image(deps)
    seiren.preview_image(deps)

    assert_equal(render_count, 1)
    assert_deep_equal(viewed_paths, {
      "/tmp/seiren-image-1.png",
      "/tmp/seiren-image-1.png",
    })

    seiren.close()
  end)

  it("renders a new cached image when Mermaid source changes", function()
    package.loaded["seiren"] = nil
    package.loaded["seiren.config"] = nil
    package.loaded["seiren.image_cache"] = nil

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      "```mermaid",
      "flowchart TD",
      "  A --> B",
      "```",
    })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })

    local render_count = 0
    local viewed_paths = {}
    local seiren = require("seiren")
    seiren.setup()

    local deps = {
      image_backend = {
        render = function()
          render_count = render_count + 1
          return {
            ok = true,
            image_path = "/tmp/seiren-image-" .. render_count .. ".png",
          }
        end,
      },
      viewer = {
        show = function(image_path)
          table.insert(viewed_paths, image_path)
          return {
            ok = true,
          }
        end,
      },
    }

    seiren.preview_image(deps)
    vim.api.nvim_buf_set_lines(bufnr, 2, 3, false, { "  B --> C" })
    seiren.preview_image(deps)

    assert_equal(render_count, 2)
    assert_deep_equal(viewed_paths, {
      "/tmp/seiren-image-1.png",
      "/tmp/seiren-image-2.png",
    })

    seiren.close()
  end)

  it("keeps cached images on close and cleans them up on VimLeavePre", function()
    package.loaded["seiren"] = nil
    package.loaded["seiren.config"] = nil
    package.loaded["seiren.image_cache"] = nil

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      "```mermaid",
      "flowchart TD",
      "  A --> B",
      "```",
    })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })

    local render_count = 0
    local deleted = {}
    local seiren = require("seiren")
    seiren.setup()

    local deps = {
      image_backend = {
        render = function()
          render_count = render_count + 1
          return {
            ok = true,
            image_path = "/tmp/seiren-image-" .. render_count .. ".png",
          }
        end,
      },
      viewer = {
        show = function()
          return {
            ok = true,
          }
        end,
      },
      delete = function(path)
        table.insert(deleted, path)
      end,
    }

    seiren.preview_image(deps)
    vim.api.nvim_buf_set_lines(bufnr, 2, 3, false, { "  B --> C" })
    seiren.preview_image(deps)
    seiren.close()

    assert_deep_equal(deleted, {})

    vim.api.nvim_exec_autocmds("VimLeavePre", {
      group = "seiren_cleanup",
      modeline = false,
    })

    table.sort(deleted)
    assert_deep_equal(deleted, {
      "/tmp/seiren-image-1.png",
      "/tmp/seiren-image-2.png",
    })
  end)

  it("keeps a cached image when a later image render fails", function()
    package.loaded["seiren"] = nil
    package.loaded["seiren.config"] = nil
    package.loaded["seiren.image_cache"] = nil

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      "```mermaid",
      "flowchart TD",
      "  A --> B",
      "```",
    })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })

    local render_count = 0
    local deleted = {}
    local viewed_paths = {}
    local seiren = require("seiren")
    seiren.setup()

    seiren.preview_image({
      image_backend = {
        render = function()
          return {
            ok = true,
            image_path = "/tmp/seiren-image.png",
          }
        end,
      },
      viewer = {
        show = function(image_path)
          table.insert(viewed_paths, image_path)
          return {
            ok = true,
          }
        end,
      },
      delete = function(path)
        table.insert(deleted, path)
      end,
    })

    vim.api.nvim_buf_set_lines(bufnr, 2, 3, false, { "  B --> C" })
    seiren.preview_image({
      image_backend = {
        render = function()
          render_count = render_count + 1
          return {
            ok = false,
            lines = { "Image renderer error: failed" },
          }
        end,
      },
      delete = function(path)
        table.insert(deleted, path)
      end,
    })

    assert_equal(render_count, 1)
    assert_deep_equal(viewed_paths, { "/tmp/seiren-image.png" })
    assert_deep_equal(deleted, {})

    vim.api.nvim_exec_autocmds("VimLeavePre", {
      group = "seiren_cleanup",
      modeline = false,
    })

    assert_deep_equal(deleted, { "/tmp/seiren-image.png" })
  end)
end)
