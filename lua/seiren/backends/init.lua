local source = require("seiren.backends.source")

local M = {}

local backend_modules = {
  source = source,
}

function M.render(block, options)
  options = options or {}
  local mermaid = options.mermaid or {}
  local backend_name = mermaid.backend or "source"
  local backend = backend_modules[backend_name]

  if not backend then
    local result = source.render(block, options)
    result.ok = false
    result.backend = "source"
    result.error = string.format("unknown backend: %s", backend_name)
    return result
  end

  return backend.render(block, options)
end

return M

