local source_backend = require("seiren.backends.source")
local paths = require("seiren.paths")

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

local function default_runner_path()
  return paths.runner_path()
end

local function source_lines_with_error(block, message)
  local fallback = source_backend.render(block)
  local lines = { "Renderer error: " .. message, "" }

  vim.list_extend(lines, fallback.lines)
  return lines
end

function M.render(block, options, deps)
  options = options or {}
  deps = deps or {}

  local mermaid = options.mermaid or {}
  local node_command = mermaid.node_command or "node"
  local runner_path = mermaid.runner_path or (deps.runner_path or default_runner_path)()
  local temp_path = (deps.tempname or vim.fn.tempname)()
  local writefile = deps.writefile or vim.fn.writefile
  local delete = deps.delete or vim.fn.delete
  local system = deps.system or vim.system

  if not temp_path:match("%.mmd$") then
    temp_path = temp_path .. ".mmd"
  end

  writefile(split_lines(block and block.source or ""), temp_path)

  local plugin_root = (deps.plugin_root or paths.plugin_root)()
  local result = system({ node_command, runner_path, temp_path }, { text = true, cwd = plugin_root }):wait()
  delete(temp_path)

  if result.code ~= 0 then
    local message = vim.trim(result.stderr or result.stdout or "render failed")
    if message == "" then
      message = "render failed"
    end

    return {
      ok = false,
      backend = "beautiful_mermaid",
      error = message,
      lines = source_lines_with_error(block, message),
    }
  end

  return {
    ok = true,
    backend = "beautiful_mermaid",
    lines = split_lines(result.stdout or ""),
  }
end

return M
