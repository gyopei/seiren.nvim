local M = {}

local function trim_to_width(line, width)
  if not width or width <= 0 or vim.fn.strdisplaywidth(line) <= width then
    return line
  end

  local result = ""
  local char_count = vim.fn.strchars(line)

  for index = 0, char_count - 1 do
    local next_result = result .. vim.fn.strcharpart(line, index, 1)
    if vim.fn.strdisplaywidth(next_result .. "…") > width then
      return result .. "…"
    end
    result = next_result
  end

  return result
end

local function append_context(lines, context_lines, width)
  for _, line in ipairs(context_lines or {}) do
    table.insert(lines, trim_to_width(line, width))
  end
end

local function append_lines(lines, source_lines)
  for _, item in ipairs(source_lines or {}) do
    item = tostring(item):gsub("\r\n", "\n")
    for line in (item .. "\n"):gmatch("(.-)\n") do
      table.insert(lines, line)
    end
  end
end

function M.format(block, rendered_lines, options)
  options = options or {}
  local preview = options.preview or {}
  local width = preview.context_max_width or 80
  local lines = {}

  if block.heading then
    table.insert(lines, "# " .. trim_to_width(block.heading, width))
  end

  local type_label = block.type or "mermaid"
  table.insert(lines, string.format("Mermaid: %s at line %d", type_label, block.start_line or 1))

  if #(block.before_lines or {}) > 0 then
    table.insert(lines, "")
    append_context(lines, block.before_lines, width)
  end

  if #(rendered_lines or {}) > 0 then
    table.insert(lines, "")
    append_lines(lines, rendered_lines)
  end

  if #(block.after_lines or {}) > 0 then
    table.insert(lines, "")
    append_context(lines, block.after_lines, width)
  end

  return lines
end

return M
