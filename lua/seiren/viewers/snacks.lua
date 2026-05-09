local preview_window = require("seiren.preview")
local image_overlay = require("seiren.image_overlay")
local image_window = require("seiren.image_window")

local M = {}

local function snacks_image()
  if _G.Snacks and _G.Snacks.image then
    return _G.Snacks.image
  end

  local ok, snacks = pcall(require, "snacks")
  if ok and snacks and snacks.image then
    return snacks.image
  end

  return nil
end

local function set_image_buffer(bufnr)
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "" })
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
  vim.api.nvim_set_option_value("filetype", "image", { buf = bufnr })
end

local function large_image_summary(image_path, layout)
  local dimensions = layout and layout.dimensions
  local natural = layout and layout.natural or {}
  local preview = layout and layout.preview or {}
  local scale = layout and layout.scale

  return {
    "Mermaid image is too large for useful preview",
    "",
    "Generated image: " .. image_path,
    dimensions and string.format("Image pixels: %d x %d", dimensions.width, dimensions.height) or "Image pixels: unknown",
    string.format("Natural cells: %s x %s", natural.width or "unknown", natural.height or "unknown"),
    string.format("Preview cells: %s x %s", preview.width or "unknown", preview.height or "unknown"),
    string.format("Scale: %.3f", scale or 0),
    "",
    "Use :SeirenPreview for text/source preview, or open the generated PNG externally.",
  }
end

function M.show(image_path, options, deps)
  deps = deps or {}
  local image = snacks_image()
  if not image or not image.placement or not image.placement.new then
    return {
      ok = false,
      error = "snacks.nvim image viewer is not available",
    }
  end

  if image.supports and not image.supports(image_path) then
    return {
      ok = false,
      error = "snacks.nvim image viewer does not support this image or terminal",
    }
  end

  local resolver = deps.image_window or image_window
  local layout = resolver.resolve and resolver.resolve(image_path, options or {}) or resolver.layout(image_path, options or {})
  if layout and layout.large and layout.large_action == "summary" then
    preview_window.open(large_image_summary(image_path, layout), options)
    return {
      ok = true,
      close = function()
        preview_window.close()
      end,
    }
  end

  local overlay = deps.image_overlay or image_overlay
  local window_options = overlay.placement(
    deps.block,
    deps.source_win or vim.api.nvim_get_current_win(),
    layout,
    options or {}
  )
  local preview_options = vim.tbl_deep_extend("force", options or {}, window_options)

  preview_window.open({ "" }, preview_options)
  local bufnr = preview_window.get_bufnr()
  set_image_buffer(bufnr)

  local ok, placement = pcall(image.placement.new, bufnr, image_path, {
    pos = { 1, 0 },
    width = preview_options.preview and preview_options.preview.width,
    height = preview_options.preview and preview_options.preview.height,
    inline = false,
    auto_resize = false,
  })
  if not ok then
    return {
      ok = false,
      error = tostring(placement),
    }
  end

  if deps.source_win and vim.api.nvim_win_is_valid(deps.source_win) then
    vim.api.nvim_set_current_win(deps.source_win)
  end

  return {
    ok = true,
    close = function()
      if placement and placement.close then
        pcall(function()
          placement:close()
        end)
      end
      preview_window.close()
    end,
  }
end

return M
