local M = {}

local function module_source(deps)
  deps = deps or {}
  if deps.source then
    return deps.source
  end

  return debug.getinfo(1, "S").source
end

function M.plugin_root(deps)
  local source = module_source(deps)

  if source:sub(1, 1) == "@" then
    source = source:sub(2)
  end

  local marker = "/lua/seiren/"
  local marker_start = source:find(marker, 1, true)

  if marker_start then
    return source:sub(1, marker_start - 1)
  end

  return vim.fn.fnamemodify(source, ":p:h:h:h")
end

function M.runner_path(deps)
  return vim.fs.joinpath(M.plugin_root(deps), "scripts", "render-beautiful-mermaid.mjs")
end

return M

