local M = {}

local function split_lines(source)
  local lines = {}

  source = source or ""
  for line in (source .. "\n"):gmatch("(.-)\n") do
    table.insert(lines, line)
  end

  return lines
end

function M.render(block)
  local lines = { "```mermaid" }

  for _, line in ipairs(split_lines(block and block.source or "")) do
    table.insert(lines, line)
  end

  table.insert(lines, "```")

  return {
    ok = true,
    backend = "source",
    lines = lines,
  }
end

return M

