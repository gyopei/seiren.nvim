local preview_window = require("seiren.preview")
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

local function image_markdown_lines(image_path, layout)
  local row = layout and layout.image and layout.image.row or 0
  local column = layout and layout.image and layout.image.column or 0
  local lines = {}

  for _ = 1, row do
    table.insert(lines, "")
  end

  table.insert(lines, string.rep(" ", column) .. string.format("![Mermaid diagram](%s)", image_path))
  return lines
end

function M.show(image_path, options, deps)
  deps = deps or {}
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

  local resolver = deps.image_window or image_window
  local layout = resolver.resolve and resolver.resolve(image_path, options or {}) or resolver.layout(image_path, options or {})
  local window_options = layout and { preview = layout.preview } or {}
  local preview_options = vim.tbl_deep_extend("force", options or {}, window_options)

  preview_window.open(image_markdown_lines(image_path, layout), preview_options)
  local bufnr = vim.api.nvim_get_current_buf()
  vim.bo[bufnr].filetype = "markdown"
  if layout and layout.image then
    vim.api.nvim_win_set_cursor(0, { layout.image.row + 1, layout.image.column })
  end

  for _, key in ipairs({ "h", "l", "<Left>", "<Right>" }) do
    vim.keymap.set("n", key, "<Nop>", {
      buffer = bufnr,
      silent = true,
      nowait = true,
    })
  end

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
