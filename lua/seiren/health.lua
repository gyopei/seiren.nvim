local config = require("seiren.config")
local paths = require("seiren.paths")

local M = {}

local function runner_path(options, deps)
  local configured = options.mermaid and options.mermaid.runner_path
  if configured then
    return configured
  end

  return (deps.runner_path or paths.runner_path)()
end

local function add(checks, status, name, message)
  table.insert(checks, {
    status = status,
    name = name,
    message = message,
  })
end

local function sample_render(checks, sample, node_command, resolved_runner, plugin_root, deps)
  local tempname = deps.tempname or vim.fn.tempname
  local writefile = deps.writefile or vim.fn.writefile
  local delete = deps.delete or vim.fn.delete
  local system = deps.system or vim.system
  local temp_path = tempname()

  if not temp_path:match("%.mmd$") then
    temp_path = temp_path .. ".mmd"
  end

  writefile(vim.split(sample.source, "\n", { plain = true }), temp_path)

  local result = system({ node_command, resolved_runner, temp_path }, { text = true, cwd = plugin_root }):wait()
  delete(temp_path)

  if result.code == 0 and vim.trim(result.stdout or "") ~= "" then
    add(checks, "ok", sample.name, "rendered non-empty output")
    return
  end

  local message = vim.trim(result.stderr or result.stdout or "sample render failed")
  if message == "" then
    message = "sample render returned empty output"
  end
  add(checks, "error", sample.name, message)
end

function M.collect(options, deps)
  options = options or config.get()
  deps = deps or {}

  local checks = {}
  local executable = deps.executable or vim.fn.executable
  local filereadable = deps.filereadable or vim.fn.filereadable
  local system = deps.system or vim.system
  local mermaid = options.mermaid or {}
  local image = options.image or {}
  local preview = options.preview or {}
  local node_command = mermaid.node_command or "node"
  local resolved_runner = runner_path(options, deps)
  local plugin_root = (deps.plugin_root or paths.plugin_root)()

  if executable(node_command) == 1 then
    add(checks, "ok", "Node.js", node_command .. " is executable")
  else
    add(checks, "error", "Node.js", node_command .. " is not executable")
  end

  if filereadable(resolved_runner) == 1 then
    add(checks, "ok", "beautiful-mermaid runner", resolved_runner)
  else
    add(checks, "error", "beautiful-mermaid runner", resolved_runner .. " is missing")
  end

  local import_result = system({
    node_command,
    "-e",
    "import('beautiful-mermaid').then(() => console.log('ok')).catch((error) => { console.error(error.message); process.exit(1); })",
  }, { text = true, cwd = plugin_root }):wait()

  if import_result.code == 0 then
    add(checks, "ok", "beautiful-mermaid package", "import succeeded")
  else
    local message = vim.trim(import_result.stderr or import_result.stdout or "import failed")
    if message == "" then
      message = "import failed"
    end
    add(checks, "error", "beautiful-mermaid package", message)
  end

  sample_render(checks, {
    name = "sample render flowchart",
    source = "flowchart TD\n  A --> B",
  }, node_command, resolved_runner, plugin_root, deps)

  sample_render(checks, {
    name = "sample render sequenceDiagram",
    source = "sequenceDiagram\n  A->>B: hello",
  }, node_command, resolved_runner, plugin_root, deps)

  if preview.wrap == true then
    add(checks, "warn", "preview.wrap", "soft wrapping can break diagram layout")
  else
    add(checks, "ok", "preview.wrap", "disabled")
  end

  if image.enabled == true then
    local mmdc = image.mmdc_command or (deps.mmdc_path or paths.mmdc_path)()
    if executable(mmdc) == 1 then
      add(checks, "ok", "mermaid-cli", mmdc .. " is executable")
    else
      add(checks, "error", "mermaid-cli", mmdc .. " is not executable")
    end
  end

  return checks
end

function M.check()
  local health = vim.health

  health.start("seiren.nvim")

  for _, item in ipairs(M.collect()) do
    if item.status == "ok" then
      health.ok(item.name .. ": " .. item.message)
    elseif item.status == "warn" then
      health.warn(item.name .. ": " .. item.message)
    else
      health.error(item.name .. ": " .. item.message)
    end
  end
end

return M
