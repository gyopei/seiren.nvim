local paths = require("seiren.paths")
local source_backend = require("seiren.backends.source")

local M = {}

local function split_lines(text)
  local lines = {}

  text = text or ""
  text = text:gsub("\r\n", "\n")
  if text:sub(-1) == "\n" then
    text = text:sub(1, -2)
  end

  if text == "" then
    return lines
  end

  for line in (text .. "\n"):gmatch("(.-)\n") do
    table.insert(lines, line)
  end

  return lines
end

local function fallback_lines(block, message)
  local fallback = source_backend.render(block)
  local lines = { "Image renderer error: " .. message, "" }

  vim.list_extend(lines, fallback.lines)
  return lines
end

local function temp_paths(tempname, format)
  local base = tempname()
  base = base:gsub("%.mmd$", ""):gsub("%." .. format .. "$", "")

  return base .. ".mmd", base .. "." .. format
end

function M.render(block, options, deps)
  options = options or {}
  deps = deps or {}

  local image = options.image or {}
  local format = image.format or "png"
  local mmdc = image.mmdc_command or (deps.mmdc_path or paths.mmdc_path)()
  local input_path, output_path = temp_paths(deps.tempname or vim.fn.tempname, format)
  local writefile = deps.writefile or vim.fn.writefile
  local delete = deps.delete or vim.fn.delete
  local system = deps.system or vim.system
  local plugin_root = (deps.plugin_root or paths.plugin_root)()

  writefile(split_lines(block and block.source or ""), input_path)

  local result = system({
    mmdc,
    "-i",
    input_path,
    "-o",
    output_path,
    "-b",
    "transparent",
  }, { text = true, cwd = plugin_root }):wait()

  delete(input_path)

  if result.code ~= 0 then
    local message = vim.trim(result.stderr or result.stdout or "image render failed")
    if message == "" then
      message = "image render failed"
    end

    return {
      ok = false,
      backend = "image",
      error = message,
      lines = fallback_lines(block, message),
    }
  end

  return {
    ok = true,
    backend = "image",
    format = format,
    image_path = output_path,
  }
end

return M

