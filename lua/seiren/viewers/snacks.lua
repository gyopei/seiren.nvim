local preview_window = require("seiren.preview")

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

function M.show(image_path, options)
  local image = snacks_image()
  if not image or not image.hover then
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

  preview_window.open({ string.format("![Mermaid diagram](%s)", image_path) }, options)
  vim.bo[vim.api.nvim_get_current_buf()].filetype = "markdown"

  local ok, err = pcall(image.hover)
  if not ok then
    return {
      ok = false,
      error = tostring(err),
    }
  end

  return {
    ok = true,
  }
end

return M

