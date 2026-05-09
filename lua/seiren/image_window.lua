local M = {}

local png_signature = string.char(137, 80, 78, 71, 13, 10, 26, 10)

local function read_bytes(path, length)
  local fd = vim.uv.fs_open(path, "r", 438)
  if not fd then
    return nil
  end

  local data = vim.uv.fs_read(fd, length, 0)
  vim.uv.fs_close(fd)
  return data
end

local function uint32_be(text, offset)
  local b1, b2, b3, b4 = text:byte(offset, offset + 3)
  if not b1 or not b2 or not b3 or not b4 then
    return nil
  end

  return ((b1 * 256 + b2) * 256 + b3) * 256 + b4
end

local function clamp(value, min_value, max_value)
  return math.max(min_value, math.min(max_value, value))
end

function M.png_dimensions(path, deps)
  deps = deps or {}
  local read = deps.read or read_bytes
  local header = read(path, 24)

  if not header or #header < 24 then
    return nil
  end

  if header:sub(1, 8) ~= png_signature or header:sub(13, 16) ~= "IHDR" then
    return nil
  end

  local width = uint32_be(header, 17)
  local height = uint32_be(header, 21)
  if not width or not height or width <= 0 or height <= 0 then
    return nil
  end

  return {
    width = width,
    height = height,
  }
end

function M.fit(dimensions, options, editor)
  if not dimensions then
    return nil
  end

  options = options or {}
  editor = editor or {}

  local image = options.image or {}
  local window = image.window or {}

  if window.fit == false then
    return nil
  end

  local columns = editor.columns or vim.o.columns
  local lines = editor.lines or vim.o.lines
  local max_width = math.floor(columns * (window.max_width_ratio or 0.8))
  local max_height = math.floor(lines * (window.max_height_ratio or 0.8))
  local min_width = window.min_width or 20
  local min_height = window.min_height or 8
  local padding = window.padding or 2
  local pixels_per_cell_width = window.pixels_per_cell_width or 10
  local pixels_per_cell_height = window.pixels_per_cell_height or 20

  local width = math.ceil(dimensions.width / pixels_per_cell_width) + padding * 2
  local height = math.ceil(dimensions.height / pixels_per_cell_height) + padding * 2

  return {
    width = clamp(width, min_width, max_width),
    height = clamp(height, min_height, max_height),
  }
end

function M.layout(dimensions, options, editor)
  if not dimensions then
    return nil
  end

  options = options or {}
  local image = options.image or {}
  local window = image.window or {}
  local pixels_per_cell_width = window.pixels_per_cell_width or 10
  local pixels_per_cell_height = window.pixels_per_cell_height or 20
  local size = M.fit(dimensions, options, editor)

  if not size then
    return nil
  end

  local image_width = math.ceil(dimensions.width / pixels_per_cell_width)
  local image_height = math.ceil(dimensions.height / pixels_per_cell_height)
  local width_scale = size.width / image_width
  local height_scale = size.height / image_height
  local scale = math.min(width_scale, height_scale)
  local min_readable_scale = window.min_readable_scale or 0.25
  local large_action = window.large_image or "summary"
  local large = large_action ~= "fit" and scale < min_readable_scale

  return {
    preview = size,
    image = {
      column = math.max(0, math.floor((size.width - image_width) / 2)),
      row = math.max(0, math.floor((size.height - image_height) / 2)),
    },
    natural = {
      width = image_width,
      height = image_height,
    },
    scale = scale,
    large = large,
    large_action = large_action,
  }
end

function M.options(image_path, options, deps)
  local dimensions = M.png_dimensions(image_path, deps)
  local layout = M.layout(dimensions, options, deps and deps.editor)
  if not layout then
    return {}
  end

  return {
    preview = layout.preview,
  }
end

function M.resolve(image_path, options, deps)
  local dimensions = M.png_dimensions(image_path, deps)
  return M.layout(dimensions, options, deps and deps.editor)
end

return M
