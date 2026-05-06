local M = {}

local function node_text(bufnr, node)
  return vim.treesitter.get_node_text(node, bufnr)
end

local function first_non_empty_line(source)
  for line in (source .. "\n"):gmatch("(.-)\n") do
    local trimmed = vim.trim(line)
    if trimmed ~= "" then
      return trimmed
    end
  end
  return ""
end

local function diagram_type(source)
  local first = first_non_empty_line(source)
  return first:match("^(%S+)") or "mermaid"
end

local function heading_before(lines, line_index)
  for index = line_index, 1, -1 do
    local heading = lines[index]:match("^%s*#+%s*(.-)%s*$")
    if heading and heading ~= "" then
      return heading
    end
  end
  return nil
end

local function context_before(lines, start_line, count)
  local result = {}
  local index = start_line - 1

  while index >= 1 and #result < count do
    local line = lines[index]
    if vim.trim(line) ~= "" and not line:match("^%s*#+%s+") then
      table.insert(result, 1, line)
    end
    index = index - 1
  end

  return result
end

local function context_after(lines, end_line, count)
  local result = {}
  local index = end_line + 1

  while index <= #lines and #result < count do
    local line = lines[index]
    if vim.trim(line) ~= "" and not line:match("^%s*#+%s+") then
      table.insert(result, line)
    end
    index = index + 1
  end

  return result
end

local function is_mermaid_fence(bufnr, node)
  for child in node:iter_children() do
    if child:type() == "info_string" then
      return vim.trim(node_text(bufnr, child)) == "mermaid"
    end
  end

  return false
end

local function walk(node, callback)
  callback(node)
  for child in node:iter_children() do
    walk(child, callback)
  end
end

function M.extract(bufnr, options)
  bufnr = bufnr or 0
  options = options or {}
  local preview = options.preview or {}
  local context_lines = preview.context_lines or 1
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "markdown")

  if not ok or not parser then
    return {}
  end

  local tree = parser:parse()[1]
  local blocks = {}

  walk(tree:root(), function(node)
    if node:type() ~= "fenced_code_block" or not is_mermaid_fence(bufnr, node) then
      return
    end

    local start_row, _, end_row = node:range()
    local start_line = start_row + 1
    local end_line = end_row
    local source_lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line - 1, false)
    local source = table.concat(source_lines, "\n")

    table.insert(blocks, {
      source = source,
      type = diagram_type(source),
      start_line = start_line,
      end_line = end_line,
      heading = heading_before(lines, start_line),
      before_lines = context_before(lines, start_line, context_lines),
      after_lines = context_after(lines, end_line, context_lines),
    })
  end)

  table.sort(blocks, function(left, right)
    return left.start_line < right.start_line
  end)

  return blocks
end

function M.select(bufnr, cursor_line, options)
  local blocks = M.extract(bufnr, options)
  local selected

  for _, block in ipairs(blocks) do
    if cursor_line >= block.start_line and cursor_line <= block.end_line then
      return block
    end

    if block.end_line < cursor_line then
      selected = block
    end
  end

  return selected
end

return M

