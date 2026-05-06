local config = require("seiren.config")

local M = {}

local function runner_path(options)
  local configured = options.mermaid and options.mermaid.runner_path
  if configured then
    return configured
  end

  return vim.fs.joinpath(vim.fn.getcwd(), "scripts", "render-beautiful-mermaid.mjs")
end

local function add(checks, status, name, message)
  table.insert(checks, {
    status = status,
    name = name,
    message = message,
  })
end

function M.collect(options, deps)
  options = options or config.get()
  deps = deps or {}

  local checks = {}
  local executable = deps.executable or vim.fn.executable
  local filereadable = deps.filereadable or vim.fn.filereadable
  local system = deps.system or vim.system
  local mermaid = options.mermaid or {}
  local preview = options.preview or {}
  local node_command = mermaid.node_command or "node"
  local resolved_runner = runner_path(options)

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
  }, { text = true }):wait()

  if import_result.code == 0 then
    add(checks, "ok", "beautiful-mermaid package", "import succeeded")
  else
    local message = vim.trim(import_result.stderr or import_result.stdout or "import failed")
    if message == "" then
      message = "import failed"
    end
    add(checks, "error", "beautiful-mermaid package", message)
  end

  if preview.wrap == true then
    add(checks, "warn", "preview.wrap", "soft wrapping can break diagram layout")
  else
    add(checks, "ok", "preview.wrap", "disabled")
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

